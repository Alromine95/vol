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


/opt/crave/resync.sh;

repo sync -c --force-sync --force-remove-dirty;

/opt/crave/resync.sh;

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

cd ~/pos

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

#fixing build errors

cd ~/pos

CLANG_REPO="prebuilts/clang/host/linux-x86"
LIB="clang-r530567/lib/libclang.so"

# Restore the library from the existing Git checkout if tracked
if git -C "$CLANG_REPO" cat-file -e "HEAD:$LIB" 2>/dev/null; then
    git -C "$CLANG_REPO" restore --source=HEAD -- "$LIB"
fi

# If the file is still missing, sync only the Clang prebuilt project
if [ ! -s "$CLANG_REPO/$LIB" ]; then
    repo sync -c "$CLANG_REPO"
fi

# Verify the library is actually present
if [ -s "$CLANG_REPO/$LIB" ]; then
    ls -lh "$CLANG_REPO/$LIB"
    file "$CLANG_REPO/$LIB"
else
    echo "ERROR: libclang.so is still missing"
fi

#deleting extra generator
rm -rf vendor/lineage/build/soong/generator

rm -rf out/soong/.intermediates/external/perfetto/perfetto_trace_protos/
   
rm -rf out/soong/.intermediates/art/tools/signal_dumper/

# Set up build environment
. build/envsetup.sh
echo "============="

# Lunch
lunch aosp_blossom-bp1a-userdebug

# Build
m bacon
