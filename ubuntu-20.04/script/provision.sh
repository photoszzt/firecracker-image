#! /bin/bash
set -ex

dpkg -i /mnt/root/linux*.deb

echo 'ubuntu-focal' > /etc/hostname
passwd -d root
mkdir /etc/systemd/system/serial-getty@ttyS0.service.d/
cat <<EOF > /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -- \\u' --keep-baud 115200,38400,9600 --noclear --autologin root ttyS0 $TERM
EOF

cat <<EOF > /etc/pam.d/login
auth sufficient pam_listfile.so item=tty sense=allow file=/etc/securetty onerr=fail apply=root
EOF
echo ttyS0 >> /etc/securetty

cat <<EOF > /etc/netplan/99_config.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: false
EOF
netplan generate

echo "deb http://archive.ubuntu.com/ubuntu focal main restricted universe multiverse" > /etc/apt/sources.list
printf "nameserver 128.83.120.181\nnameserver 128.83.120.30\nnameserver 8.8.8.8\nnameserver 172.31.0.2\nnameserver 10.1.0.2" > /etc/resolv.conf

echo LANG="en_US.UTF-8" | tee -a mnt/etc/default/locale
echo "Etc/UTC" > /etc/timezone
locale-gen en_US.UTF-8
dpkg-reconfigure -f non-interactive tzdata

apt-get update
apt-get -y install wget python3-pip libpython3-dev language-pack-en-base
apt-get -y clean

pip3 install boto3==1.17.19 redis==3.5.3

echo "finish provision"
