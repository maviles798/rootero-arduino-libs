# Build environment for the Rootero framework libraries (Espressif's lib-builder, pinned).
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    bison ca-certificates ccache cmake curl flex git gperf jq libncurses-dev libssl-dev \
    libusb-1.0-0 ninja-build patch python3 python3-click python3-cryptography python3-future \
    python3-pip python3-pyelftools python3-pyparsing python3-serial python3-setuptools \
    python3-venv wget xz-utils && rm -rf /var/lib/apt/lists/*
ENV IDF_CCACHE_ENABLE=1
RUN git config --system --add safe.directory '*'
WORKDIR /work
