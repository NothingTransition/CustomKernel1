# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers
# Stormbreaker Kernel - Miatoll - Pure Clang 18 Build

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Stormbreaker Kernel by kardebayan @ xda-developers
kernel.for=miatoll
kernel.compiler=Clang 18.1.0 (r547379)
kernel.made=kardebayan
kernel.version=4.14.357-Stormbreaker-Clang18
message.word=Stormbreaker | Pure Clang 18 | BBR | BPF | F2FS-NTFS | KernelSU Ready | No Modules
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=miatoll
device.name2=curtana
device.name3=excalibur
device.name4=gram
device.name5=joyeuse
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

# Begin Ramdisk Changes
# No ramdisk changes needed for this kernel - pure Image.gz
# Example: if you need to add init scripts, place them in ramdisk/ and use:
# insert_line init.rc "import /init.stormbreaker.rc" after "import /init.miui.rc" "import /init.stormbreaker.rc"

# End Ramdisk Changes

write_boot;
## end boot install

# shell variables for vendor_boot (if needed for future)
#block=vendor_boot;
#is_slot_device=1;
#ramdisk_compression=auto;
#patch_vbmeta_flag=auto;

# reset for vendor_boot patching
#reset_ak;

## AnyKernel vendor_boot install
#split_boot; # skip unpack/repack ramdisk since we don't need vendor_ramdisk access
#flash_boot;
## end vendor_boot install
