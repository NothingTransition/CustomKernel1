### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
## Stormbreaker — curtana (Redmi Note 9 Pro / 9S), A-only, boot header v2
## Multi-ROM: keeps the installed ROM's own DTB/DTBO (Android 13/14/15/16)

### AnyKernel setup
# global properties
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
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
dump_boot;

# Multi-ROM DTB handling: keep the installed ROM's own DTB so this kernel
# boots Android 13/14/15/16 ROMs alike. dtb.fallback is a last resort only.
if [ -s "$SPLITIMG/dtb" ]; then
  ui_print "- Keeping this ROM's own DTB (multi-ROM compatible)";
elif [ -s "$SPLITIMG/kernel_dtb" ]; then
  ui_print "- Keeping this ROM's own DTB (appended to kernel)";
  cat "$AKHOME/Image.gz" "$SPLITIMG/kernel_dtb" > "$AKHOME/Image.gz-dtb";
  rm -f "$AKHOME/Image.gz";
else
  if [ -s "$AKHOME/dtb.fallback" ]; then
    ui_print "- No ROM DTB detected; using bundled fallback DTB";
    cp -f "$AKHOME/dtb.fallback" "$SPLITIMG/dtb";
  else
    abort "No DTB found to build boot image. Aborting...";
  fi;
fi;

write_boot;
## end boot install
