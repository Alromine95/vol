#!/bin/bash

echo "========================"
echo "removing local manifests"
echo "========================"

rm -rf .repo/local_manifests;

echo "====================="
echo "      Repo init      "
echo "====================="

repo init -u https://git.libremobileos.com/LMODroid/manifest.git -b fourteen-qpr1 --git-lfs --depth=1

git clone https://github.com/Alromine95/rom-sources.git -b main .repo/local_manifests;

echo "==================="
echo "     repo sync     "
echo "==================="

/opt/crave/resync.sh

repo sync -c --force-sync --force-remove-dirty --no-clone-bundle --no-tags


/opt/crave/resync.sh

sudo apt-get update && sudo apt-get install patchelf coreutils -y;

export BUILD_USERNAME=Abhinav
export BUILD_HOSTNAME=foss

rm -rf build/soong/fsgen;


#deleting extra generator
rm -rf vendor/lineage/build/soong/generator


echo "build started!..."

source build/envsetup.sh ;
lunch lmodroid_blossom-userdebug ;
m bacon ;
