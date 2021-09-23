FROM intel/oneapi-hpckit

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-utils \
        gnupg \
        ca-certificates \
        shellcheck \
        clang-format \
        make \
        cmake \
        git \
        g++ \
        gdb \
        liblapacke-dev \
        wget \
        ccache \
        nano \
        vim

WORKDIR /opt/HPCTools/