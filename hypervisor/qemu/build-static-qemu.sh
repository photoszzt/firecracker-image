#!/bin/bash
#
# Copyright (c) 2018 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

set -o errexit
set -o nounset
set -o pipefail
set -x

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${script_dir}/../qemu.blacklist"

qemu_tar="static-qemu.tar.gz"
qemu_tmp_tar="static-qemu-tmp.tar.gz"

qemu_repo="https://gitlab.com/qemu-project/qemu.git"
qemu_url="https://gitlab.com/qemu-project/qemu"
qemu_version="v5.1.0"

http_proxy="${http_proxy:-}"
https_proxy="${https_proxy:-}"
prefix="${prefix:-"/opt/qemu"}"

sudo docker build \
	--no-cache \
	--build-arg http_proxy="${http_proxy}" \
	--build-arg https_proxy="${https_proxy}" \
	--build-arg QEMU_REPO="${qemu_repo}" \
	--build-arg QEMU_VERSION="${qemu_version}" \
	--build-arg QEMU_TARBALL="${qemu_tar}" \
	--build-arg PREFIX="${prefix}" \
	"${script_dir}/../" \
	-f "${script_dir}/Dockerfile" \
	-t qemu-static

sudo docker run \
	-i \
	-v "${PWD}":/share qemu-static \
	mv "/tmp/qemu-static/${qemu_tar}" /share/

sudo chown ${USER} "${PWD}/${qemu_tar}"

# Remove blacklisted binaries
gzip -d < "${qemu_tar}" | tar --delete --wildcards -f - ${qemu_black_list[*]} | gzip > \
    "${qemu_tmp_tar}" || true
mv -f "${qemu_tmp_tar}" "${qemu_tar}"
