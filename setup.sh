#!/bin/bash

set -euxo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

apt update
DEBIAN_FRONTEND=noninteractive apt install -y awscli golang-go pv docker docker-compose clang-12 make jq emacs

# Download, setup and install zstd v1.5.2.
# We use an upgraded version rather than what ubuntu uses because
# 1.5.0+ greatly improved performance (3-5x faster for compression/decompression).
mkdir /zstd/
cd /zstd
wget -q -O- https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz | tar xzf -
cd /zstd/zstd-1.5.2
CC=clang-12 CXX=clang++-12 CFLAGS="-O3" make zstd
ln -s /zstd/zstd-1.5.2/zstd /zstd/zstd
