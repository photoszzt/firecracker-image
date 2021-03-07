#!/bin/bash
set -euo pipefail
sudo rm -rf output mnt image.ext4
docker build -t ubuntu-firecracker .
docker run --privileged -it --rm -v $(pwd)/output:/output ubuntu-firecracker

echo "done setup"
