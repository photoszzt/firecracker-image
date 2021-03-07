FROM alpine:3.13.2

ENV KERNEL_SOURCE_VERSION 5.4.102
RUN apk add diffutils bash alpine-sdk openrc util-linux elfutils-dev openssl openssl-dev bison make flex perl xz \
    linux-headers && wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$KERNEL_SOURCE_VERSION.tar.xz && \
    tar xvf linux-$KERNEL_SOURCE_VERSION.tar.*

ADD config/kernel-config-5 /linux-$KERNEL_SOURCE_VERSION/.config

WORKDIR /linux-$KERNEL_SOURCE_VERSION
RUN make -j $(nproc)
WORKDIR /

VOLUME [ "/output", "/rootfs", "/script", "/config" ]

ADD script /script
ADD config /config

CMD [ "/bin/bash", "/script/image.sh" ]
