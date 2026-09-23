# AnyKernel3 Structure - Stormbreaker

This is standard osm0sis AnyKernel3 structure.

```
AnyKernel3/
├── anykernel.sh          # Main flash script - kernel.string, device check, boot install
├── tools/                # Binaries for unpacking/repacking
│   ├── ak3-core.sh       # Core functions (DO NOT EDIT)
│   ├── busybox           # Busybox binary
│   ├── magiskboot        # Magisk boot image tool
│   └── magiskpolicy      # Magisk sepolicy tool
├── ramdisk/              # Ramdisk overlay files (optional)
│   └── .placeholder      # Keep folder in git
├── modules/              # Kernel modules (optional)
│   └── system/lib/modules/
│       └── .placeholder  # No modules - all built-in (USB_GSPCA, RMNET_PERF, RMNET_SHS removed)
├── patch/                # Patch files for ramdisk modifications (optional)
│   └── .placeholder
├── META-INF/             # Flashable zip metadata
│   └── com/google/android/
│       ├── update-binary # Flash binary (symlink to tools)
│       └── updater-script # Updater script
├── Image.gz              # Kernel image (generated after build)
└── Stormbreaker-*.zip    # Final flashable zip (generated)
```

## anykernel.sh explained
- `kernel.string`: Name shown in recovery
- `do.devicecheck=1`: Check device is miatoll family
- `do.modules=0`: No modules to flash (all built-in, 3 modules removed: USB_GSPCA, RMNET_PERF, RMNET_SHS)
- `do.systemless=1`: Support Magisk systemless
- `block`: Boot partition path
- `dump_boot` / `write_boot`: Standard AnyKernel3 boot install flow

## Build output
After `./build.sh`:
- `out/arch/arm64/boot/Image.gz` → copied to `AnyKernel3/Image.gz`
- Zipped as `AnyKernel3/Stormbreaker-miatoll-YYYYMMDD-HH.zip`

## No modules
This kernel has **zero modules** (`=m`):
- Previously had 3 modules: USB_GSPCA=m, RMNET_PERF=m, RMNET_SHS=m
- Now all disabled → all built-in or removed for cleaner structure
- If you need modules later, set `do.modules=1` and place .ko in `modules/system/lib/modules/`

## Flashing
Flash the zip in recovery (TWRP/OrangeFox) or via Magisk Manager (as boot image).

## Reference
- osm0sis AnyKernel3: https://github.com/osm0sis/AnyKernel3
- Original README.md in this folder has full documentation
