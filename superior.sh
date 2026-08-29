#!/bin/bash

rm -rf .repo/local_manifests/

# repo init rom
repo init -u https://github.com/SuperiorOS/manifest.git -b sixteen-los --depth=1 --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

# Local manifests
git clone https://gitlab.com/haikito18/local_manifest_blossom.git -b A16 .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Build Sync
/opt/crave/resync.sh
echo "============="
echo "Sync success"
echo "============="

# Installing packages 
sudo apt install bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs gnupg gperf imagemagick lib32readline-dev lib32z1-dev liblz4-tool libncurses6 libncurses-dev libsdl1.2-dev libssl-dev libwxgtk3.2-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev -y ;
sudo apt-get update && sudo apt-get install patchelf coreutils -y
echo "============="
echo "packages done"
echo "============="

# Export
export BUILD_USERNAME=Qbhi
export BUILD_HOSTNAME=crave
export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true
echo "======= Export Done ======"

rm -rf build/soong/fsgen;

# Set up build environment
./build-superior.sh blossom -j4
echo "============="
