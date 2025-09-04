# syntax=docker/dockerfile:1
#
ARG IMAGEBASE=frommakefile
#
FROM ${IMAGEBASE}
#
ARG VERSION=master
ARG PLATFORMVERSION=master
ARG NPROC=4
ARG PYCECVERSION=0.5.2
#
RUN set -xe \
    && apk add --no-cache --purge -uU \
        libstdc++ \
        libgcc \
        eudev-libs \
        # libcec \
        libx11 \
        libxrandr \
        # p8-platform \
        python3 \
        # py3-libcec \
        raspberrypi-libs \
        v4l-utils \
#
    && apk add --update --virtual .build-dependencies \
        build-base \
        cmake \
        eudev-dev \
        git \
        libx11-dev \
        libxrandr-dev \
        linux-headers \
        make \
        ncurses-dev \
        pkgconf \
        py3-pip \
        python3-dev \
        raspberrypi-dev \
        swig \
#
    && mkdir /opt/cec-build \
#
    && cd /opt/cec-build \
    && git clone https://github.com/Pulse-Eight/platform.git -b ${PLATFORMVERSION} ./platform \
    && mkdir platform/build \
    && cd platform/build \
    && cmake \
        -DCMAKE_INSTALL_PREFIX:PATH=/usr \
        .. \
    && make -j${NPROC} \
    && make install \
#
    && cd /opt/cec-build \
    && git clone https://github.com/Pulse-Eight/libcec.git -b libcec-${VERSION} ./libcec \
    && mkdir libcec/build \
    && cd libcec/build \
    && cmake \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_INSTALL_PREFIX:PATH=/usr \
        -DHAVE_AOCEC_API=1 \
        -DHAVE_EXYNOS_API=1 \
        -DHAVE_IMX_API=1 \
        -DHAVE_LINUX_API=1 \
#       -DHAVE_TEGRA_API=1 \
        -DRPI_INCLUDE_DIR=/opt/vc/include \
        -DRPI_LIB_DIR=/opt/vc/lib \
        .. \
    && make -j${NPROC} \
    && make install \
#     && ldconfig \
#
    && pip install --no-cache-dir --break-system-packages -v \
        https://github.com/konikvranik/pyCEC/archive/refs/tags/v${PYCECVERSION}.tar.gz \
    && apk del --purge .build-dependencies \
    # && apk del --purge py3-pip \
    && rm -rf /opt/cec-build /var/cache/apk/* /root/.cache /tmp/*
#
ENV LD_LIBRARY_PATH=/opt/vc/lib:${LD_LIBRARY_PATH}
#
COPY root/ /
#
EXPOSE 9526
#
HEALTHCHECK \
    --interval=2m \
    --retries=5 \
    --start-period=5m \
    --timeout=10s \
    CMD \
    nc -z -i 1 -w 1 localhost ${PYCEC_PORT:-9526} || exit 1
#
ENTRYPOINT ["/init"]
