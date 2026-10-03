# Stormbreaker

Custom kernel for the miatoll family, based on Linux 4.14.357 (OpenELA/CAF). KernelSU is built in, so you get root out of the box — the matching manager APK is attached to every release.

## Devices

| Codename | Device |
|---|---|
| curtana | Redmi Note 9S |
| joyeuse | Redmi Note 9 Pro |
| excalibur | Redmi Note 9 Pro Max |
| gram | Poco M2 Pro |

One zip for all four — it ships its own DTB and DTBO.

## Features

- KernelSU v3.3.0-52 built in (manager APK in the release)
- SUSFS v2.3.0 + NoMount v2.0.0 hiding stack, BRENE module bundled
- BFQ I/O scheduler and TCP BBR by default
- MGLRU backport (compiled in, off by default, runtime toggle)
- Memory tuned to installed RAM — 4/6/8 GB profiles applied at boot (kswapd reserve, swappiness, cache pressure, dirty limits, swapin readahead)
- ext4, F2FS (compression + encryption), EROFS, exFAT, NTFS
- Android 13–17 support — **A17 tested and working on Evolution X**; full ACK eBPF backport compiled in (ring buffer, in-kernel BTF, iterators, trampolines, **BPF LSM**) — sockmap/sk_msg stays off because that part of the backport does not compile here; see RELEASE_NOTES for the A16/A17 compatibility audit

## Flash

Flash the release zip in recovery, reboot, install the manager APK. Done.

## Credits

CAF/OpenELA · backslashxx (KernelSU) · simonpunk/sidex15 (SUSFS) · maxsteeel (NoMount) · osm0sis (AnyKernel3) · Google (MGLRU)

---

Flash at your own risk. Back up your boot and dtbo partitions if you want to be safe.
