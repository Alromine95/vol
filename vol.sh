#!/bin/bash

set -eE
trap 'echo " FAILED at ${BASH_SOURCE[0]}:${LINENO} -> $BASH_COMMAND"; exit 1' ERR

#Removing old manifests
rm -rf .repo/local_manifests
echo "=====old local manifest deleted====="

#repo init rom source
repo init -u https://github.com/VoltageOS/manifest.git -b 16.2 --git-lfs --depth=1 

#clone local manifests
git clone https://github.com/Alromine95/Local-manifest.git -b main .repo/local_manifests
echo "====My local manifests cloned===="


# Build Sync
/opt/crave/resync.sh || true;

/opt/crave/resync.sh || true;

echo "============="
echo "Sync success"
echo "============="

# Installing packages 
sudo apt-get update && sudo apt-get install patchelf coreutils -y 
echo "====Packages Installed===="

# Export
export BUILD_USERNAME=Qbhi
export BUILD_HOSTNAME=crave
export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true
export IGNORE_PATCH_ERRORS=true
echo "==== Export Done ===="

#Fixing patchs
git -C frameworks/av am --abort 2>/dev/null || true
git -C frameworks/base am --abort 2>/dev/null || true
git -C hardware/interfaces am --abort 2>/dev/null || true
git -C packages/modules/Bluetooth am --abort 2>/dev/null || true
git -C build/soong am --abort 2>/dev/null || true
git -C system/sepolicy am --abort 2>/dev/null || true

rm -rf out/soong/.intermediates/external/perfetto/perfetto_trace_protos/
rm -rf out/soong/.intermediates/art/tools/signal_dumper/

#Starting build environment
. build/envsetup.sh

#Lunching Build environment
lunch arrow_blossom-userdebug

#Compiling ROM
m bacon
