#!/bin/bash
rm -rf .repo/local_manifests;

 repo init -u https://github.com/VoltageOS/manifest.git --depth=1 -b 16.2 --git-lfs;
 
git clone https://github.com/Alromine95/android_local_manifests_blossom.git -b main .repo/local_manifests
/opt/crave/resync.sh;

export BUILD_USERNAME=Abhinav
export BUILD_HOSTNAME=foss

. build/envsetup.sh
# run

make installclean
brunch blossom

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







