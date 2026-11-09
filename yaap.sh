#!/bin/bash


rm -rf .repo/local_manifests


# repo init rom
repo init -u https://github.com/yaap/manifest.git -b seventeen --git-lfs --depth=1
echo "=================="
echo "Repo init success"
echo "=================="

# Local manifests
git clone https://github.com/Alromine95/dt.git -b 17.0 .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"





# Build Sync


repo sync -j12;

repo sync -j5 --fail-fast

echo "============="
echo "Sync success"
echo "============="



# Installing packages 
sudo apt-get update && sudo apt-get install patchelf coreutils -y 
echo "============="
echo "packages done"
echo "============="

# Export
export BUILD_USERNAME=Qbhi
export BUILD_HOSTNAME=crave
export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true
export IGNORE_PATCH_ERRORS=true
echo "======= Export Done ======"

#Fixing patchs
git -C frameworks/av am --abort 2>/dev/null || true
git -C frameworks/base am --abort 2>/dev/null || true
git -C hardware/interfaces am --abort 2>/dev/null || true
git -C packages/modules/Bluetooth am --abort 2>/dev/null || true
git -C build/soong am --abort 2>/dev/null || true
git -C system/sepolicy am --abort 2>/dev/null || true

#deleting extra generator
rm -rf vendor/lineage/build/soong/generator


# Set up build environment
source build/envsetup.sh
lunch yaap_blossom-user && m yaap
