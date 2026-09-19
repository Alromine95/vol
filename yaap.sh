#!/bin/bash

rm -rf .repo/local_manifests/

# repo init rom
repo init -u https://github.com/yaap/manifest.git -b sixteen --depth=1 --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

# Local manifests
git clone https://github.com/Alromine95/Local-manifest.git -b main .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Build Sync
repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune --retry-fetches=5 -j$(nproc --all)
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
export IGNORE_PATCH_ERRORS=true
echo "======= Export Done ======"

#Go fix
SOONG_FILE="build/soong/ui/execution_metrics/execution_metrics.go"; git checkout -- "$SOONG_FILE" 2>/dev/null; [ -f "$SOONG_FILE" ] && (echo "🔧 Re-patching execution_metrics.go safely..."; grep -q '"sort"' "$SOONG_FILE" || sed -i '/^import (/a\    "sort"' "$SOONG_FILE"; sed -i '/"maps"/d; /"slices"/d' "$SOONG_FILE"; sed -i 's/slices\.Sorted(maps\.Keys(\([^)]*\)))/func() []string { keys := make([]string, 0, len(\1)); for k := range \1 { keys = append(keys, k) }; sort.Strings(keys); return keys }()/' "$SOONG_FILE"; echo "✅ Fixed and patched successfully!") || echo "❌ Soong execution_metrics.go not found!"

# Set up build environment
source build/envsetup.sh
echo "============="

# Lunch
lunch yaap_blossom-bp2a-userdebug

# Build
m yaap
