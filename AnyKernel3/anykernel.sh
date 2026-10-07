### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
## Stormbreaker — miatoll family (curtana/excalibur/gram/joyeuse), A-only, boot header v2
## Full-stack flash: kernel + Stormbreaker's own DTB + DTBO (per-device overlays)

### AnyKernel setup
# global properties
properties() { '
kernel.string=Stormbreaker KernelSU (KSU + SUSFS v2.3.0 + NoMount v2.0.0)
kernel.compiler=Clang/LLVM 18 (LLVM=1, no GCC)
kernel.made=NothingTransition CI
kernel.version=4.14.357-openela
message.word=Stormbreaker stable for the miatoll family (curtana / excalibur / gram / joyeuse) — full-stack DTB/DTBO included.
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

# Full-stack flash: the zip bundles Stormbreaker's own dtb and dtbo.img.
# ak3-core picks $AKHOME/dtb (our dtb) over the ROM's, and flash_generic
# writes dtbo.img to the dtbo partition. dtb = shared miatoll base,
# dtbo = per-device overlays for curtana/excalibur/gram/joyeuse.

write_boot;
## end boot install
