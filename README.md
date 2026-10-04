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

### Root & hiding
- **KernelSU** built in — driver vendored from backslashxx/KernelSU `v3.3.0-52` (`KSU_VERSION 32651`); no kprobes, no daemon, no `/su` binary
- Manager APKs attached to every release: **KernelSU `v3.3.0-55`** and **KernelSU-Next `v3.4.0`** (the kernel accepts either manager's signature)
- **SUSFS v2.3.0** — sus_path, sus_mount, sus_kstat, sus_map, spoof uname / cmdline+bootconfig, open_redirect, AVC log spoofing, KSU/SUSFS symbol hiding
- **NoMount v2.0.0** — per-app directory hiding via keyring rules
- **BRENE v0.0.68** module bundled — SUSFS rules control panel

### Memory
- **RAM-tier auto-tuning** — 4/6/8 GB profiles applied at boot (kswapd reserve via `extra_free_kbytes`, so ROM post_boot cannot erase it; swappiness, cache pressure, dirty limits, swapin readahead). Every value stays a runtime-overridable sysctl
- **zram** — lz4 and zstd compressors selectable at runtime, dedup built in
- MGLRU backport stays in-tree but **compiled out since #109** — it was never active, and CI keeps it out

### Storage & I/O
- **CFQ** I/O scheduler default; **BFQ** (with per-app cgroup support), deadline and kyber still selectable per disk
- **BLK_WBT** writeback throttling (sq + mq) — smooths background writes so foreground stays responsive
- ext4 (+ FBE), **F2FS** (compression LZO/LZ4/ZSTD + encryption + security labels), **EROFS** (+ ZIP), exFAT, NTFS (read/write), VFAT — plus dm-verity, FBE, quotas and incremental-fs for Android

### CPU & scheduling
- Qualcomm **WALT** (`SCHED_WALT`) with `SCHED_TUNE` and `core_ctl`; schedutil governor built in
- **cpu-boost** defaults to a 1.8 GHz input boost on all cores, so the UI responds even on ROMs that never configure it
- HZ 300 for finer UI scheduling; PSI for modern Android

### Networking
- **BBR** default congestion control (Vegas/Westwood+/BIC/HTCP also built in) and **fq_codel** default qdisc — no bufferbloat under load
- TCP defaults that survive idle periods and broken path-MTU discovery — all runtime-overridable; WiFi guidance (the ROM's `WCNSS_qcom_cfg.ini`) in RELEASE_NOTES

### Android
- **Android 13–17** — A17 tested on Evolution X; full ACK eBPF backport + **BPF LSM** (ring buffer, in-kernel BTF, iterators, trampolines); sockmap/sk_msg stays off because that part of the backport does not compile here — see RELEASE_NOTES for the A16/A17 compatibility audit
- Binder (`binder,hwbinder,vndbinder`), SELinux (enforcing, `checkreqprot=0`, bootparam), seccomp filter, KASLR, STRICT_KERNEL_RWX, INIT_ON_ALLOC, hardened usercopy
- **LZ4 ramdisk**, boot header v2, **A-only** device — one zip for curtana / excalibur / gram / joyeuse (own DTB + DTBO)

## Flash

Flash the release zip in recovery, reboot, install the manager APK. Done.

## Releases & tags

| Stream | Tag | What it is |
|---|---|---|
| Stable | `stormbreaker-v<N>` | One release per CI run, tagged with the run number; the zip inside is `Stormbreaker-miatoll-KSU-SUSFS-NoMount-<N>.zip`. The newest is badged **Latest**; every release carries the same companions (both manager APKs, BRENE, NoMount). |
| Diagnostic | `diag-<N>` (**pre-release**) | Experimental bisect/test kernels (see `diag/README.md`). Never for daily use. |
| Known-good | `stormbreaker-v108` | The v105 tree. If a newer build misbehaves on a strict ROM, flash this. |
| Restored | `stormbreaker-v93` | Historical. Byte-identical zip from CI run #93, recovered from that run's artifact after the #110 cleanup pruned it (`restore-release.yml`). Not for daily use. |

Boot status on **Infinity X 4.0 (A17)**: `v108` is the one to flash — the newer
builds (`v109` and the `v110` housekeeping rebuild) are blocked there, because
that ROM currently only lets the Imperial-X kernel boot it; the bisect for that
is parked (see `diag/README.md`). The stack is field-tested working on
Evolution X A17.

## Build

Builds run in GitHub Actions on Ubuntu 24.04 with the distro LLVM toolchain — no local cross-compiler needed:

- **Workflow:** `.github/workflows/build-miatoll.yml` — build → verify → package → release.
- **Trigger:** a push to a trigger branch (`arena/01a0bfbb-customkernel1`, `arena/01a1039d-customkernel1`) touching the paths the workflow watches, or a manual run (`workflow_dispatch`).
- **Pipeline:** resolve `vendor/xiaomi/miatoll_defconfig` → hard-require the security/feature config set → compile kernel + DTB + DTBO (`LLVM=1`, `LLVM_IAS=1`) → verify KernelSU/SUSFS/NoMount and the required symbols are linked → package the AnyKernel3 zip → publish the numbered release with the manager APKs and companion modules.
- **Diagnostics:** experimental bisect kernels live in `diag/` and build on manual dispatch only — see `diag/README.md`.
- **Restore:** `.github/workflows/restore-release.yml` re-attaches a pruned release's original zip from the CI artifact of the run that built it (used once to bring back `v93`); it never rebuilds.

CI enforces: no duplicate defconfig symbols, the required config set must be present in the *resolved* `.config`, and features that are supposed to be gone (MGLRU since #109, the Droidspaces fragment, kprobes) stay gone.

## Credits

CAF/OpenELA · backslashxx (KernelSU) · simonpunk/sidex15 (SUSFS) · maxsteeel (NoMount) · osm0sis (AnyKernel3) · Google (MGLRU)

## License

GPL-2.0 — see `COPYING`. KernelSU, SUSFS, NoMount and AnyKernel3 keep their own licenses; see `CREDITS`.

---

Flash at your own risk. Back up your boot and dtbo partitions if you want to be safe.
