#!/bin/bash
#
# Compile script for QuicksilveR kernel
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0 # builtin bash timer
ZIPNAME="QuicksilveRV2-ginkgo-$(date '+%Y%m%d-%H%M').zip"
SDC_DIR="$HOME/tc/sdc-clang"
GCC_DIR="$HOME/tc/gcc"
GCC64_DIR="$HOME/tc/gcc64"
AK3_DIR="$HOME/android/AnyKernel3"
DEFCONFIG="vendor/ginkgo-perf_defconfig"

export PATH="${SDC_DIR}/compiler/bin:${GCC64_DIR}/bin:${GCC_DIR}/bin:/usr/bin:${PATH}"

if ! [ -d "$SDC_DIR" ]; then
echo "Sdclang not found! Cloning to $SDC_DIR..."
if ! git clone https://github.com/ThankYouMario/proprietary_vendor_qcom_sdclang -b 12  --depth=1 $SDC_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "$GCC64_DIR" ]; then
echo "aarch64-linux-android-4.9 not found! Cloning to $GCC64_DIR..."
if ! git clone https://github.com/WisnuArdhi28/aarch64-linux-android-4.9 -b main --depth=1 $GCC64_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "$GCC_DIR" ]; then
echo "arm-linux-androideabi-4.9 not found! Cloning to $GCC_DIR..."
if ! git clone https://github.com/WisnuArdhi28/arm-linux-androideabi-4.9 -b main --depth=1 $GCC_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

export KBUILD_BUILD_USER=WisnuArdhi28
export KBUILD_BUILD_HOST=localhost

if [[ $1 = "-r" || $1 = "--regen" ]]; then
make O=out ARCH=arm64 $DEFCONFIG savedefconfig
cp out/defconfig arch/arm64/configs/$DEFCONFIG
exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 LD_LIBRARY_PATH="${SDC_DIR}/lib:${LD_LIBRARY_PATH}" CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_ARM32=arm-linux-androideabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz-dtb dtbo.img

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
if [ -d "$AK3_DIR" ]; then
cp -r $AK3_DIR AnyKernel3
elif ! git clone -q https://github.com/Hengker-Development/AnyKernel3; then
echo -e "\nAnyKernel3 repo not found locally and cloning failed! Aborting..."
exit 1
fi
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
rm -f *zip
cd AnyKernel3
git checkout master &> /dev/null
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
rm -rf AnyKernel3
rm -rf out/arch/arm64/boot
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
curl -T $ZIPNAME oshi.at; echo
else
echo -e "\nCompilation failed!"
exit 1
fi
