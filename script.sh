#!/usr/bin/env bash
# Circle CI/CD - Simple kernel build script
# Copyright (C) 2019, 2020, Raphielscape LLC (@raphielscape)
# Copyright (C) 2019, 2020, Dicky Herlambang (@Nicklas373)
# Copyright (C) 2020, Muhammad Fadlyas (@fadlyas07)
git clone --depth=1 https://github.com/andeh24/kernel_xiaomi_msm8917 kernel -b simplified-purecaf
cd kernel
export parse_branch=$(git rev-parse --abbrev-ref HEAD)
git clone --depth=1 https://github.com/chips-project/priv-toolchains -b non-elf/gcc-9.2.0/arm gcc32
git clone --depth=1 https://github.com/chips-project/priv-toolchains -b non-elf/gcc-9.2.0/arm64 gcc
git clone --depth=1 --single-branch https://github.com/fabianonline/telegram.sh telegram
git clone --depth=1 --single-branch https://github.com/andeh24/anykernel-3 -b purecaf
mkdir $(pwd)/temp
export ARCH=arm64
export TEMP=$(pwd)/temp
export TELEGRAM_ID=-1001277959729
export TELEGRAM_TOKEN=1030153459:AAH61KzwmtwM8cMl630_i3OrDTIC0WOzkLk
export pack=$(pwd)/anykernel-3
export product_name=SimplifiedPureCAF
export device="Redmi Note 5A Lite"
export KBUILD_BUILD_HOST=$(git log --format='%H' -1)
export KBUILD_BUILD_USER=$(git log --format='%cn' -1)
export kernel_img=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
build_start=$(date +"%s")

tg_sendstick() {
   curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
 -d sticker="CAACAgUAAx0CRnUl0gACAYtefvnRLoB3iZVHd_znW5MWhZmTDAACXgAD7OCaHqb1LvxuHwQMGAQ" \
 -d chat_id="$TELEGRAM_ID"
}
TELEGRAM=telegram/telegram
tg_channelcast() {
    "$TELEGRAM" -c "$TELEGRAM_ID" -H \
 "$(
  for POST in "$@"; do
   echo "$POST"
  done
 )"
}
tg_build() {
export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-gnu-"
export CROSS_COMPILE_ARM32="$(pwd)/gcc32/bin/arm-linux-gnueabi-"
make O=out -j$(nproc --all)
}
date=$(TZ=Asia/Makassar date +'%H%M-%d%m%y')
make ARCH=arm64 O=out "ugglite_defconfig" && \
tg_build 2>&1| tee $(TZ=Asia/Makassar date +'%A-%H%M-%d%m%y').log
mv *.log $TEMP
if ! [[ -f "$kernel_img" ]]; then
    build_end=$(date +"%s")
    build_diff=$(($build_end - $build_start))
    curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
    tg_channelcast "<b>$product_name</b> for <b>$device</b> at commit <b>$(git log --pretty=format:'%s' -1)</b> Build errors in $(($build_diff / 60)) minutes and $(($build_diff % 60)) seconds."
    exit 1
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
mv $kernel_img $pack/zImage
cd $pack && zip -r9q $product_name-ugglite-$date.zip * -x .git README.md LICENCE $(echo *.zip)
cd ..
build_end=$(date +"%s")
build_diff=$(($build_end - $build_start))
kernel_ver=$(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)
toolchain_ver=$(cat $(pwd)/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
tg_channelcast "⚠️ <i>Warning: New build is available!</i> working on <b>$parse_branch</b> in <b>Linux $kernel_ver</b> using <b>$toolchain_ver</b> for <b>$device</b> at commit <b>$(git log --pretty=format:'%s' -1)</b>. Build complete in $(($build_diff / 60)) minutes and $(($build_diff % 60)) seconds."
curl -F document=@$(echo $pack/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
