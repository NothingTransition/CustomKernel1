# Stormbreaker

A custom kernel for the **miatoll family** — the Redmi Note 9S / 9 Pro / 9 Pro Max and Poco M2 Pro. Built on the Linux 4.14.357 OpenELA/CAF base with KernelSU, SUSFS and NoMount baked in, so you get root and a working hiding stack from the first boot. One zip flashes all four devices.

## Supported devices

| Codename | Device |
|---|---|
| curtana | Redmi Note 9S |
| joyeuse | Redmi Note 9 Pro |
| excalibur | Redmi Note 9 Pro Max |
| gram | Poco M2 Pro |

The zip carries its own DTB and DTBO with overlays for all four, so there is nothing extra to flash per device. Devices are A-only — no A/B slot business.

## What's inside

**Root** — KernelSU v3.3.0-52 is built straight into the kernel (supercall style, no kprobes, no /su binary lying around). The matching manager APK is attached to every release, so you install the kernel, install the manager, done.

**Hiding** — SUSFS v2.3.0 (the full set: path hiding, mount hiding, kstat spoofing, uname/cmdline spoofing, maps/fdinfo spoofing, SELinux context and symbol hiding, AVC log spoofing) plus NoMount v2.0.0 for per-app directory hiding. The BRENE module comes bundled as the control panel. This is the part banking-style apps care about — it's the reason this kernel exists.

**I/O and networking** — BFQ as the default I/O scheduler, writeback throttling (BLK_WBT) so background writes don't stutter the UI, TCP BBR as the default congestion control with Vegas/Westwood+/BIC/HTCP available too, and FQ_CODEL for keeping latency flat when the line is busy.

**Memory** — Multigenerational LRU is backported from Google's 4.14 series but left **off by default** after a hang report during idle charging. It's there if you want to test it:

```
su -c "echo 1 > /sys/kernel/mm/lru_gen/enabled"   # on
su -c "echo 0 > /sys/kernel/mm/lru_gen/enabled"   # off
su -c "cat /sys/kernel/mm/lru_gen/enabled"        # check
```

It resets to off on every boot.

**Filesystems** — ext4, F2FS (with LZ4/LZO/ZSTD transparent compression and encryption), EROFS, exFAT, VFAT, NTFS (read/write) and FUSE — basically anything a miatoll ROM can throw at it, including encrypted /data.

## Android version support

The kernel is tuned for modern userspaces:

- **Android 17 — supported.** Boot parity was taken from a known-working A17 kernel (LZ4 ramdisk decompression, audit, ftrace core, netfilter logging targets, HIDRAW, EROFS decompression threads), and it has been **tested booting Evolution X A17 on miatoll** — gets past the boot animation where older builds hung.
- **Android 16** — daily driver territory, running as the main ROM on the test device.
- **Android 13 / 14 / 15** — config was checked against the kernels those ROMs build with; nothing missing.

If some ROM misbehaves, report it — every numbered release is kept on GitHub, so rollback is always one flash away.

## Flashing

1. Download the latest release zip (Releases page).
2. Boot into your custom recovery.
3. Flash the zip.
4. Reboot, install the bundled KernelSU manager APK, grant it root.

That's it. No firmware steps, no separate dtbo flashing.

## Releases

Builds are numbered (`stormbreaker-v<run>`) and old ones are never deleted. Each release carries a short changelog of what actually changed — see `CHANGELOG.md`. The full feature documentation lives in `RELEASE_NOTES.md`.

The kernel is built by GitHub Actions with Clang/LLVM 18 on every push to the working branch; zips in Releases are those CI artifacts.

## Credits

- CAF / OpenELA for the base
- backslashxx — KernelSU
- simonpunk / sidex15 — SUSFS
- maxsteeel — NoMount
- osm0sis — AnyKernel3 template
- Google and the Android common kernel team — MGLRU series

## Disclaimer

Flash at your own risk. This kernel replaces your boot image and ships its own DTB/DTBO — keep a backup of your boot and dtbo partitions if you like to be safe. No warranty, implied or otherwise.
