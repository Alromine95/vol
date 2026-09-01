#!/bin/bash

echo "========================"
echo "removing local manifests"
echo "========================"

rm -rf .repo/local_manifests;
rm -rf out/soong/.intermediates/system/sepolicy;

echo "====================="
echo "      Repo init      "
echo "====================="

repo init -u https://github.com/OrionOS-Project/manifest -b bka --depth=1 --git-lfs;
git clone https://github.com/Alromine95/Local-manifest.git -b main .repo/local_manifests;

echo "==================="
echo "     repo sync     "
echo "==================="

/opt/crave/resync.sh;

sudo apt-get update && sudo apt-get install patchelf coreutils -y;


export BUILD_USERNAME=Abhinav
export BUILD_HOSTNAME=foss

rm -rf build/soong/fsgen;

XML=vendor/lineage/prebuilt/common/etc/permissions/product-privapp-permissions-aosp.xml
if ! grep -q "com.google.android.deskclock" "$XML"; then
  sed -i 's|</permissions>|<privapp-permissions package="com.google.android.deskclock">\n<permission name="android.permission.CONTROL_DISPLAY_COLOR_TRANSFORMS"/>\n<permission name="android.permission.START_FOREGROUND_SERVICES_FROM_BACKGROUND"/>\n</privapp-permissions>\n</permissions>|' "$XML"
  echo "Patched privapp-permissions XML"
else
  echo "privapp-permissions XML already patched, skipping"
fi

echo "build started!..."

. build/envsetup.sh;
lunch lineage_blossom-bp2a-eng;
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







