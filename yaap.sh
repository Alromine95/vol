#!/bin/bash

echo "========================"
echo "removing local manifests"
echo "========================"

rm -rf .repo/local_manifests;
rm -rf .repo

echo "====================="
echo "      Repo init      "
echo "====================="

repo init -u https://github.com/yaap/manifest.git -b sixteen --depth=1 --git-lfs;

git clone https://github.com/Alromine95/Local-manifest.git -b main .repo/local_manifests;

echo "==================="
echo "     repo sync     "
echo "==================="

/opt/crave/resync.sh;

sudo apt-get update && sudo apt-get install patchelf coreutils -y;

export BUILD_USERNAME=Abhinav
export BUILD_HOSTNAME=foss

rm -rf build/soong/fsgen;

# Clone Soong
rm -rf build/soong
git clone https://github.com/yaap-17-stone/build_soong.git -b sixteen build/soong

# 2. Patch Go 1.23+ incompatibilities in execution_metrics.go
sed -i 's/"golang.org\/x\/exp\/maps"/& \n\t"sort"/' build/soong/ui/execution_metrics/execution_metrics.go
sed -i 's/slices\.Sorted(maps\.Keys(\([^)]*\)))/func() []string { keys := make([]string, 0, len(\1)); for k := range \1 { keys = append(keys, k) }; sort.Strings(keys); return keys }()/' build/soong/ui/execution_metrics/execution_metrics.go


echo "build started!..."

source build/envsetup.sh ;
lunch yaap_blossom-bp4a-userdebug ;
m installclean ;
m yaap ;

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
