#!/bin/bash

rm -rf .repo/local_manifests/

git config --global user.name "Abhinav"
git config --global user.email "abhinav@gmail.com"

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
