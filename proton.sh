#!/usr/bin/env bash
# ProtonPlus ROM builder for blossom (shell-script version of the GitHub Actions workflow)
# Target: Ubuntu 22.04 (or similar). Run as a normal user with sudo access:  bash build-rom.sh
set -uo pipefail

# ============================ CONFIG ============================
REPO_INIT_URL="https://github.com/ProtonPlus-ORG/manifest"
REPO_BRANCH="tm-qpr3"
LUNCH_TARGET="proton_blossom-eng"
BUILD_COMMAND="m otapackage"

GIT_NAME="abhinav"
GIT_EMAIL="abhinav@example.com"

WORKSPACE="/mnt/workspace"          # holds rom.img + swapfile
BUILD_DIR="$WORKSPACE/build"        # ROM source tree lives here
IMG_SIZE="200G"                     # sparse btrfs image size
USE_BTRFS=1                         # 1 = compressed btrfs image (saves disk), 0 = plain folder
SWAP_SIZE="6G"
JOBS="$(nproc --all)"               # change to a fixed number (e.g. 12) if RAM is tight
DELETE_DOT_REPO=0                   # 1 = delete .repo after sync to save ~35-45GB (can't re-sync after)

# Optional uploads (leave empty to skip PixelDrain)
PIXELDRAIN_API_KEY=""
# ================================================================

log() { echo -e "\n==== $* ====\n"; }

# ---------------------------- 1. Dependencies ----------------------------
log "Installing dependencies"
sudo apt-get update
sudo apt-get install -y \
  btrfs-progs git aria2 python3 python-is-python3 bc bison build-essential \
  curl flex g++-multilib gcc-multilib gnupg gperf imagemagick \
  lib32ncurses-dev lib32readline-dev lib32z1-dev liblz4-tool \
  libncurses-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils \
  lzop pngcrush rsync schedtool squashfs-tools xsltproc zip \
  zlib1g-dev unzip

# repo tool (plain script, NOT base64)
sudo curl -fsSL "https://storage.googleapis.com/git-repo-downloads/repo" -o /usr/local/bin/repo
sudo chmod a+rx /usr/local/bin/repo
head -n 1 /usr/local/bin/repo
repo --version

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# ---------------------------- 2. Workspace + swap ----------------------------
log "Setting up workspace"
sudo mkdir -p "$BUILD_DIR"
sudo chown -R "$USER:$USER" "$WORKSPACE"

if [ "$USE_BTRFS" = "1" ]; then
  if ! mountpoint -q "$BUILD_DIR"; then
    [ -f "$WORKSPACE/rom.img" ] || { truncate -s "$IMG_SIZE" "$WORKSPACE/rom.img"; mkfs.btrfs -f "$WORKSPACE/rom.img"; }
    sudo mount -o loop,compress=zstd:3,noatime,discard=async "$WORKSPACE/rom.img" "$BUILD_DIR"
  fi
  sudo chown -R "$USER:$USER" "$BUILD_DIR"
fi

# zswap + swapfile
if ! swapon --show | grep -q "$WORKSPACE/swapfile"; then
  echo 1 | sudo tee /sys/module/zswap/parameters/enabled >/dev/null || true
  echo zstd | sudo tee /sys/module/zswap/parameters/compressor >/dev/null || true
  [ -f "$WORKSPACE/swapfile" ] || {
    sudo fallocate -l "$SWAP_SIZE" "$WORKSPACE/swapfile"
    sudo chmod 600 "$WORKSPACE/swapfile"
    sudo mkswap "$WORKSPACE/swapfile"
  }
  sudo swapon "$WORKSPACE/swapfile" || true
fi
df -h / "$BUILD_DIR"
free -h

# ---------------------------- 3. Init, manifest, sync ----------------------------
log "repo init + local manifest + sync"
cd "$BUILD_DIR"
[ -d .repo ] || repo init -u "$REPO_INIT_URL" -b "$REPO_BRANCH"

mkdir -p .repo/local_manifests
cat << 'EOF' > .repo/local_manifests/roomservice.xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>

<remote name="t25" fetch="https://github.com/TelegramAt25" />
<remote name="25ji" fetch="https://github.com/25ji-Telegram-de" />
<remote name="astechpro20" fetch="https://github.com/AsTechpro20" />
<remote name="LOS" fetch="https://github.com/LineageOS" />

<!-- Device Trees -->
<project path="device/xiaomi/blossom" name="android_device_xiaomi_blossom" remote="astechpro20" revision="lineage-20" />

<!-- SELinux Policies -->
<project path="device/mediatek/sepolicy_vndr" name="android_device_mediatek_sepolicy_vndr" remote="LOS" revision="lineage-20" />

<!-- Hardware Supports -->
<project path="hardware/mediatek" name="android_hardware_mediatek" remote="t25" revision="lineage-20_blossom" />

<!-- Kernel Trees -->
<project path="device/xiaomi/blossom-kernel" name="device_xiaomi_blossom-kernel" remote="t25" revision="lineage-20">
 <linkfile src="headers" dest="kernel/xiaomi/blossom" />
</project>

<!-- Vendor Trees -->
<project path="vendor/xiaomi/blossom" name="proprietary_vendor_xiaomi_blossom" remote="t25" revision="lineage-20" />

<!-- RevampedFMRadio -->
<project path="packages/apps/RevampedFMRadio" name="android_packages_apps_RevampedFMRadio" remote="25ji" revision="tomfoolery" />

</manifest>
EOF

repo sync -c -j"$JOBS" --force-sync --no-tags --no-clone-bundle --prune --optimized-fetch || true
repo sync -l -j"$JOBS" --force-sync || true

# ---------------------------- 3b. Auto-patch device tree ----------------------------
log "Patching device tree (lineage_blossom -> proton_blossom)"
if [ -d "device/xiaomi/blossom" ]; then
  (
    cd device/xiaomi/blossom
    [ -f "lineage_blossom.mk" ] && mv lineage_blossom.mk proton_blossom.mk
    sed -i 's/lineage_blossom/proton_blossom/g' AndroidProducts.mk proton_blossom.mk
    find . -type f -exec sed -i \
      -e 's|vendor/lineage/config/common_full_phone.mk|vendor/proton/config/common.mk|g' \
      -e 's|vendor/lineage/config/common.mk|vendor/proton/config/common.mk|g' \
      -e 's|vendor/lineage|vendor/proton|g' {} +
  )
fi

# ---------------------------- 4. Optional: free space ----------------------------
if [ "$DELETE_DOT_REPO" = "1" ]; then
  log "Deleting .repo"
  rm -rf "$BUILD_DIR/.repo"
  [ "$USE_BTRFS" = "1" ] && sudo fstrim -v "$BUILD_DIR"
  df -h / "$BUILD_DIR"
fi

# ---------------------------- 5. Build ----------------------------
log "Building ROM"
cd "$BUILD_DIR"
export USE_CCACHE=0
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
# envsetup/lunch use unset vars, so relax -u for them
set +u
# shellcheck disable=SC1091
. build/envsetup.sh
lunch "$LUNCH_TARGET" || { echo "lunch failed"; exit 1; }
set -u
$BUILD_COMMAND -j"$JOBS" || { echo "Build failed"; exit 1; }

# ---------------------------- 6. Upload ----------------------------
log "Uploading ROM zip"
OUT="$BUILD_DIR/out/target/product/blossom"
ZIP_FILE=$(ls -t "$OUT"/*.zip 2>/dev/null | grep -vi "ota" | head -n 1 || true)
[ -z "$ZIP_FILE" ] && ZIP_FILE=$(ls -t "$OUT"/*.zip 2>/dev/null | head -n 1 || true)
[ -z "$ZIP_FILE" ] && { echo "No zip found in $OUT"; exit 1; }
echo "FOUND ROM ZIP: $ZIP_FILE"

if [ -n "$PIXELDRAIN_API_KEY" ]; then
  echo "Uploading to PixelDrain..."
  curl -T "$ZIP_FILE" -u ":$PIXELDRAIN_API_KEY" "https://pixeldrain.com/api/file/$(basename "$ZIP_FILE")"
  echo
else
  echo "PIXELDRAIN_API_KEY not set, skipping PixelDrain."
fi

echo "Uploading to GoFile..."
curl -F "file=@$ZIP_FILE" "https://upload.gofile.io/uploadfile"
echo
log "Done"
