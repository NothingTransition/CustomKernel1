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
- BFQ I/O scheduler by default
- Stock VM defaults — the RAM-tier auto-tuning was removed in #107 for a lighter, deadcode-free kernel (the knobs it touched are ordinary sysctls and can still be set at runtime)
- ext4, F2FS (compression + encryption), EROFS, exFAT, NTFS
- Android 13–17 support — **A17 tested and working on Evolution X**; full ACK eBPF backport compiled in (ring buffer, in-kernel BTF, iterators, trampolines, **BPF LSM**) — sockmap/sk_msg stays off because that part of the backport does not compile here; see RELEASE_NOTES for the A16/A17 compatibility audit
- **Network** — stock kernel defaults: **CUBIC is the only congestion control** (Vegas, Westwood+, BIC, HTCP and BBR removed in #107) with the kernel's `pfifo_fast` qdisc; #106 removed the custom defaults and boot-time TCP overrides for a lighter build. `fq_codel`/`fq` remain usable via `tc`; WiFi guidance (the ROM's `WCNSS_qcom_cfg.ini`) is in RELEASE_NOTES

## Flash

Flash the release zip in recovery, reboot, install the manager APK. Done.

## Credits

CAF/OpenELA · backslashxx (KernelSU) · simonpunk/sidex15 (SUSFS) · maxsteeel (NoMount) · osm0sis (AnyKernel3)

---

Flash at your own risk. Back up your boot and dtbo partitions if you want to be safe.
