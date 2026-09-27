#!/bin/bash


git config --global user.name "Abhinav"
git config --global user.email "abhinav@gmail.com"

repo init -u https://github.com/PotatoProject/manifest -b gnocchi-release --depth=1 

git clone https://github.com/Alromine95/local_manifests_blossom.git -b lineage-20 .repo/local_manifests

repo sync -c --no-tags --no-clone-bundle --optimized-fetch -j5 --force-sync

source build/envsetup.sh;
lunch potato_blossom-userdebug;
brunch blossom;
