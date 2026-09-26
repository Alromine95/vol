#!/bin/bash


repo init -u https://github.com/ArrowOS/android_manifest.git -b arrow-14.0 --depth=1 



repo sync -c --no-tags --no-clone-bundle --optimized-fetch -j4 --force-sync

. build/envsetup.sh

m bacon
