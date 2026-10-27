#!/bin/bash

echo "========================"
echo "removing local manifests"
echo "========================"

rm -rf .repo/local_manifests;
rm -rf out/soong/.intermediates/system/sepolicy;

echo "====================="
echo "      Repo init      "
echo "====================="

repo init -u https://github.com/LineageOS/android.git -b lineage-24.0 --git-lfs --depth=1;

git clone https://github.com/Alromine95/dt.git -b 17.0 .repo/local_manifests;

echo "==================="
echo "     repo sync     "
echo "==================="

/opt/crave/resync.sh;

/opt/crave/resync.sh;

/opt/crave/resync.sh;

sudo apt-get update && sudo apt-get install patchelf coreutils -y;


export BUILD_USERNAME=Abhinav
export BUILD_HOSTNAME=foss


rm -rf build/soong/fsgen;

echo "build started!..."

. build/envsetup.sh;
lunch lineage_blossom-userdebug;
m bacon -j$(nproc --all);
