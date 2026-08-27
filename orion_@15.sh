#!/bin/bash

rm -rf .repo/local_manifests/

# repo init rom
repo init -u https://github.com/OrionOS-Project/manifest -b vic --depth=1 --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

# Local manifests
git clone https://github.com/AsTechpro20/local_manifests_blossom.git -b lineage-22 .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Build Sync
repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune --retry-fetches=5 -j$(nproc --all)
echo "============="
echo "Sync success"
echo "============="

# Installing packages 
sudo apt install bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs gnupg gperf imagemagick lib32ncurses-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses6 libncurses-dev libsdl1.2-dev libssl-dev libwxgtk3.2-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev;
sudo apt-get update && sudo apt-get install patchelf coreutils -y
echo "============="
echo "packages done"
echo "============="

# Export
export BUILD_USERNAME=Qbhi
export BUILD_HOSTNAME=crave
export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "============="

# Lunch
lunch orion_blossom-bpa-userdebug

# Build
make orion -j$(nproc --all)
