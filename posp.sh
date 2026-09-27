#/bin/bash


repo init -u https://github.com/PotatoProject/manifest -b gnocchi-release --depth=1 



source build/envsetup.sh;
lunch potato_blossom-userdebug;
brunch blossom;
