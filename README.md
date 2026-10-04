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

- KernelSU v3.3.0-55 built in (manager APK in the release)
- SUSFS v2.3.0 + NoMount v2.0.0 hiding stack, BRENE module bundled
- CFQ I/O scheduler (BFQ compiled in and selectable per disk) and TCP BBR by default
- MGLRU backport stays in-tree but compiled out since #109 — it was never active, and CI keeps it out
- Memory tuned to installed RAM — 4/6/8 GB profiles applied at boot (kswapd reserve via `extra_free_kbytes`, so ROM post_boot cannot erase it; swappiness, cache pressure, dirty limits, swapin readahead)
- ext4, F2FS (compression + encryption), EROFS, exFAT, NTFS
- Android 13–17 support — **A17 tested and working on Evolution X**; full ACK eBPF backport compiled in (ring buffer, in-kernel BTF, iterators, trampolines, **BPF LSM**) — sockmap/sk_msg stays off because that part of the backport does not compile here; see RELEASE_NOTES for the A16/A17 compatibility audit
- **Network tuning for mobile data** — BBR congestion control and `fq_codel` (no bufferbloat) as defaults, plus TCP defaults that survive idle periods and broken path-MTU discovery; all runtime-overridable. WiFi guidance (the ROM's `WCNSS_qcom_cfg.ini`) in RELEASE_NOTES

## Flash

Flash the release zip in recovery, reboot, install the manager APK. Done.

## Releases & tags

| Stream | Tag | What it is |
|---|---|---|
| Stable | `stormbreaker-v<N>` | One release per CI run, tagged with the run number; the zip inside is `Stormbreaker-miatoll-KSU-SUSFS-NoMount-<N>.zip`. The newest is badged **Latest**; every release carries the same companions (both manager APKs, BRENE, NoMount). |
| Diagnostic | `diag-<N>` (**pre-release**) | Experimental bisect/test kernels (see `diag/README.md`). Never for daily use. |
| Known-good | `stormbreaker-v108` | The v105 tree. If a newer build misbehaves on a strict ROM, flash this. |

Boot status on **Infinity X 4.0 (A17)**: `v108` boots; `v109` is the newest
build, but that ROM currently only lets the Imperial-X kernel boot it — the
bisect for that is parked (see `diag/README.md`). The stack is field-tested
working on Evolution X A17.

## Credits

CAF/OpenELA · backslashxx (KernelSU) · simonpunk/sidex15 (SUSFS) · maxsteeel (NoMount) · osm0sis (AnyKernel3) · Google (MGLRU)

---

Flash at your own risk. Back up your boot and dtbo partitions if you want to be safe.
