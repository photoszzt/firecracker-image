FROM ubuntu:focal

ENV DEBIAN_FRONTEND noninteractive
ENV KERNEL_SOURCE_VERSION 5.4.102

WORKDIR /root

RUN apt-get update && apt-get install -y debootstrap build-essential kernel-package \
  fakeroot bc kmod cpio flex cpio libncurses5-dev libelf-dev libssl-dev bison rsync && \
  wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$KERNEL_SOURCE_VERSION.tar.xz && \
  tar xvf linux-$KERNEL_SOURCE_VERSION.tar.*

ADD config/kernel-config-5 /root/linux-$KERNEL_SOURCE_VERSION/.config

WORKDIR /root/linux-$KERNEL_SOURCE_VERSION
RUN make -j $(nproc) deb-pkg
WORKDIR /root

VOLUME [ "/output", "/rootfs", "/script", "/config" ]

ADD script /script
ADD config /config

CMD [ "/bin/bash", "/script/image.sh" ]
