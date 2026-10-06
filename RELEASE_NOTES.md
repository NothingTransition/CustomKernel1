# Stormbreaker — miatoll family (Redmi Note 9 Pro / 9S: curtana · excalibur · gram · joyeuse)

Linux 4.14.357-openela · built with Clang/LLVM 18 · A-only flash

## Features

### Root & control
- **BakaSU v4.2.0-rc3** (formerly ReSukiSU) — built-in, supercall-based (no kprobes, no daemon, no /su binary); `KSU_VERSION 35171`, the same version code the shipped manager reports
- **SUSFS inline-hook mode.** Tracepoint hooks are GKI 2.0 (5.10+) only and the plain manual hook carries no SUSFS, so the driver runs in its SUSFS inline-hook mode against the v2.3.0 kernel side. All seven hook sites it requires are in the tree and are verified by the driver's own `inline_hook_check.mk` during the build
- **Only the BakaSU manager family is accepted.** Two certificates are trusted: BakaSU/ReSukiSU (`0x377`, `d3469712…`) and the official KernelSU certificate (`c371061b…`). The fork certificates the driver knows about (5ec1cff, rsuntk, SukiSU-Ultra, KOWX712) are deliberately rejected — `CONFIG_KSU_MULTI_MANAGER_SUPPORT` is off
- Manager APK bundled with the release: **BakaSU v4.2.0-rc3** (`BakaSU-manager.apk`, the universal `ReSukiSU_v4.2.0-rc3_35171` build)

### Hiding stack
- **SUSFS v2.3.0** — full feature set:
  - sus_path (+ looped variant) — hide configured paths
  - sus_mount — hide configured mounts per app
  - sus_kstat — spoof file metadata
  - uname spoofing
  - cmdline / bootconfig spoofing
  - open_redirect — redirect file opens
  - sus_map — /proc/maps and fdinfo spoofing
  - SELinux context hiding + KSU/SUSFS symbol hiding
  - AVC log spoofing
- **NoMount v2.0.0** — per-app directory hiding via keyring rules
- **BRENE v0.0.68** module bundled — SUSFS rules control panel

### Storage / IO
- **BFQ** I/O scheduler — the system default in this lineage (as in the original v93 build). **CFQ**, deadline, mq-deadline, noop and kyber all stay compiled in and selectable per-disk
- BFQ cgroup (per-app) scheduling support
- **BLK_WBT** block writeback throttling (sq + mq) — smooths background writes so foreground operations stay responsive

### Memory
- **Stock VM defaults** — this build is the v93 lineage: the boot-time RAM-tier tuning of the withdrawn #96–#110 stream is not in it. `swappiness` (60), `vfs_cache_pressure` (100), `dirty_ratio`/`dirty_background_ratio` (20/10), `watermark_scale_factor` (20) and `page_cluster` (3) are the kernel's own defaults
- **zram** — built in with **dedup**; the boot default compressor is the stock **lzo**, with **lz4** selectable at runtime via `/sys/block/zram0/comp_algorithm`. `zstd` is not compiled into this lineage
- **Multigenerational LRU (MGLRU)** — the backport is compiled in (`CONFIG_LRU_GEN=y`) and stays **off at runtime** by default (`/sys/kernel/mm/lru_gen/enabled` turns it on). Source and `Documentation/vm/multigen_lru.rst` are in the tree

### Networking
- **BBRplus** congestion control — set as the **system default**. Google's BBR v1 with BBR v2 backports: ACK-aggregation tracking (`bbr_extra_acked`, 10-round-trip window, 100 ms cap) plus a variable PROBE_BW gain-cycle length with randomized phase start. The ACK fix is the point on cellular — when GRO and delayed ACKs compress the ACK stream, plain BBR v1 underestimates the delivery rate and under-paces
- **Plain BBR v1 is built in too** and is one sysctl away: `echo bbr > /proc/sys/net/ipv4/tcp_congestion_control`
- **CUBIC, Vegas, Westwood+, BIC and HTCP** are built in as well — switchable per-route/app
- **FQ_CODEL** and **FQ** packet schedulers built in — the default qdisc is the stock `pfifo_fast` in this lineage; switch an interface with `tc qdisc replace dev <if> root fq_codel`
- TCP sysctls are stock — the #105 `net_tune` defaults are not in this build (see the networking section below for the values and how to set them if you want them)
- BPF / eBPF support (syscall + JIT)

### Filesystems & compatibility
- EROFS support
- NTFS support
- F2FS with compression (LZO / LZ4 / ZSTD) + encryption + security labels
- Loadable module support with SHA512 signature verification (unsigned modules load with taint)
- **Whole miatoll family supported**: the zip ships kernel + Stormbreaker's own DTB + DTBO. The DTB is the shared miatoll base (`cust-atoll-ab`) and the DTBO carries per-device overlays for **curtana, excalibur, gram and joyeuse** — one zip flashes all four
- **Official osm0sis AnyKernel3 template**: flasher structure, `anykernel.sh` and all tools updated to the current upstream osm0sis/AnyKernel3 master layout

### Android 16/17 readiness
- **Containers / Droidspaces — on** (v93 lineage): SYSVIPC, POSIX mqueue, PID and USER namespaces, cgroup device/pids/net_prio, nftables, bridge netfilter and xt addrtype are compiled in, on top of the UTS/NET namespaces, VETH/BRIDGE, cgroups, overlayfs and netfilter core — so Docker-style containers work
- **Android 15 ROM parity**: MSDOS_FS, EXT4_ENCRYPTION, NETFILTER_XT_TARGET_TRACE aligned with A13-A15 ROM kernels
- **Android 17 boot parity — tested working on Evolution X A17 (miatoll)**: defconfig aligned with a known-working Imperial-X A17 build (extracted from its shipped kernel config) — LZ4 ramdisk decompression (RD_LZ4), audit subsystem, full ftrace/tracing core, netfilter LOG/NFLOG/quota2-log targets, HIDRAW (FCM 7), EROFS per-cpu decompression kthreads, larger kernel log buffer. Boots past the OS animation where earlier builds hung at the boot logo. If a specific A17 ROM still misbehaves, report it — the stack has a runtime kill switch and builds are preserved per release for rollback

### Android 16/17 compatibility — what a non-GKI 4.14 kernel actually needs

Google's support matrix lists only ACK kernels (5.10 and newer) for A16/A17, so 4.14 is a **legacy** path. What decides it in practice is **eBPF**: Android 16+ leans on the newer eBPF feature set, and the requirement on old kernels is "1:1 eBPF backports, feature equivalent to Linux 5.4". This tree carries the full ACK eBPF backport — a **superset of 5.4** (BPF ring buffer, in-kernel BTF, BPF iterators, trampolines + dispatcher, local/inode storage, struct_ops, bpf_fs). This lineage compiles with **BPF LSM off** (`# CONFIG_BPF_LSM is not set`); the eBPF backport itself (ring buffer, in-kernel BTF, iterators, trampolines, struct_ops) stays in. The **BPF stream parser** (sockmap/sk_msg) is **on** since the #103 compile gap in `net/core/skmsg.c` was fixed at the source (the callback it failed to save is now captured where the other `saved_*` callbacks are), so `skmsg.o` / `sock_map.o` / `tcp_bpf.o` are built in and `BPF_MAP_TYPE_SOCKMAP` works.

Android userspace requirements verified present in this kernel:

| Area | What the kernel provides |
|---|---|
| eBPF | syscall + JIT (JIT always-on, unprivileged off), cgroup BPF, tc BPF, ring buffer, iterators, sockmap/sk_msg stream parser (BPF LSM: see gaps) |
| Memory / limits | PSI (on by default — used by lmkd), cgroups (sched, cpuacct, freezer, pids, devices, net_prio, cpuset), WALT + SCHED_TUNE + schedutil |
| Security | SELinux (develop + bootparam + AVC stats, checkreqprot=0), namespaces incl. user, seccomp filter, KASLR, STRICT_KERNEL_RWX, HARDENED_USERCOPY, INIT_ON_ALLOC, PAN/UAO |
| Storage / encryption | FBE (ext4 + f2fs encryption), metadata encryption (`dm-default-key`), AVB (`dm-verity`), fs-verity, project quotas, incremental FS, EROFS/exFAT/NTFS |
| IPC / IO | binder + hwbinder + vndbinder, ashmem, ion, sync_file, devtmpfs, tmpfs xattr/ACL, overlayfs, FUSE |
| Networking | nftables + xtables, conntrack, eBPF tc, TUN/PPP(-MPPE)/L2TP/IPsec, veth/bridge/NAT, XFRM |

Known gaps, stated plainly:

- **uclamp is not in this tree at all** (no code — not merely disabled). Android task profiles can use uclamp to boost the foreground; here ROMs fall back to Qualcomm's WALT/SCHED_TUNE, which is what this SoC generation actually ships with. Adding uclamp means backporting 5.x scheduler-core changes — a project on its own, not a defconfig toggle.
- **sockmap / sk_msg (`CONFIG_BPF_STREAM_PARSER`) is on again** (fixed after the #103 failure). The backport had left `sk_psock_init()` in `net/core/skmsg.c` reading an undeclared local `prot` — a line from the 5.x version that this tree's older backport does not have, and which was never compiled because the option was off. The callback that line was meant to save, `saved_destroy`, is now captured in `sk_psock_update_proto()` next to `saved_unhash` / `saved_close` / `saved_write_space`, exactly where the rest of the backport captures its callbacks, so `sock_map_destroy()` gets a valid destructor. `skmsg.o`, `sock_map.o` and `tcp_bpf.o` build, CI asserts them in the linked image, and BPF programs that use `BPF_MAP_TYPE_SOCKMAP` are available again.
- **Android's BPF userspace is told a release it can use** (`CONFIG_FAKE_UNAME_5_10`, init/Kconfig "Fake uname kernel version"). `bpfloader`, `netbpfload`, `netd` and `uprobestats` — root only, by `comm` — see `5.10.239` instead of `4.14.357`, because they choose their BPF program set/feature level from `uname()` and this kernel's BPF is a v5.10 backport. Every other process sees the real release. This is composed with SUSFS: the fake is applied first and `susfs_spoof_uname()` runs after, so a manager-configured SUSFS uname always wins and nothing about SUSFS behaviour changes. Choose another level (`5_4`, `5_15`, `6_1`, `6_6`, `6_12`) or `NONE` in the same Kconfig choice.
- **`CONFIG_DEBUG_INFO_BTF` is off.** It generates the kernel's own BTF for CO-RE (bpftrace/BCC and some loader paths) at the cost of debug info plus the `pahole` tool in the build — a bigger image and a longer build. ROMs boot fine without it; ask for an instrumented build if you need it.
- **16 KB page size** (an Android 15+ requirement for *new* devices) isn't applicable here: this SoC's vendor blobs and this 4.14 tree are 4 KB-page. Apps are unaffected on a 4 KB kernel.
- Intentionally off for performance/size, not compatibility: KPTI (`UNMAP_KERNEL_AT_EL0` — atoll's cores aren't Meltdown-affected), `FORTIFY_SOURCE`, `SCHED_AUTOGROUP`.

### Network tuning: mobile data + WiFi

The kernel cannot raise what the radio gives you — peak throughput is modem firmware, carrier provisioning, band and signal. What it *can* do is use the link well. This lineage ships **stock TCP sysctls** with **BBRplus already the default congestion control**, so the one change with real effect under load is in. The #105 `net_tune` defaults (`fq_codel` as default qdisc, `tcp_slow_start_after_idle=0`, `tcp_mtu_probing=1`) are **not** applied at boot here; they remain ordinary sysctls you can set yourself at runtime (root):

| Knob | This build | #105 value, if you want it | Why anyone wants it |
|---|---|---|---|
| `tcp_congestion_control` | `bbrplus` | `bbr` | BBRplus (BBR v1 + the v2 ACK-aggregation fix) behaves far better than CUBIC on lossy, high-RTT cellular links; plain `bbr` is built in too — `echo bbr > /proc/sys/net/ipv4/tcp_congestion_control` |
| `net.core.default_qdisc` | `pfifo_fast` (stock) | `fq_codel` | fq_codel keeps queue delay low, so uploads stop ballooning RTT |
| `tcp_slow_start_after_idle` | `1` (stock) | `0` | Keeps the congestion window across idle periods instead of re-ramping |
| `tcp_mtu_probing` | `0` (stock) | `1` | Finds a working MSS when the path drops ICMP "fragmentation needed" |

Set the last three at runtime if you want the #105 behavior (they do not survive a reboot unless a ROM script or module re-applies them):

```
echo fq_codel > /proc/sys/net/core/default_qdisc
echo 0 > /proc/sys/net/ipv4/tcp_slow_start_after_idle
echo 1 > /proc/sys/net/ipv4/tcp_mtu_probing
```

Verify what you have (root):

```
cat /proc/sys/net/ipv4/tcp_congestion_control      # bbrplus
cat /proc/sys/net/core/default_qdisc               # pfifo_fast unless you changed it
cat /proc/sys/net/ipv4/tcp_slow_start_after_idle   # 1
cat /proc/sys/net/ipv4/tcp_mtu_probing             # 0
```

Two honest notes. A qdisc change applies to network devices created **after** it is set; the data interfaces (`rmnet_data*` for cellular, `wlan0`) are created at runtime after boot, so they get it — an interface that already existed keeps its old qdisc until recreated, or fix it per device with `tc qdisc replace dev <if> root fq_codel` (needs the `tc` tool). And explicitly **not** done here: raising `tcp_rmem`/`tcp_wmem`. Those windows are auto-tuned per connection and already sized for fast links; oversized static buffers don't raise throughput, they add queuing delay and pin memory. "Internet booster" scripts that do that are placebo.

#### WiFi: what a kernel can and cannot do

The driver is in this kernel (`qcacld-3.0`), but the settings that matter for WiFi speed and latency are read by that driver from the ROM's config file at load, not from the kernel image. Peak speed itself is decided by band (5 GHz vs 2.4 GHz), channel width, distance/RSSI and the AP — no kernel change touches that.

The file is `WCNSS_qcom_cfg.ini`. Locate yours:

```
find /vendor /system/etc -name "WCNSS_qcom_cfg.ini" 2>/dev/null
# common: /vendor/etc/wifi/WCNSS_qcom_cfg.ini
```

Keys this driver actually parses that are worth knowing (all confirmed present in this tree's qcacld):

| Key | Effect | Trade-off |
|---|---|---|
| `gChannelBondingMode5GHz` | `1` enables 40/80 MHz bonding on 5 GHz — usually already 1 and the biggest single speed factor when it isn't | none if the AP supports it |
| `gChannelBondingMode24GHz` | 40 MHz on 2.4 GHz | often **worse** in crowded 2.4 GHz — leave off unless you know your environment |
| `gEnableAMPDU` | frame aggregation, leave `1` | disabling it always costs throughput |
| `gEnableImps` / `gEnableBmps` | idle / beacon-mode power save; `0` = radio stays awake | less latency, **more battery drain** — this is the battery-vs-responsiveness dial |
| `gEnableDynamicDTIM` / `gEnableModulatedDTIM` | dynamic/adaptive DTIM sleep (`0` = less sleeping) | same trade: latency vs battery |
| `gTxPowerCap` | max TX power cap in dBm | changing it can hurt range or violate regulatory limits — leave alone |

Editing the ini needs root and a rewrite of `/vendor` (Magisk module or overlay is the clean way); it is a ROM-side change, not a kernel one, so it is documented here rather than shipped in the image. If a specific ROM already sets these well, leave it alone.



| File | What it is |
|---|---|
| `Stormbreaker-miatoll-KSU-SUSFS-NoMount-*.zip` | Flashable AnyKernel3 zip — kernel + Stormbreaker DTB + DTBO (all four miatoll devices) |
| `BakaSU-manager.apk` | BakaSU manager app v4.2.0-rc3 (`KSU_VERSION 35171`) — install **after** flashing + booting |
| `BRENE-v0.0.68.zip` | SUSFS rules module — install inside the KSU manager, then reboot |
| `NoMount-v2.0.0.zip` | NoMount module — install inside the KSU manager, then reboot |

## Install

1. Flash the zip from recovery (TWRP/OrangeFox) — works on any miatoll device (curtana / excalibur / gram / joyeuse).
2. Boot the ROM.
3. Install `BakaSU-manager.apk`.
4. In the manager: install the BRENE and NoMount modules, then reboot.
