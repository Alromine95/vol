#!/bin/bash

set -e

git config --global user.name "Abhinav"
git config --global user.email "abhinav@gmail.com"

repo init \
    -u https://github.com/ArrowOS/android_manifest.git \
    -b arrow-14.0 \
    --depth=1

rm -rf .repo/local_manifests

git clone \
    https://github.com/Alromine95/local_manifests_blossom.git \
    -b lineage-21 \
    .repo/local_manifests

cat > .repo/local_manifests/arrow_vendor.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
    <remote
        name="arrow"
        fetch="https://github.com/ArrowOS"
        revision="arrow-14.0" />

    <project
        name="android_vendor_arrow"
        path="vendor/arrow"
        remote="arrow"
        revision="arrow-14.0"
        clone-depth="1" />
</manifest>
EOF

repo sync -c --no-tags --no-clone-bundle --optimized-fetch -j4 --force-sync

echo "========================================"
echo "ArrowOS source sync complete"
echo "========================================"

# Clean any stale Soong output
rm -rf out/soong
rm -rf out/host/linux-x86/bin/soong*

source build/envsetup.sh

lunch arrow_blossom-userdebug

m bacon
