#!/bin/bash

set -o nounset                              # Treat unset variables as an error
set -eou pipefail

INET_DEV=eno1
VM_IP=192.168.20.2
TAP_IP=192.168.20.1

../setup_network/setup_fc_networking.sh natted l_tap0 $TAP_IP $INET_DEV
sudo firecracker --no-api --config-file ./linux_config.json
