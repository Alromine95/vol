#!/bin/bash

echo "========================"
echo "removing local manifests"
echo "========================"

rm -rf .repo/local_manifests;
rm -rf out/soong/.intermediates/system/sepolicy;

echo "====================="
echo "      Repo init      "
echo "====================="

repo init -u https://github.com/RisingOS-Revived/android -b seventeen --git-lfs --depth=1

git clone https://github.com/Alromine95/dt.git -b 17.0 .repo/local_manifests;

echo "==================="
echo "     repo sync     "
echo "==================="

/opt/crave/resync.sh;

/opt/crave/resync.sh;

/opt/crave/resync.sh;

sudo apt-get update && sudo apt-get install patchelf coreutils -y;

# Export
export BUILD_USERNAME=Qbhi
export BUILD_HOSTNAME=crave
export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true
export BUILD_BROKEN_PREBUILT_ELF_FILES=true
export BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES=true
export BUILD_BROKEN_VENDOR_PROPERTY_NAMESPACE=true
export BUILD_BROKEN_DUP_RULES=true
export ALLOW_MISSING_DEPENDENCIES=true
export BUILD_BROKEN_USES_BUILD_COPY_HEADERS=true
export WITH_ADB_INSECURE=true
echo "======= Export Done ======"

rm -rf build/soong/fsgen;

echo "build started!..."

. build/envsetup.sh

riseup blossom userdebug

rise b
