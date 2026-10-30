#!/bin/bash

rm -rf .repo/local_manifests/

# repo init rom
repo init -u https://github.com/ProtonPlus-ORG/manifest -b tm --depth=1
echo "=================="
echo "Repo init success"
echo "=================="

# Local manifests
git clone https://github.com/AsTechpro20/local_manifests_blossom.git -b lineage-20 .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Build Sync
repo sync -j$(nproc --all) --force-sync --no-tags --no-clone-bundle --prune --optimized-fetch
echo "============="
echo "Sync success"
echo "============="

rm -rf .repo

# Installing packages 

echo "============="
echo "packages done"
echo "============="

# Export
export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "============="

# Lunch
lunch blossom-userdebug

# Build
m otapackage
