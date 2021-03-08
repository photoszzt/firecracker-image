#!/bin/bash
set -euo pipefail
sudo rm -rf output mnt image.ext4
docker build -t alpine-microvm .
docker run --privileged -it --rm -v $(pwd)/output:/output alpine-microvm

echo "done setup"
