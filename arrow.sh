#!/bin/bash

rm -rf .repo/local_manifests

# repo init rom
repo init -u https://github.com/ArrowOS/android_manifest.git -b arrow-14.0 --depth=1 
echo "=================="
echo "Repo init success"
echo "=================="

# Local manifests
git clone https://github.com/Alromine95/local_manifests_blossom.git -b patch .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Build Sync
repo sync -j12;

repo sync -j5 --fail-fast;

echo "============="
echo "Sync success"
echo "============="

# Installing packages 
sudo apt-get update && sudo apt-get install patchelf coreutils -y;
echo "============="
echo "packages done"
echo "============="

# Export
export BUILD_USERNAME=Qbhi
export BUILD_HOSTNAME=crave
export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true
export BUILD_BROKEN_PREBUILT_ELF_FILES=true
export BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES=true
export BUILD_BROKEN_VENDOR_PROPERTY_NAMESPACE=true
export BUILD_BROKEN_DUP_RULES=true
export ALLOW_MISSING_DEPENDENCIES=true
export BUILD_BROKEN_USES_BUILD_COPY_HEADERS=true
export WITH_ADB_INSECURE=true
echo "======= Export Done ======"

rm -rf build/soong/fsgen;

sed -i 's/android\.PathForSourceRelaxed/android.PathForSource/g' vendor/arrow/build/soong/generator/generator.go && sed -n '226p' vendor/arrow/build/soong/generator/generator.go || true;

sed -i 's/"export_cflags"/"cflags"/; s/^\( *\)export_cflags:/\1cflags:/' vendor/arrow/build/soong/Android.bp && grep -n "export_cflags\|cflags" vendor/arrow/build/soong/Android.bp | head -5 || true;

find vendor/qcom/opensource/dataservices hardware/qcom-caf/bootctrl -name Android.bp -exec mv {} {}.bak \; || true

grep -rn "SOONG_NAMESPACES" device/xiaomi/blossom vendor/xiaomi/blossom | head; grep -q "PRODUCT_SOONG_NAMESPACES.*vendor/xiaomi/blossom" device/xiaomi/blossom/device.mk || echo 'PRODUCT_SOONG_NAMESPACES += vendor/xiaomi/blossom' >> device/xiaomi/blossom/device.mk; tail -3 device/xiaomi/blossom/device.mk || true;

sed -n '508,520p' device/xiaomi/blossom/device.mk; echo ---; sed -n '1,14p' vendor/xiaomi/blossom/blossom-vendor.mk; echo ---; head -12 vendor/xiaomi/blossom/Android.bp || true;

sed -i '0,/^\tr\.sortedNamespaces\.add(namespace)$/s//\tif namespace.exportToKati {\n\t\tr.rootNamespace.visibleNamespaces = append(r.rootNamespace.visibleNamespaces, namespace)\n\t}\n\tr.sortedNamespaces.add(namespace)/' build/soong/android/namespace.go && sed -n '158,166p' build/soong/android/namespace.go || true;

grep -q BoardConfigSoong device/xiaomi/blossom/BoardConfig.mk || echo 'include vendor/arrow/config/BoardConfigSoong.mk' >> device/xiaomi/blossom/BoardConfig.mk; tail -2 device/xiaomi/blossom/BoardConfig.mk || true;

find hardware/qcom-caf -name Android.bp -exec sed -i '/^[[:space:]]*clang:[[:space:]]*true,\{0,1\}[[:space:]]*$/d' {} + && grep -rn "clang:" hardware/qcom-caf --include=Android.bp | head -3 || true; 

grep -rl --include=Android.bp -E '^[[:space:]]*clang:' hardware vendor | xargs -r sed -i -E '/^[[:space:]]*clang:[[:space:]]*true,?[[:space:]]*$/d'; grep -rn --include=Android.bp -E '^[[:space:]]*clang:' hardware vendor | head -5 || true; 

mv hardware/qcom/wlan/Android.mk hardware/qcom/wlan/Android.mk.bak || true;

find hardware/qcom/wlan -name Android.mk -exec mv {} {}.bak \; || true;

sed -i 's/\$(MD5SUM)/md5sum/' vendor/arrow/build/tasks/bacon.mk && sed -n '12p' vendor/arrow/build/tasks/bacon.mk || true; 

grep -rl --include=*.mk 'MD5SUM' vendor/arrow | xargs -r sed -i 's/\$(MD5SUM)/md5sum/g'; grep -rn --include=*.mk 'MD5SUM' vendor/arrow | head -3 || true; 

sed -i '0,/^#include/s//#include <android-base\/unique_fd.h>\n#include/' device/xiaomi/blossom/libshims/libshim_ui/GraphicBufferMapper.cpp && head -12 device/xiaomi/blossom/libshims/libshim_ui/GraphicBufferMapper.cpp || true; 

printf '// Android 14: libui already exports these symbols; empty shim keeps blobs that need libshim_ui loading.\n' > device/xiaomi/blossom/libshims/libshim_ui/GraphicBufferMapper.cpp && cat device/xiaomi/blossom/libshims/libshim_ui/GraphicBufferMapper.cpp || true;

# Back up the policy file first
cp device/xiaomi/blossom/sepolicy/vendor/platform_app.te \
   device/xiaomi/blossom/sepolicy/vendor/platform_app.te.bak

# Remove the rule that references the undefined type
sed -i '/pm_archiving_enabled_prop/d' \
   device/xiaomi/blossom/sepolicy/vendor/platform_app.te

# Verify the offending reference is gone
grep -n 'pm_archiving_enabled_prop' \
   device/xiaomi/blossom/sepolicy/vendor/platform_app.te

cp device/mediatek/sepolicy_vndr/basic/non_plat/genfs_contexts \
   device/mediatek/sepolicy_vndr/basic/non_plat/genfs_contexts.bak

sed -i '\|genfscon sysfs /devices/platform/1000d000.pwrap/1000d000.pwrap:main_pmic/mt6397-rtc/wakeup |d' \
  device/mediatek/sepolicy_vndr/basic/non_plat/genfs_contexts

#fix the settings bug
OVERLAY="vendor/arrow/overlay/common/packages/apps/Settings/res"

# Find every overlay file using the missing resource
grep -RIl --include='config.xml' \
    '@string/backup_transport_setting_label' "$OVERLAY" |
while IFS= read -r file; do
    # Preserve the original file
    cp -n "$file" "$file.bak"

    # Replace the missing resource reference with a literal label
    sed -i 's|@string/backup_transport_setting_label|Change backup provider|g' "$file"

    echo "Fixed: $file"
done

#removing bak files
python3 - <<'PY'
from pathlib import Path
import shutil

root = Path("vendor/arrow/overlay/common/packages/apps/Settings/res")
backup_root = Path("/tmp/arrow-settings-overlay-backups")

files = list(root.rglob("*.bak"))

for src in files:
    dest = backup_root / src.relative_to(root)
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(src), str(dest))

print(f"Moved {len(files)} backup files outside the resource directory.")
print(f"Backups preserved in: {backup_root}")
PY

mkdir -p device/xiaomi/blossom-kernel/modules


. build/envsetup.sh

lunch arrow_blossom-userdebug

m bacon
