#!/bin/bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "need image name"
    exit
fi

if [ ! -d "/var/local/${USER}/.faas/galvanic" ] 
then
    echo "Dir /var/local/${USER}/.faas/galvanic doesn't exist. Run 'make' on src/host_cache/guest_boto3wrap_py_module to create it"
    exit 1
fi

if [ ! -f "/var/local/$USER/.linux-img/server" ]
then
    echo "/var/local/$USER/.linux-img/server doesn't exist, run 'make' on src/server to create it"
    exit 1
fi

mkdir -p mnt
sudo mount /var/local/$USER/.linux-img/$1/image.ext4 mnt
sudo rm -f mnt/server
sudo cp /var/local/$USER/.linux-img/server mnt/server
sudo cp /var/local/$USER/.linux-img/forkserver.py mnt/forkserver.py
sudo cp run_linux_kernel_cmdline/kcmd_run.py mnt/kcmd_run.py

sudo rm -rf mnt/usr/local/lib/python3.6/dist-packages/boto3cached
sudo rm -rf mnt/usr/local/lib/python3.6/dist-packages/galvanic

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

sudo umount mnt
rmdir mnt
