#!/bin/bash

rm -rf .repo/local_manifests/

git config --global user.name "Abhinav"
git config --global user.email "abhinav@gmail.com"

sudo apt-get update
          sudo apt-get install -y \
            btrfs-progs git aria2 python3 python-is-python3 bc bison build-essential \
            curl flex g++-multilib gcc-multilib gnupg gperf imagemagick \
            lib32ncurses-dev lib32readline-dev lib32z1-dev liblz4-tool \
            libncurses-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils \
            lzop pngcrush rsync schedtool squashfs-tools xsltproc zip \
            zlib1g-dev unzip

          sudo curl -fsSL "https://storage.googleapis.com/git-repo-downloads/repo" | base64 -d | sudo tee /usr/local/bin/repo > /dev/null
          sudo chmod a+rx /usr/local/bin/repo
          head -n 1 /usr/local/bin/repo
          repo --version

          # Configure Git Identity safely
          git config --global user.name "abhinav"
          git config --global user.email "abhinav@example.com"
          repo --version


          # Create 200GB sparse Btrfs mount with ZSTD compression & async discard
          sudo mkdir -p /mnt/workspace/build
          sudo chown -R "$USER:$USER" /mnt/workspace
          truncate -s 200G /mnt/workspace/rom.img
          mkfs.btrfs -f /mnt/workspace/rom.img
          sudo mount -o loop,compress=zstd:3,noatime,discard=async /mnt/workspace/rom.img /mnt/workspace/build
          sudo chown -R "$USER:$USER" /mnt/workspace/build

          # Enable built-in kernel zswap + compact 6GB swapfile (Azure kernel safe)
          sudo swapoff -a || true
          sudo rm -f /swapfile /mnt/swapfile
          echo 1 | sudo tee /sys/module/zswap/parameters/enabled || true
          echo zstd | sudo tee /sys/module/zswap/parameters/compressor || true
          sudo fallocate -l 6G /mnt/workspace/swapfile
          sudo chmod 600 /mnt/workspace/swapfile
          sudo mkswap /mnt/workspace/swapfile
          sudo swapon /mnt/workspace/swapfile

          df -h / /mnt/workspace/build



# Build Sync
repo init -u https://github.com/ProtonPlus-ORG/manifest -b tm-qpr3 --depth=1;

git clone https://github.com/AsTechpro20/local_manifests_blossom.git -b lineage-20 .repo/local_manifests;

repo sync -j$(nproc --all) --force-sync --no-tags --no-clone-bundle --prune --optimized-fetch;

repo sync 

echo "============="
echo "Sync success"
echo "============="

rm -rf .repo

 # Fix 2: Auto-convert lineage_blossom -> proton_blossom & rewrite common.mk paths
          if [ -d "device/xiaomi/blossom" ]; then
            cd device/xiaomi/blossom
            [ -f "lineage_blossom.mk" ] && mv lineage_blossom.mk proton_blossom.mk
            sed -i 's/lineage_blossom/proton_blossom/g' AndroidProducts.mk proton_blossom.mk
            find . -type f -exec sed -i \
              -e 's|vendor/lineage/config/common_full_phone.mk|vendor/proton/config/common.mk|g' \
              -e 's|vendor/lineage/config/common.mk|vendor/proton/config/common.mk|g' \
              -e 's|vendor/lineage|vendor/proton|g' {} +
            cd /mnt/workspace/build
          fi


# Installing packages 

echo "============="
echo "packages done"
echo "============="

# Export
export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "============="

# Lunch
lunch proton_blossom-userdebug

# Build
m otapackage
