
#!/usr/bin/env bash
# ProtonPlus ROM builder for Xiaomi Redmi 9 Activ (blossom)
# Ubuntu 22.04+
# Run: bash build-rom.sh

set -Eeuo pipefail

trap 'rc=$?; echo "[ERROR] Line $LINENO: $BASH_COMMAND (exit $rc)" >&2; exit "$rc"' ERR

# ============================ CONFIG ============================

REPO_INIT_URL="https://github.com/ProtonPlus-ORG/manifest"
REPO_BRANCH="tm-qpr3"

LUNCH_TARGET="proton_blossom-eng"

GIT_NAME="abhinav"
GIT_EMAIL="abhinav@example.com"

WORKSPACE="/mnt/workspace"
BUILD_DIR="$WORKSPACE/build"

IMG_SIZE="200G"
USE_BTRFS=1

SWAP_SIZE="6G"

# Keep repo sync conservative.
SYNC_JOBS="${SYNC_JOBS:-4}"
NETWORK_JOBS="${NETWORK_JOBS:-4}"
CHECKOUT_JOBS="${CHECKOUT_JOBS:-2}"

# Build jobs can be overridden when running the script.
BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"

DELETE_DOT_REPO=0

PIXELDRAIN_API_KEY="${PIXELDRAIN_API_KEY:-}"

# ================================================================

log() {
    printf '\n========== %s ==========\n\n' "$*"
}

fail() {
    echo "[FATAL] $*" >&2
    exit 1
}

# ---------------------------- 1. Dependencies ----------------------------

log "Installing dependencies"

sudo apt-get update

sudo apt-get install -y \
    btrfs-progs git aria2 python3 python-is-python3 bc bison \
    build-essential curl flex g++-multilib gcc-multilib gnupg \
    gperf imagemagick lib32ncurses-dev lib32readline-dev \
    lib32z1-dev liblz4-tool libncurses-dev libsdl1.2-dev \
    libssl-dev libxml2 libxml2-utils lzop pngcrush rsync \
    schedtool squashfs-tools xsltproc zip zlib1g-dev unzip

log "Installing Android repo tool"

sudo install -d /usr/local/bin

curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo \
    | sudo tee /usr/local/bin/repo >/dev/null

sudo chmod 0755 /usr/local/bin/repo

repo --version

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# ---------------------------- 2. Workspace + swap ----------------------------

log "Setting up workspace"

sudo mkdir -p "$WORKSPACE" "$BUILD_DIR"
sudo chown "$USER:$USER" "$WORKSPACE"

if [[ "$USE_BTRFS" == "1" ]]; then

    if ! mountpoint -q "$BUILD_DIR"; then

        if [[ ! -f "$WORKSPACE/rom.img" ]]; then
            log "Creating BTRFS image"

            truncate -s "$IMG_SIZE" "$WORKSPACE/rom.img"

            mkfs.btrfs -f "$WORKSPACE/rom.img"
        fi

        log "Mounting BTRFS image"

        sudo mount \
            -o loop,compress=zstd:3,noatime \
            "$WORKSPACE/rom.img" "$BUILD_DIR"
    fi

    sudo chown "$USER:$USER" "$BUILD_DIR"
fi

log "Configuring swap"

if ! swapon --show=NAME --noheadings | grep -Fxq "$WORKSPACE/swapfile"; then

    echo 1 | sudo tee /sys/module/zswap/parameters/enabled >/dev/null || true
    echo zstd | sudo tee /sys/module/zswap/parameters/compressor >/dev/null || true

    if [[ ! -f "$WORKSPACE/swapfile" ]]; then
        sudo fallocate -l "$SWAP_SIZE" "$WORKSPACE/swapfile"
        sudo chmod 600 "$WORKSPACE/swapfile"
        sudo mkswap "$WORKSPACE/swapfile"
    fi

    sudo swapon "$WORKSPACE/swapfile"
fi

df -h "$WORKSPACE" "$BUILD_DIR"
free -h

# ---------------------------- 3. Repo initialization ----------------------------

log "Initializing ProtonPlus manifest"

cd "$BUILD_DIR"

repo init \
    -u "$REPO_INIT_URL" \
    -b "$REPO_BRANCH" \
    --no-clone-bundle

# ---------------------------- 4. Local manifest ----------------------------

log "Creating blossom local manifest"

mkdir -p .repo/local_manifests

cat > .repo/local_manifests/roomservice.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>

    <remote name="t25"
            fetch="https://github.com/TelegramAt25" />

    <remote name="25ji"
            fetch="https://github.com/25ji-Telegram-de" />

    <remote name="astechpro20"
            fetch="https://github.com/AsTechpro20" />

    <remote name="LOS"
            fetch="https://github.com/LineageOS" />

    <remote name="protonplus"
            fetch="https://github.com/ProtonPlus-ORG" />

    <!-- Device tree -->
    <project path="device/xiaomi/blossom"
             name="android_device_xiaomi_blossom"
             remote="astechpro20"
             revision="lineage-20" />

    <!-- MediaTek SELinux -->
    <project path="device/mediatek/sepolicy_vndr"
             name="android_device_mediatek_sepolicy_vndr"
             remote="LOS"
             revision="lineage-20" />

    <!-- MediaTek hardware -->
    <project path="hardware/mediatek"
             name="android_hardware_mediatek"
             remote="t25"
             revision="lineage-20_blossom" />

    <!-- Kernel -->
    <project path="device/xiaomi/blossom-kernel"
             name="device_xiaomi_blossom-kernel"
             remote="t25"
             revision="lineage-20">
        <linkfile src="headers"
                  dest="kernel/xiaomi/blossom" />
    </project>

    <!-- Device vendor blobs -->
    <project path="vendor/xiaomi/blossom"
             name="proprietary_vendor_xiaomi_blossom"
             remote="t25"
             revision="lineage-20" />

    <!-- ProtonPlus vendor -->
    <project path="vendor/proton"
             name="vendor_proton"
             remote="protonplus"
             revision="tm-qpr3" />

    <!-- FM Radio -->
    <project path="packages/apps/RevampedFMRadio"
             name="android_packages_apps_RevampedFMRadio"
             remote="25ji"
             revision="tomfoolery" />

</manifest>
EOF

# Validate XML before attempting sync.
xmllint --noout .repo/local_manifests/roomservice.xml

# ---------------------------- 5. Repository synchronization ----------------------------

log "Starting repository synchronization"

echo "Sync jobs:       $SYNC_JOBS"
echo "Network jobs:    $NETWORK_JOBS"
echo "Checkout jobs:   $CHECKOUT_JOBS"

echo "Sync log: $WORKSPACE/repo-sync.log"

# Do not ignore errors. Preserve partial downloads for the next attempt.
repo sync \
    -c \
    -j"$SYNC_JOBS" \
    --jobs-network="$NETWORK_JOBS" \
    --jobs-checkout="$CHECKOUT_JOBS" \
    --no-tags \
    --no-clone-bundle \
    --prune \
    --fail-fast \
    --verbose \
    2>&1 | tee "$WORKSPACE/repo-sync.log"

log "Repository synchronization completed"

# Verify required repositories exist.
[[ -d device/xiaomi/blossom ]] || fail "Blossom device tree missing"
[[ -d vendor/xiaomi/blossom ]] || fail "Blossom vendor tree missing"
[[ -f vendor/proton/config/common.mk ]] || fail "ProtonPlus vendor configuration missing"

# ---------------------------- 6. Device tree patch ----------------------------

log "Patching blossom device tree"

(
    cd device/xiaomi/blossom

    if [[ -f lineage_blossom.mk && ! -f proton_blossom.mk ]]; then
        mv lineage_blossom.mk proton_blossom.mk
    fi

    [[ -f proton_blossom.mk ]] || {
        echo "Expected lineage_blossom.mk or proton_blossom.mk was not found."
        exit 1
    }

    [[ -f AndroidProducts.mk ]] || {
        echo "AndroidProducts.mk missing!"
        exit 1
    }

    # Only patch text source/configuration files.
    # Never run sed against every file, including binary assets.
    find . -type f \
        \( \
            -name '*.mk' -o \
            -name '*.bp' -o \
            -name '*.xml' -o \
            -name '*.sh' -o \
            -name '*.prop' -o \
            -name '*.rc' -o \
            -name '*.te' -o \
            -name 'BoardConfig*' \
        \) \
        -not -path './.git/*' \
        -exec sed -i \
            -e 's/lineage_blossom/proton_blossom/g' \
            -e 's#vendor/lineage/config/common_full_phone.mk#vendor/proton/config/common.mk#g' \
            -e 's#vendor/lineage/config/common.mk#vendor/proton/config/common.mk#g' \
            -e 's#vendor/lineage#vendor/proton#g' \
            {} +
)

log "Device tree patch completed"

# ---------------------------- 7. Optional space cleanup ----------------------------

if [[ "$DELETE_DOT_REPO" == "1" ]]; then

    log "Deleting repository metadata"

    rm -rf "$BUILD_DIR/.repo"

    if [[ "$USE_BTRFS" == "1" ]]; then
        sudo fstrim -v "$BUILD_DIR" || true
    fi

    df -h "$WORKSPACE" "$BUILD_DIR"
fi

# ---------------------------- 8. Build ROM ----------------------------

log "Starting ProtonPlus build"

cd "$BUILD_DIR"

export USE_CCACHE=0
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# envsetup/lunch may reference unset variables.
set +u

source build/envsetup.sh

lunch "$LUNCH_TARGET" || fail "Lunch target failed: $LUNCH_TARGET"

set -u

echo "Build jobs: $BUILD_JOBS"

m -j"$BUILD_JOBS" otapackage

log "Build completed successfully"

# ---------------------------- 9. Locate ROM ZIP ----------------------------

log "Locating ROM ZIP"

OUT="$BUILD_DIR/out/target/product/blossom"

[[ -d "$OUT" ]] || fail "Output directory does not exist: $OUT"

ZIP_FILE="$(
    find "$OUT" -maxdepth 1 -type f \
        -name '*.zip' ! -iname '*ota*' \
        -printf '%T@ %p\n' |
        sort -nr |
        head -n 1 |
        cut -d' ' -f2- || true
)"

if [[ -z "$ZIP_FILE" ]]; then
    ZIP_FILE="$(
        find "$OUT" -maxdepth 1 -type f \
            -name '*.zip' \
            -printf '%T@ %p\n' |
            sort -nr |
            head -n 1 |
            cut -d' ' -f2- || true
    )"
fi

[[ -n "$ZIP_FILE" ]] || fail "No ROM ZIP found"

echo "FOUND ROM ZIP: $ZIP_FILE"

sha256sum "$ZIP_FILE"

# ---------------------------- 10. Upload ----------------------------

log "Uploading ROM"

if [[ -n "$PIXELDRAIN_API_KEY" ]]; then

    echo "Uploading to PixelDrain..."

    if curl -fSL --retry 3 \
        -T "$ZIP_FILE" \
        -u ":$PIXELDRAIN_API_KEY" \
        "https://pixeldrain.com/api/file/$(basename "$ZIP_FILE")"; then
        echo "PixelDrain upload completed."
    else
        echo "PixelDrain upload failed."
    fi

else
    echo "PixelDrain API key not configured. Skipping."
fi

echo "Uploading to GoFile..."

if curl -fSL --retry 3 \
    -F "file=@$ZIP_FILE" \
    "https://upload.gofile.io/uploadfile"; then
    echo "GoFile upload completed."
else
    echo "GoFile upload failed."
fi

log "ProtonPlus blossom build finished"
