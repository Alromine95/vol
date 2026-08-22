#!/bin/bash
rm -rf .repo/local_manifests;


repo init -u https://github.com/OrionOS-Project/manifest -b bka --git-lfs;
 
git clone https://github.com/Alromine95/local_manifests_blossom.git -b lineage-23.0 .repo/local_manifests;

/opt/crave/resync.sh;

sudo apt-get update && sudo apt-get install patchelf coreutils -y;

export BUILD_USERNAME=Abhinav
export BUILD_HOSTNAME=foss

rm -rf build/soong/fsgen;

. build/envsetup.sh;
lunch lineage_blossom-bp2a-userdebug;
mka orion -j$(nproc --all);

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







