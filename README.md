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
- **KernelSU** built in — driver vendored from backslashxx/KernelSU `v3.3.0-62` (`KSU_VERSION 32663`); no kprobes, no daemon, no `/su` binary
- **Only the backslashxx/KernelSU manager family is accepted**: release managers signed with the public dummy.keystore (package-locked to `me.weishu.kernelsu`) and self-built managers carrying the official KernelSU certificate. Fork managers (KernelSU-Next, KOWX712, …) are deliberately rejected
- Manager APK attached to every release: **KernelSU `v3.3.0-62`** (upstream build, shipped as `KernelSU-manager.apk`); the immutable copy on our `v111` release is the fallback
- **SUSFS v2.3.0** — sus_path, sus_mount, sus_kstat, sus_map, spoof uname / cmdline+bootconfig, open_redirect, AVC log spoofing, KSU/SUSFS symbol hiding
- **NoMount v2.0.0** — per-app directory hiding via keyring rules
- **BRENE v0.0.68** module bundled — SUSFS rules control panel

### Memory
- **Stock VM defaults** — this build is the v93 lineage: the boot-time RAM-tier tuning from the withdrawn #96–#110 stream is not in it. `swappiness`, `dirty_*`, `vfs_cache_pressure`, `watermark_scale_factor` are the kernel's own defaults
- **zram** — built in with dedup; `lz4` is available at runtime (`/sys/block/zram0/comp_algorithm`) while the boot default is the stock `lzo`. `zstd` is not compiled into this lineage
- **MGLRU** — the multigenerational LRU backport is compiled in (`CONFIG_LRU_GEN=y`) and stays off at runtime by default; `/sys/kernel/mm/lru_gen/enabled` turns it on. Source and `Documentation/vm/multigen_lru.rst` are in the tree

### Storage & I/O
- **BFQ** I/O scheduler default (as in the original v93 build); **CFQ**, deadline and kyber still selectable per disk
- **BLK_WBT** writeback throttling (sq + mq) — smooths background writes so foreground stays responsive
- ext4 (+ FBE), **F2FS** (compression LZO/LZ4/ZSTD + encryption + security labels), **EROFS** (+ ZIP), exFAT, NTFS (read/write), VFAT — plus dm-verity, FBE, quotas and incremental-fs for Android

### CPU & scheduling
- Qualcomm **WALT** (`SCHED_WALT`) with `SCHED_TUNE` and `core_ctl`; schedutil governor built in
- **cpu-boost** defaults to a 1.8 GHz input boost on all cores, so the UI responds even on ROMs that never configure it
- HZ 300 for finer UI scheduling; PSI for modern Android

### Networking
- **BBRplus** system default congestion control — Google's BBR v1 plus BBR v2 backports (ACK-aggregation tracking + variable PROBE_BW cycle) that fix v1's under-pacing when mobile-data ACKs arrive compressed. **Plain BBR v1 is built in too** and switchable at runtime (`echo bbr > /proc/sys/net/ipv4/tcp_congestion_control`), as are Vegas, Westwood+, BIC and HTCP
- **fq_codel** and **fq** packet schedulers built in — the default qdisc is the stock `pfifo_fast` in this lineage; select fq_codel per interface with `tc qdisc replace`
- TCP sysctls are stock (the #105 `net_tune` defaults are not in this build); WiFi guidance (the ROM's `WCNSS_qcom_cfg.ini`) in RELEASE_NOTES

### Android
- **Android 13–17** — A17 tested on Evolution X; full ACK eBPF backport (ring buffer, in-kernel BTF, iterators, trampolines) **plus the stream parser** — sockmap/sk_msg builds and is on (`BPF_MAP_TYPE_SOCKMAP` works); BPF LSM is off in this lineage. See RELEASE_NOTES for the A16/A17 compatibility audit
- Binder (`binder,hwbinder,vndbinder`), SELinux (enforcing, `checkreqprot=0`), seccomp filter, KASLR, STRICT_KERNEL_RWX, INIT_ON_ALLOC, hardened usercopy
- **LZ4 ramdisk**, boot header v2, **A-only** device — one zip for curtana / excalibur / gram / joyeuse (own DTB + DTBO)

## Flash

Flash the release zip in recovery, reboot, install the manager APK. Done.

## Releases & tags

| Stream | Tag | What it is |
|---|---|---|
| Stable | `stormbreaker-v<N>` | One release per CI run, tagged with the run number; the zip inside is `Stormbreaker-miatoll-KSU-SUSFS-NoMount-<N>.zip`. The newest is badged **Latest** and is the **default** build. |
| Restored | `stormbreaker-v93` | Byte-identical zip from CI run #93, recovered from that run's artifact (`restore-release.yml`). The lineage the current build continues. |
| Diagnostic | `diag-<N>` (**pre-release**) | Experimental bisect/test kernels (see `diag/README.md`). Never for daily use. |

The **#96–#110 lineage is withdrawn** (RAM-tier tuning, CFQ default, MGLRU and
Droidspaces compiled out, GKI-style `fq_codel` default). Those releases
(`v105`, `v108`, `v109`, `v110`) were deleted; the current build returns to the
v93 base and moves forward from there with the backslashxx driver.

Boot status on **Infinity X 4.0 (A17)**: that ROM currently only boots the
Imperial-X kernel reliably, so no Stormbreaker build is guaranteed there; the
bisect for the boot stall is parked (see `diag/README.md`). The stack is
field-tested working on Evolution X A17.

## Build

Builds run in GitHub Actions on Ubuntu 24.04 with the distro LLVM toolchain — no local cross-compiler needed:

- **Workflow:** `.github/workflows/build-miatoll.yml` — build → verify → package → release.
- **Trigger:** a push to a trigger branch (`arena/01a0bfbb-customkernel1`, `arena/01a1039d-customkernel1`) touching the paths the workflow watches, or a manual run (`workflow_dispatch`).
- **Pipeline:** resolve `vendor/xiaomi/miatoll_defconfig` → hard-require the security/feature config set → compile kernel + DTB + DTBO (`LLVM=1`, `LLVM_IAS=1`) → verify KernelSU/SUSFS/NoMount and the required symbols are linked → package the AnyKernel3 zip → publish the numbered release with the manager APK and companion modules.
- **Diagnostics:** experimental bisect kernels live in `diag/` and build on manual dispatch only — see `diag/README.md`.
- **Restore:** `.github/workflows/restore-release.yml` re-attaches a pruned release's original zip from the CI artifact of the run that built it (used once to bring back `v93`); it never rebuilds.

CI enforces: no duplicate defconfig symbols, the required config set must be present in the *resolved* `.config` (including the eBPF stream parser, whose objects and symbols are also checked in the linked image), the v93-lineage features (MGLRU, the container/namespace set, BFQ default) must be in it, and the options that must stay off (kprobes) stay off.

## Credits

CAF/OpenELA · backslashxx (KernelSU) · simonpunk/sidex15 (SUSFS) · maxsteeel (NoMount) · osm0sis (AnyKernel3) · Google (MGLRU)

## License

GPL-2.0 — see `COPYING`. KernelSU, SUSFS, NoMount and AnyKernel3 keep their own licenses; see `CREDITS`.

---

Flash at your own risk. Back up your boot and dtbo partitions if you want to be safe.
