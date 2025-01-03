MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/sh

echo "Installing docker"
yum -y install docker
echo "Making swap at nvme2n1"
mkfs -t xfs /dev/nvme2n1
mkdir /swap
mount /dev/nvme2n1 /swap
fallocate -l 400G /swap/swapfile
chmod 600 /swap/swapfile
mkswap /swap/swapfile
swapon /swap/swapfile
swapon -s

echo "Making local at nvme1n1"
mkfs -t xfs /dev/nvme1n1
mkdir /local
mount /dev/nvme1n1 /local
mkdir /local/docker
chown -R ec2-user:users /local


read -r -d '' DOCKER_SETTINGS << EOM
{
    "data-root": "/local/docker"
}
EOM

echo -e "$DOCKER_SETTINGS" > /etc/docker/daemon.json

systemctl enable docker.service
systemctl enable containerd.service

service docker restart

sudo usermod -a -G docker ec2-user

--==MYBOUNDARY==--\
