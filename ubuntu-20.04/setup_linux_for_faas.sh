#!/bin/bash
set -euo pipefail

if [ ! -d "/var/local/${USER}/.faas/galvanic" ] 
then
    echo "Dir /var/local/${USER}/.faas/galvanic doesn't exist. Run 'make' on src/host_cache/guest_boto3wrap_py_module to create it"
    exit 1
fi

if [ ! -d "/var/local/${USER}/.faas/pocket_api" ]
then
    echo "Dir /var/local/${USER}/.faas/pocket_api doesn't exist. Run 'package.sh' on src/pocket/pocket/client to create it"
    exit 1
fi

if [ ! -f "/var/local/$USER/.linux-img/server" ]
then
    echo "/var/local/$USER/.linux-img/server doesn't exist, run 'make' on src/server to create it"
    exit 1
fi

make -C ../host_cache/guest_boto3wrap_py_module

sudo chown -R ${USER} output
cd output
mkdir -p mnt
sudo mount image.ext4 mnt
sudo rm -f mnt/server
sudo cp /var/local/$USER/.linux-img/server mnt/server
sudo cp /var/local/$USER/.linux-img/forkserver.py mnt/forkserver.py

sudo rm -rf mnt/function
sudo mkdir mnt/function

echo /usr/lib/python3.6/site-packages | sudo tee mnt/usr/lib/python3/dist-packages/site.pth
sudo cp -r /var/local/${USER}/.faas/galvanic mnt/usr/local/lib/python3.6/dist-packages/
sudo cp /var/local/${USER}/.faas/pocket_api/*.py \
    mnt/usr/local/lib/python3.6/dist-packages/galvanic/
sudo cp /var/local/${USER}/.faas/pocket_api/libpocket.so \
    mnt/usr/local/lib/python3.6/dist-packages/galvanic/
sudo cp /var/local/${USER}/.faas/pocket_api/libcppcrail.so \
    /var/local/${USER}/.faas/pocket_api/libboost_python3-py36.so.1.65.1 \
    mnt/usr/local/lib/
cd mnt/usr/local/lib/
sudo ln -sf libboost_python3-py36.so.1.65.1 libboost_python3-py36.so
sudo ln -sf libboost_python3-py36.so libboost_python3.so
cd -

sudo cp ../boot.sh mnt
sudo chmod +x mnt/boot.sh

sudo cp ../run_linux_kernel_cmdline/kcmd_run.py mnt
sudo cp ../fetch_memstats_vmstat.py mnt/

sudo tee mnt/etc/systemd/system/kcmd.service > /dev/null <<-EOF
[Unit]
Description=Run app from kernel cmdline
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 -u /kcmd_run.py > /kcmd_output.txt 2>&1
StandardOutput=file:/kcmd.log
[Install]
WantedBy=multi-user.target
EOF

sudo rm -f mnt/etc/systemd/system/multi-user.target.wants/kcmd.service
sudo ln -s mnt/etc/systemd/system/kcmd.service mnt/etc/systemd/system/multi-user.target.wants/kcmd.service

printf "\nPermitRootLogin yes" | sudo tee -a mnt/etc/ssh/sshd_config
printf "\nPermitEmptyPasswords yes\n" | sudo tee -a mnt/etc/ssh/sshd_config
sudo mkdir -p mnt/root/.ssh && sudo chmod 700 mnt/root/.ssh && sudo touch mnt/root/.ssh/authorized_keys && sudo chmod 600 mnt/root/.ssh/authorized_keys
printf "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDavXrDsk5omQli684k6r1ReuB2cY8dXC5TFu088HaSabnp198o950/BBN4GKSh0JdbGu+47xfQEWDqzL5UPGm2ZL8Mx+LcXohgVM8CTIQY/Qca2fcShmykCeVlrgzeibf/OfzCWUxra/cGLh7sKSErgJZ/SJvsmyYAASaj30YYXz5LduIbiNlwXCqhQvhM2DZI/IkeidQ81s3SkDZ2U3VwaRg1O1VklpehJu3szZA0l6W3pwq9+wSIiSb3vQH1rOfRWCg0ZCdeWbxHV2YJYtbj4rBl2UwqGBk3ncAewgy8N+QPe0BgzSGvu8HpW3g9KjeNpkzi+T6P78+1seG2aGph hfingler@languedoc" | sudo tee mnt/root/.ssh/authorized_keys
if ! [ -f ~/.ssh/lvm ]; then
    cat /dev/zero | ssh-keygen -q -N "" -b 2048 -t rsa -f ~/.ssh/lvm
fi
cat ~/.ssh/lvm.pub | sudo tee -a mnt/root/.ssh/authorized_keys

sudo umount mnt
rmdir mnt

cd ..
sudo mkdir -p /var/local/$USER
sudo chown $USER /var/local/$USER
sudo chmod a+rw /var/local
mkdir -p /var/local/$USER/.linux-img/base
cp output/image.ext4 /var/local/$USER/.linux-img/base
cp output/vmlinux /var/local/$USER/.linux-img/base
e2fsck -p /var/local/$USER/.linux-img/base/image.ext4
echo "done setup"

#gen initramfs
./initramfs/build.sh
