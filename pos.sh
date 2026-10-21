#!/bin/bash

set -eE
trap 'echo " FAILED at ${BASH_SOURCE[0]}:${LINENO} -> $BASH_COMMAND"; exit 1' ERR

rm -rf .repo/local_manifests


# repo init rom
repo init -u https://github.com/PixelOS-AOSP/manifest.git -b fifteen --git-lfs --depth=1 
echo "=================="
echo "Repo init success"
echo "=================="

# Local manifests
git clone https://github.com/Alromine95/local_manifests_blossom.git -b lineage-22.2 .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Build Sync
/opt/crave/resync.sh || true;

/opt/crave/resync.sh || true;

/opt/crave/resync.sh || true;


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

FILE="hardware/qcom-caf/common/os_pickup_aosp.mk"

cp -a "$FILE" "$FILE.bak"

python3 - <<'PY'
from pathlib import Path

p = Path("hardware/qcom-caf/common/os_pickup_aosp.mk")
s = p.read_text()

guard = "ifneq ($(TARGET_PRODUCT),aosp_blossom)"
if guard in s:
    print("Guard already exists; no changes made.")
else:
    old = """ifneq ($(BOARD_USES_QCOM_HARDWARE),true)
include $(call first-makefiles-under,$(LOCAL_PATH))
endif"""
    new = """ifneq ($(TARGET_PRODUCT),aosp_blossom)
ifneq ($(BOARD_USES_QCOM_HARDWARE),true)
include $(call first-makefiles-under,$(LOCAL_PATH))
endif
endif"""

    if old not in s:
        print("ERROR: Expected block not found. File left unchanged.")
    else:
        p.write_text(s.replace(old, new, 1))
        print("Applied aosp_blossom guard.")
PY

sed -n '1,20p' "$FILE"


#deleting extra generator
rm -rf vendor/lineage/build/soong/generator

rm -rf build/soong/fsgen

find hardware/qcom -xtype l -name Android.bp -delete

# Set up build environment
. build/envsetup.sh
echo "============="

# Lunch
lunch aosp_blossom-bp1a-userdebug

# Build
m bacon

# Upload rom zip
wget -q -O upload.sh https://raw.githubusercontent.com/Alromine95/vol/refs/heads/main/upload.sh
chmod +x upload.sh
./upload.sh blossom
