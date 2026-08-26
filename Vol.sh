#!/bin/bash



rm -rf .repo/local_manifests/
rm -rf device/lge vendor/lineage-priv/keys
rm -rf vendor/lge/msm8996-common kernel/lge/msm8996
rm -rf hardware/qcom-caf/msm8996
rm -rf hardware/qcom-caf/common 


repo init -u https://github.com/DerpFest-AOSP/android_manifest.git -b 16 --depth=1 --git-lfs;
 
/opt/crave/resync.sh;

sudo apt-get update && sudo apt-get install patchelf coreutils -y;

export BUILD_USERNAME=Abhinav
export BUILD_HOSTNAME=foss

rm -rf build/soong/fsgen;

echo "build started!..."

. build/envsetup.sh;
lunch lineage_blossom-bp2a-user;
mka derp;

echo "Upload to GoFile will be started..."

ZIP=$(find out/target/product/blossom -maxdepth 1 -type f -name "*.zip" | head -n 1)

if [ -n "$ZIP" ]; then
    echo "Uploading $ZIP..."
    wget https://raw.githubusercontent.com/lordgaruda/GoFile-Upload/refs/heads/master/upload.sh
    chmod +x upload.sh
    ./upload.sh "$ZIP"
else
    echo "No ROM ZIP found!"
    exit 1
fi







