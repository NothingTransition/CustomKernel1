#!/usr/bin/env bash
# Package the AnyKernel3 flashable zips (classic + experimental variants).
# Run from the kernel source root after a successful build (out/ populated).
set -euxo pipefail

rm -rf package artifacts
mkdir -p artifacts
rsync -a \
  --exclude='.gitignore' \
  --exclude='README.md' \
  --exclude='placeholder' \
  AnyKernel3/ package/

# Two zip variants from the same AnyKernel3 base (anykernel.sh decides at
# flash time which DTB path applies):
#  - classic     : Image.gz + our dtb + our dtbo (full-stack, like
#                  traditional custom kernels)
#  - experimental: Image.gz only; preserves the installed ROM's own DTB/DTBO
#                  (multi-ROM: Android 13/14/15/16)
cp out/arch/arm64/boot/Image.gz package/Image.gz
cp out/arch/arm64/boot/dtb.img package/dtb
cp out/arch/arm64/boot/dtbo.img package/dtbo.img

# No modules packaged: KSU/SUSFS/NoMount are fully built-in and the few
# defconfig =m leftovers are not needed in the zip. modules/ stays empty.
# keep ramdisk/ and patch/ dirs in the zip (empty is fine)
mkdir -p package/ramdisk package/patch

(
  cd package
  zip -r9 \
    "../artifacts/Stormbreaker-miatoll-KSU-SUSFS-NoMount-${GITHUB_RUN_NUMBER}.zip" .
)

# experimental variant: drop our dtb/dtbo, keep dtb as last-resort fallback
rm -f package/dtb package/dtbo.img
cp out/arch/arm64/boot/dtb.img package/dtb.fallback
(
  cd package
  zip -r9 \
    "../artifacts/Stormbreaker-miatoll-KSU-SUSFS-NoMount-${GITHUB_RUN_NUMBER}-experimental.zip" .
)

# Raw images + metadata alongside the flashable zips
cp kernel.release SHA256SUMS build-info.txt toolchain-info.txt artifacts/
cp out/arch/arm64/boot/Image.gz out/arch/arm64/boot/dtb.img out/arch/arm64/boot/dtbo.img artifacts/
sha256sum artifacts/Stormbreaker-miatoll-*.zip >> artifacts/SHA256SUMS
for z in artifacts/Stormbreaker-miatoll-*.zip; do unzip -l "$z"; done
