#!/bin/bash

git config --global user.name "Abhinav"
git config --global user.email "abhinav@gmail.com"


repo init -u https://github.com/ArrowOS/android_manifest.git -b arrow-14.0 --depth=1 ;

git clone https://github.com/Alromine95/local_manifests_blossom.git -b lineage-21 .repo/local_manifests ;

repo sync -c --no-tags --no-clone-bundle --optimized-fetch -j4 --force-sync ;

. build/envsetup.sh ;

lunch arrow_blossom-userdebug ;

m bacon ;
