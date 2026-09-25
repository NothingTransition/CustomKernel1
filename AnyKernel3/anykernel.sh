# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers
# Configured for Xiaomi miatoll family (curtana/excalibur/gram/joyeuse),
# A-only partitioning, boot header v2 (dtb inside boot image, LZ4 ramdisk)

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Stormbreaker KernelSU Universal (KSU + SUSFS v2.3.0 + NoMount v2.0.0)
kernel.compiler=Clang/LLVM 18 (LLVM=1, no GCC)
kernel.made=NothingTransition CI
kernel.version=4.14.357-openela
message.word=Stormbreaker stable for curtana — universal: boots Android 13/14/15/16 ROMs (keeps your ROM's own DTB/DTBO).
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=curtana
device.name2=excalibur
device.name3=gram
device.name4=joyeuse
device.name5=miatoll
supported.versions=
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;

## AnyKernel boot install
dump_boot;

## Multi-ROM DTB handling (Android 13/14/15/16 support):
## keep the ROM's own DTB so the kernel boots any curtana ROM.
## dtb.fallback (bundled) is only used when the ROM provides none.
if [ -s "$split_img/dtb" ]; then
  ui_print "- Keeping this ROM's own DTB (multi-ROM compatible)";
elif [ -s "$split_img/kernel_dtb" ]; then
  ui_print "- Keeping this ROM's own DTB (appended to kernel)";
  cat "$home/Image.gz" "$split_img/kernel_dtb" > "$home/Image.gz-dtb";
  rm -f "$home/Image.gz";
else
  if [ -s "$home/dtb.fallback" ]; then
    ui_print "- No ROM DTB detected; using bundled fallback DTB";
    cp -f "$home/dtb.fallback" "$split_img/dtb";
  else
    abort "No DTB found to build boot image. Aborting...";
  fi;
fi;

write_boot;
## end boot install
