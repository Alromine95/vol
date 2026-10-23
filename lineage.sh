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

# ---- Go / low-RAM tuning for blossom ----
DT=device/xiaomi/blossom
MK=$DT/device.mk

if [ -f "$MK" ] && ! grep -q "ro.config.low_ram" "$MK"; then
    # use go_defaults if the source has it, else rely on manual props only
    GO_MK=$(ls build/make/target/product/ | grep -m1 '^go_defaults.mk$')
    if [ -n "$GO_MK" ] && ! grep -q go_defaults "$MK"; then
        sed -i '0,/^\$(call inherit-product/s||$(call inherit-product, $(SRC_TARGET_DIR)/product/go_defaults.mk)\n&|' "$MK"
    fi

    # remove old heap values so they don't conflict
    sed -i '/dalvik.vm.heapgrowthlimit/d;/dalvik.vm.heapsize/d' "$MK"

    cat >> "$MK" <<'EOF'

# Go / low-RAM tuning
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.low_ram=true \
    ro.lmk.use_psi=true \
    ro.lmk.debug=false \
    ro.statsd.enable=false \
    dalvik.vm.heapgrowthlimit=128m \
    dalvik.vm.heapsize=256m \
    dalvik.vm.dex2oat-threads=2 \
    pm.dexopt.bg-dexopt=speed-profile \
    pm.dexopt.install=speed-profile

WITH_DEXPREOPT_BOOT_IMG_AND_SYSTEM_SERVER_ONLY := true
MALLOC_SVELTE := true
PRODUCT_MINIMIZE_JAVA_DEBUG_INFO := true
EOF
    echo "[go-tuning] applied to $MK"
else
    echo "[go-tuning] skipped (device.mk missing or already tuned)"
fi
# ---- end Go tuning ----

export BUILD_USERNAME=Abhinav
export BUILD_HOSTNAME=foss

rm -rf build/soong/fsgen;

echo "build started!..."

. build/envsetup.sh;
lunch lineage_blossom-cp2a-userdebug;
m bacon -j$(nproc --all);
