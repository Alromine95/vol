#!/bin/bash


git config --global user.name "Abhinav"
git config --global user.email "abhinav@gmail.com"

repo init -u https://github.com/PotatoProject/manifest -b gnocchi-release --depth=1 

git clone https://github.com/Alromine95/local_manifests_blossom.git -b lineage-20 .repo/local_manifests

repo sync -c --no-tags --no-clone-bundle --optimized-fetch -j5 --force-sync

rm -rf build/soong/fsgen;

source build/envsetup.sh;
lunch potato_blossom-userdebug;
brunch blossom;

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
