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

#clone priv keys repo
ROOT_DIR="/tmp/src/android"
KEYS_DIR="$ROOT_DIR/vendor/voltage-priv/keys"

cd "$ROOT_DIR"

if [ ! -f "$KEYS_DIR/keys.sh" ]; then
    rm -rf "$KEYS_DIR"
    git clone https://github.com/VoltageOS/vendor_voltage-priv_keys.git -b 16.2 "$KEYS_DIR"
fi

if [ ! -f "$KEYS_DIR/platform.pk8" ]; then
    cd "$KEYS_DIR" && chmod +x keys.sh && ./keys.sh
fi

cd "$ROOT_DIR"

#Fixing patchs
git -C frameworks/av am --abort 2>/dev/null || true
git -C frameworks/base am --abort 2>/dev/null || true
git -C hardware/interfaces am --abort 2>/dev/null || true
git -C packages/modules/Bluetooth am --abort 2>/dev/null || true
git -C build/soong am --abort 2>/dev/null || true
git -C system/sepolicy am --abort 2>/dev/null || true

#deleting extra generator
rm -rf vendor/lineage/build/soong/generator

#Go fix
SOONG_FILE="build/soong/ui/execution_metrics/execution_metrics.go"

if [ -f "$SOONG_FILE" ]; then
    echo " Re-patching execution_metrics.go safely..."

    git checkout -- "$SOONG_FILE" 2>/dev/null || true

    grep -q '"sort"' "$SOONG_FILE" || \
        sed -i '/^import (/a\    "sort"' "$SOONG_FILE"

    sed -i '/"maps"/d; /"slices"/d' "$SOONG_FILE"

    sed -i 's/slices\.Sorted(maps\.Keys(\([^)]*\)))/func() []string { keys := make([]string, 0, len(\1)); for k := range \1 { keys = append(keys, k) }; sort.Strings(keys); return keys }()/' "$SOONG_FILE"

    echo " Fixed and patched successfully!"
else
    echo " $SOONG_FILE not found, skipping Go patch."
fi

echo "=======soong fix done========"


#Fixing audio files
AUDIO_BP="hardware/interfaces/audio/common/all-versions/default/Android.bp"
if [ -f "$AUDIO_BP" ]; then
    echo " Fixing Audio select type condition..."
    sed -i 's/"true":/true:/g' "$AUDIO_BP"
    echo " Audio Android.bp patched!"
else
    echo " Audio Android.bp not found, skipping patch."
fi

echo "=======audio fix done========="

rm -rf out/soong/.intermediates/external/perfetto/perfetto_trace_protos/
rm -rf out/soong/.intermediates/art/tools/signal_dumper/


#Starting build environment
. build/envsetup.sh

# Compilation started
 brunch blossom

# Upload rom zip
wget -q -O upload.sh https://raw.githubusercontent.com/Alromine95/vol/refs/heads/main/upload.sh
chmod +x upload.sh
./upload.sh blossom
