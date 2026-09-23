#!/bin/bash
# Stormbreaker Custom Kernel - Pure Clang 18 Build Script
# Fixed for: Module Signing, BPF, BBR, NTFS, F2FS, KernelSU readiness

set -e

function compile()
{
    source ~/.bashrc 2>/dev/null || true
    source ~/.profile 2>/dev/null || true
    export LC_ALL=C
    export USE_CCACHE=1
    ccache -M 25G 2>/dev/null || true

    TANGGAL=$(date +"%Y%m%d-%H")
    export ARCH=arm64
    export SUBARCH=arm64
    export KBUILD_BUILD_HOST=android-build
    export KBUILD_BUILD_USER="kardebayan"
    export KBUILD_COMPILER_STRING="Clang 18.1.0"

    # --- Pure Clang 18 Setup ---
    CLANG_VERSION="r547379"
    # Clang 18.1.0 from crdroid - known good for 4.14 pure clang builds
    CLANG_URL_PRIMARY="https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379"
    CLANG_URL_FALLBACK="https://github.com/LineageOS/android_prebuilts_clang_host_linux-x86_clang-r547379"
    # Alternative: Proton Clang 18 or ZyC clang
    CLANG_DIR="${PWD}/clang"

    clangbin="${CLANG_DIR}/bin/clang"

    if [ ! -f "${clangbin}" ]; then
        echo "=== Clang 18 not found, downloading ==="
        rm -rf "${CLANG_DIR}"
        if ! git clone --depth=1 "${CLANG_URL_PRIMARY}" "${CLANG_DIR}"; then
            echo "Primary URL failed, trying fallback..."
            if ! git clone --depth=1 "${CLANG_URL_FALLBACK}" "${CLANG_DIR}"; then
                echo "Trying Neutron Clang 18 (alternative)..."
                # Neutron clang 18 - direct tarball
                mkdir -p "${CLANG_DIR}"
                # Use AOSP clang r530720 which is clang 18.0.1
                # Fallback to downloading from Google if git fails
                git clone --depth=1 https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r530720 "${CLANG_DIR}" || \
                git clone --depth=1 https://github.com/kdrag0n/proton-clang --branch master "${CLANG_DIR}" || \
                (echo "Failed to download Clang 18" && exit 1)
            fi
        fi
    fi

    # Verify clang version is 18.x
    echo "=== Clang Version ==="
    "${CLANG_DIR}/bin/clang" --version
    "${CLANG_DIR}/bin/ld.lld" --version || true

    # Clean previous AnyKernel and out
    rm -rf AnyKernel
    rm -rf out
    mkdir -p out

    # Generate defconfig
    echo "=== Generating defconfig: vendor/xiaomi/miatoll_defconfig ==="
    PATH="${CLANG_DIR}/bin:${PATH}" \
    make O=out ARCH=arm64 vendor/xiaomi/miatoll_defconfig

    # --- Pure Clang 18 Build ---
    # For 4.14, pure clang build requires:
    # - LLVM=1 and LLVM_IAS=1 to use integrated assembler and llvm tools
    # - No GCC cross-compile, use clang triple
    # - LD=ld.lld, AR=llvm-ar, etc.
    echo "=== Starting Pure Clang 18 Build ==="
    PATH="${CLANG_DIR}/bin:${PATH}" \
    make -j$(nproc --all) O=out \
        ARCH=arm64 \
        SUBARCH=arm64 \
        CC="clang" \
        HOSTCC="clang" \
        HOSTCXX="clang++" \
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

    # Check for Image
    if [ -f "out/arch/arm64/boot/Image.gz" ]; then
        echo "Build produced Image.gz"
    elif [ -f "out/arch/arm64/boot/Image" ]; then
        echo "Build produced Image (uncompressed), compressing..."
        gzip -k out/arch/arm64/boot/Image || true
    fi
}

function zupload()
{
    zimage=out/arch/arm64/boot/Image.gz
    # Fallback to uncompressed Image
    if [ ! -f "$zimage" ]; then
        zimage=out/arch/arm64/boot/Image
    fi

    if [ ! -f "$zimage" ]; then
        echo "Failed To Compile Kernel - check out/build.log"
        echo "=== Last 200 lines of build log ==="
        tail -n 200 out/build.log || true
        exit 1
    else
        echo -e "Kernel Compile Successful: $zimage"
        if [ ! -d "AnyKernel" ]; then
            git clone --depth=1 https://github.com/Amritorock/AnyKernel3 -b r5x AnyKernel || \
            git clone --depth=1 https://github.com/osm0sis/AnyKernel3 AnyKernel
        fi
        cp "$zimage" AnyKernel/ || cp out/arch/arm64/boot/Image.gz AnyKernel/ || cp out/arch/arm64/boot/Image AnyKernel/
        # Also copy dtb if exists
        if [ -f "out/arch/arm64/boot/dtb" ]; then
            cp out/arch/arm64/boot/dtb AnyKernel/ || true
        fi
        if [ -d "out/arch/arm64/boot/dts" ]; then
            find out/arch/arm64/boot/dts -name "*.dtb" -exec cp {} AnyKernel/ \; 2>/dev/null || true
        fi
        cd AnyKernel
        zip -r9 Stormbreaker-miatoll-${TANGGAL}.zip * -x .git README.md *placeholder
        echo "Zip created: Stormbreaker-miatoll-${TANGGAL}.zip"
        cd ../
        ls -lh AnyKernel/*.zip
    fi
}

compile
zupload
