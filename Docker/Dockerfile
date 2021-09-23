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

RUN apt-get install -y libopenblas-dev

WORKDIR /opt/HPCTools/