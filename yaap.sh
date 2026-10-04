#!/bin/bash

set -eE
trap 'echo " FAILED at line $LINENO"; exit 1' ERR

rm -rf .repo/local_manifests


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


for toolchain in \
    "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9" \
    "prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9"; do
    if [ -d "$toolchain" ]; then
        rm -rf "$toolchain"
    fi
done



# Build Sync


/opt/crave/resync.sh;

repo sync -c --force-sync --force-remove-dirty;

echo "============="
echo "Sync success"
echo "============="

# Fix broken Crave Clang wrapper
CLANG_LINK="prebuilts/clang/host/linux-x86/clang-r563880c"
CLANG_REAL="prebuilts/clang/host/linux-x86/clang-r574158"

echo "========== Clang Fix =========="

if [ ! -d "$CLANG_REAL" ]; then
    echo "ERROR: $CLANG_REAL does not exist"
    exit 1
fi

if [ -L "$CLANG_LINK" ]; then
    rm -f "$CLANG_LINK"
elif [ -d "$CLANG_LINK" ]; then
    rm -rf "${CLANG_LINK}.bak"
    mv "$CLANG_LINK" "${CLANG_LINK}.bak"
fi

ln -s "$(basename "$CLANG_REAL")" "$CLANG_LINK"

echo "Clang resolved to:"
readlink -f "$CLANG_LINK"

echo "Clang version:"
"$CLANG_LINK/bin/clang++" --version

echo "========== Clang Fix Done =========="

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






# Set up build environment
source build/envsetup.sh
echo "============="

# Lunch
lunch yaap_blossom-bp4a-userdebug


# ================= Clang guard (runs AFTER lunch) =================
CLANG_DIR=prebuilts/clang/host/linux-x86
CLANG_NAME=clang-r574158

echo "=== Checking clang binaries ==="
# Restore any empty (0-byte) binary in clang's bin dir from git
for f in "$CLANG_DIR/$CLANG_NAME"/bin/*; do
    if [ -f "$f" ] && [ ! -L "$f" ] && [ ! -s "$f" ]; then
        rel="${f#$CLANG_DIR/}"
        echo "Empty file found: $rel -> restoring from git"
        rm -f "$f"
        git -C "$CLANG_DIR" checkout -- "$rel" || true
    fi
done

# Prove clang can compile before starting the long build
echo 'int main(){return 0;}' > /tmp/t.cpp
set +e
"$CLANG_DIR/clang-r563880c/bin/clang++" -v /tmp/t.cpp -o /tmp/t.out 2>&1
RC=$?
set -e
echo "clang exit code: $RC"

if [ "$RC" -ne 0 ]; then
    echo "=== CLANG STILL BROKEN ==="
    readlink -f "$CLANG_DIR/clang-r563880c"
    ls -la "$CLANG_DIR/$CLANG_NAME/bin" | head -30
    file "$CLANG_DIR/$CLANG_NAME/bin/clang-21" "$CLANG_DIR/$CLANG_NAME/bin/clang++"
    git -C "$CLANG_DIR" status --short | head -20
    exit 1
fi
echo "=== CLANG OK, starting build ==="
# ==================================================================

# Build
m yaap 
