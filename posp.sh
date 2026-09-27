#/bin/bash


repo init -u https://github.com/PotatoProject/manifest -b gnocchi-release --depth=1 



repo sync -c --no-tags --no-clone-bundle --optimized-fetch -j4 --force-sync

source build/envsetup.sh;
lunch potato_blossom-userdebug;
brunch blossom;
