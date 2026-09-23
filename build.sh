#!/bin/bash
# Stormbreaker Custom Kernel - Pure Clang 18 Fast Build
# No GCC, only Clang 18.1.0, ccache, fast

set -e

function compile()
{
    source ~/.bashrc 2>/dev/null || true
    source ~/.profile 2>/dev/null || true
    export LC_ALL=C
    export USE_CCACHE=1
    ccache -M 3G 2>/dev/null || true
    ccache -z 2>/dev/null || true

    TANGGAL=$(date +"%Y%m%d-%H")
    export ARCH=arm64
    export SUBARCH=arm64
    export KBUILD_BUILD_HOST=android-build
    export KBUILD_BUILD_USER="kardebayan"
    export KBUILD_COMPILER_STRING="Clang 18.1.0 Fast"

    # --- Pure Clang 18 Setup ---
    CLANG_DIR="${PWD}/clang"
    clangbin="${CLANG_DIR}/bin/clang"

    if [ ! -f "${clangbin}" ]; then
        echo "=== Clang 18 not found, downloading fast ==="
        rm -rf "${CLANG_DIR}"
        # Fast single-branch clone
        git clone --depth=1 --single-branch https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379 "${CLANG_DIR}" || \
        git clone --depth=1 --single-branch https://github.com/LineageOS/android_prebuilts_clang_host_linux-x86_clang-r547379 "${CLANG_DIR}" || \
        git clone --depth=1 --single-branch https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r530720 "${CLANG_DIR}"
    fi

    echo "=== Clang Version ==="
    "${CLANG_DIR}/bin/clang" --version
    "${CLANG_DIR}/bin/ld.lld" --version || true
    ccache --version 2>/dev/null || true

    rm -rf out
    mkdir -p out

    echo "=== Defconfig: vendor/xiaomi/miatoll_defconfig ==="
    PATH="${CLANG_DIR}/bin:${PATH}" \
    make O=out ARCH=arm64 vendor/xiaomi/miatoll_defconfig

    echo "=== Fast Pure Clang 18 Build (ccache + LLVM) ==="
    PATH="${CLANG_DIR}/bin:${PATH}" \
    make -j$(nproc --all) O=out \
        ARCH=arm64 \
        SUBARCH=arm64 \
        CC="ccache clang" \
        HOSTCC="ccache clang" \
        HOSTCXX="ccache clang++" \
        LD="ld.lld" \
        AR="llvm-ar" \
        NM="llvm-nm" \
        OBJCOPY="llvm-objcopy" \
        OBJDUMP="llvm-objdump" \
        READELF="llvm-readelf" \
        STRIP="llvm-strip" \
        CLANG_TRIPLE="aarch64-linux-gnu-" \
        CROSS_COMPILE="aarch64-linux-gnu-" \
        CROSS_COMPILE_ARM32="arm-linux-gnueabi-" \
        LLVM=1 \
        LLVM_IAS=1 \
        CONFIG_NO_ERROR_ON_MISMATCH=y \
        2>&1 | tee out/build.log

    ccache -s 2>/dev/null || true

    if [ -f "out/arch/arm64/boot/Image.gz" ]; then
        echo "Build OK: Image.gz $(du -h out/arch/arm64/boot/Image.gz)"
    elif [ -f "out/arch/arm64/boot/Image" ]; then
        echo "Build OK: Image $(du -h out/arch/arm64/boot/Image)"
        gzip -k out/arch/arm64/boot/Image || true
    else
        echo "Build FAILED"
        tail -n 100 out/build.log
        exit 1
    fi
}

function zupload()
{
    zimage=out/arch/arm64/boot/Image.gz
    [ -f "$zimage" ] || zimage=out/arch/arm64/boot/Image

    if [ ! -f "$zimage" ]; then
        echo "Failed To Compile Kernel"
        exit 1
    fi

    echo "Kernel Successful: $zimage"
    rm -rf AnyKernel
    cp -r AnyKernel3 AnyKernel
    cp "$zimage" AnyKernel/
    rm -f AnyKernel/STRUCTURE.md 2>/dev/null || true

    if [ -f "out/arch/arm64/boot/dtb" ]; then
        cp out/arch/arm64/boot/dtb AnyKernel/ 2>/dev/null || true
    fi

    cd AnyKernel
    zip -r9 Stormbreaker-miatoll-${TANGGAL}-Clang18-Fast.zip * -x .git README.md *placeholder .placeholder
    echo "Zip: $(ls -lh *.zip)"
    cd ..
}

compile
zupload
