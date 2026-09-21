#!/bin/bash

set -eE
trap 'echo " FAILED at line $LINENO"; exit 1' ERR

rm -rf .repo/local_manifests
rm -rf .repo

# repo init rom
repo init -u https://github.com/yaap/manifest.git -b sixteen --depth=1 --git-lfs --groups=default,-mips,-x86,-darwin
echo "=================="
echo "Repo init success"
echo "=================="

# Local manifests
git clone https://github.com/Alromine95/Local-manifest.git -b main .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Build Sync


/opt/crave/resync.sh;

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
#Fixing patchs
git -C frameworks/av am --abort 2>/dev/null || true
git -C frameworks/base am --abort 2>/dev/null || true
git -C hardware/interfaces am --abort 2>/dev/null || true
git -C packages/modules/Bluetooth am --abort 2>/dev/null || true
git -C build/soong am --abort 2>/dev/null || true
git -C system/sepolicy am --abort 2>/dev/null || true

#Go fix
SOONG_FILE="build/soong/ui/execution_metrics/execution_metrics.go"

if [ -f "$SOONG_FILE" ]; then
    echo "🔧 Re-patching execution_metrics.go safely..."

    git checkout -- "$SOONG_FILE" 2>/dev/null || true

    grep -q '"sort"' "$SOONG_FILE" || \
        sed -i '/^import (/a\    "sort"' "$SOONG_FILE"

    sed -i '/"maps"/d; /"slices"/d' "$SOONG_FILE"

    sed -i 's/slices\.Sorted(maps\.Keys(\([^)]*\)))/func() []string { keys := make([]string, 0, len(\1)); for k := range \1 { keys = append(keys, k) }; sort.Strings(keys); return keys }()/' "$SOONG_FILE"

    echo "✅ Fixed and patched successfully!"
else
    echo "⚠️ $SOONG_FILE not found, skipping Go patch."
fi

#Making kernel modules dir
mkdir -p device/xiaomi/blossom-kernel/modules

#Fixing audio files
AUDIO_BP="hardware/interfaces/audio/common/all-versions/default/Android.bp"
if [ -f "$AUDIO_BP" ]; then
    echo "🔧 Fixing Audio select type condition..."
    sed -i 's/"true":/true:/g' "$AUDIO_BP"
    echo "✅ Audio Android.bp patched!"
else
    echo "⚠️ Audio Android.bp not found, skipping patch."
fi

# Set up build environment
source build/envsetup.sh#!/bin/bash

set -eE
trap 'echo "❌ FAILED at line $LINENO"' ERR

rm -rf .repo/local_manifests
rm -rf .repo

# repo init rom

repo init -u https://github.com/AyakaUI/android_manifest.git -b sixteen --depth=1 --git-lfs

echo "=================="
echo "Repo init success"
echo "=================="

# Local manifests

git clone https://github.com/kitsunee02/local_manifests.git -b A16 .repo/local_manifests

echo "============================"
echo "Local manifest clone success"
echo "============================"

# Build Sync
# curl -sf https://raw.githubusercontent.com/xc112lg/lg_releases/refs/heads/main/resync.sh | bash

echo "============="
echo "Sync"
echo "============="

/opt/crave/resync.sh

/opt/crave/resync.sh

# Installing packages 

sudo apt-get update && sudo apt-get install patchelf coreutils -y 

echo "============="
echo "packages done"
echo "============="

# Export

export BUILD_USERNAME=Fiyuu
export TARGET_BUILD_GAPPS=false
export BUILD_HOSTNAME=crave
export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true
export IGNORE_PATCH_ERRORS=true

echo "======= Export Done ======"

#Go fix

SOONG_FILE="build/soong/ui/execution_metrics/execution_metrics.go"; git checkout -- "$SOONG_FILE" 2>/dev/null; [ -f "$SOONG_FILE" ] && (echo "🔧 Re-patching execution_metrics.go safely..."; grep -q '"sort"' "$SOONG_FILE" || sed -i '/^import (/a\    "sort"' "$SOONG_FILE"; sed -i '/"maps"/d; /"slices"/d' "$SOONG_FILE"; sed -i 's/slices\.Sorted(maps\.Keys(\([^)]*\)))/func() []string { keys := make([]string, 0, len(\1)); for k := range \1 { keys = append(keys, k) }; sort.Strings(keys); return keys }()/' "$SOONG_FILE"; echo "✅ Fixed and patched successfully!") || echo "❌ Soong execution_metrics.go not found!"

#Making kernel modules dir

mkdir -p device/xiaomi/blossom-kernel/modules

#Fixing audio files

AUDIO_BP="hardware/interfaces/audio/common/all-versions/default/Android.bp"; [ -f "$AUDIO_BP" ] && (echo "🔧 Fixing Audio select type condition..."; sed -i 's/"true":/true:/g' "$AUDIO_BP"; echo "✅ Audio Android.bp patched!") || echo "⚠️ Audio Android.bp not found, skipping patch."

# Set up build environment

source build/envsetup.sh

echo "============="

# Lunch

lunch lineage_blossom-bp2a-userdebug

# Build

m bacon
echo "============="

# Lunch
lunch yaap_blossom-bp2a-userdebug

# Build
m yaap
