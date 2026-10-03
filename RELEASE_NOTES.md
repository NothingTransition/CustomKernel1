# Stormbreaker — miatoll family (Redmi Note 9 Pro / 9S: curtana · excalibur · gram · joyeuse)

Linux 4.14.357-openela · built with Clang/LLVM 18 · A-only flash

## Features

### Root & control
- KernelSU v3.3.0-52 — built-in, supercall-based (no kprobes, no daemon, no /su binary)
- KernelSU manager app bundled with the release, pinned to v3.3.0-52 (upstream pairing: kernel 32651, manager APK 32653)

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
- **BFQ** I/O scheduler — compiled in and set as the system default (replaces CFQ; noop/deadline/mq-deadline/kyber still selectable per-disk)
- BFQ cgroup (per-app) scheduling support
- **BLK_WBT** block writeback throttling (sq + mq) — smooths background writes so foreground operations stay responsive

### Memory
- **RAM-tier auto-tuning** — one image covers the whole miatoll family (4/6/8 GB), so the kernel detects installed RAM at boot and applies the profile that fits instead of one compromise for all. All values stay ordinary sysctls, so ROM init scripts / root can still override them:

  | knob | 4 GB | 6 GB | 8 GB |
  |---|---|---|---|
  | kswapd reserve (`watermark_scale_factor`) | ~38 MB | ~43 MB | ~39 MB |
  | `swappiness` | 100 | 100 | 100 |
  | `vfs_cache_pressure` | 150 | 125 | 100 |
  | `dirty_ratio` / `dirty_background_ratio` | 10 / 5 | 15 / 5 | 20 / 10 |
  | `page_cluster` (swapin readahead) | 0 | 0 | 0 |

  - The **kswapd reserve** is the anti-stutter one: stock leaves only ~7 MB on 4 GB, which is not enough to absorb an allocation burst, so the kernel falls into *direct* reclaim and everything stalls. ~40 MB on every tier lets reclaim happen in the background where it belongs.
  - **`swappiness = 100`** because swap here is zram (compressed RAM), not a disk — the 60 default is a rotating-disk heuristic that leaves zram underused.
  - **`page_cluster = 0`** because zram is random access: reading 8 pages to satisfy a 1-page swapin is wasted work.
- **Multigenerational LRU (MGLRU)** — backported from the Android 4.14 FROMLIST/BACKPORT series and compiled into the kernel (builds #97+ verify the symbols are linked in), **OFF by default** (stock/classic reclaim runs out of the box; early field report of a hang during idle charging under MGLRU — kept available for testing but not enabled). Its aging rate is now tuned per RAM tier, so enabling it needs no further setup.
  - Switch ON: `su -c "echo 1 > /sys/kernel/mm/lru_gen/enabled"`
  - Switch OFF: `su -c "echo 0 > /sys/kernel/mm/lru_gen/enabled"`
  - Check state: `su -c "cat /sys/kernel/mm/lru_gen/enabled"` (0 = classic, 1 = MGLRU)
  - Note: the switch resets to OFF on every reboot
  - Runtime stats: `/sys/kernel/mm/lru_gen`, debugfs stats off (LRU_GEN_STATS unset)

### Networking
- **TCP BBR** congestion control — compiled in and set as the system default
- Additional TCP congestion controls built in: **Vegas, Westwood+, BIC, HTCP** (plus CUBIC) — switchable per-route/app
- **FQ_CODEL** and **FQ** packet schedulers — bufferbloat control for steadier latency under load
- BPF / eBPF support (syscall + JIT)

### Filesystems & compatibility
- EROFS support
- NTFS support
- F2FS with compression (LZO / LZ4 / ZSTD) + encryption + security labels
- Loadable module support with SHA512 signature verification (unsigned modules load with taint)
- **Whole miatoll family supported**: the zip ships kernel + Stormbreaker's own DTB + DTBO. The DTB is the shared miatoll base (`cust-atoll-ab`) and the DTBO carries per-device overlays for **curtana, excalibur, gram and joyeuse** — one zip flashes all four
- **Official osm0sis AnyKernel3 template**: flasher structure, `anykernel.sh` and all tools updated to the current upstream osm0sis/AnyKernel3 master layout

### Containers & Android 17 readiness
- **Droidspaces-ready** (LXC-like containers): PID/IPC/USER namespaces, SYSVIPC, POSIX mqueue, devtmpfs, full cgroup set (device/pids/net_prio), nftables + NAT/bridge netfilter enabled per the official Droidspaces non-GKI fragment; cgroup v1 prefix compatibility patch applied
- **Android 15 ROM parity**: MSDOS_FS, EXT4_ENCRYPTION, NETFILTER_XT_TARGET_TRACE aligned with A13-A15 ROM kernels
- **Android 17 boot parity — tested working on Evolution X A17 (miatoll)**: defconfig aligned with a known-working Imperial-X A17 build (extracted from its shipped kernel config) — LZ4 ramdisk decompression (RD_LZ4), audit subsystem, full ftrace/tracing core, netfilter LOG/NFLOG/quota2-log targets, HIDRAW (FCM 7), EROFS per-cpu decompression kthreads, larger kernel log buffer. Boots past the OS animation where earlier builds hung at the boot logo. If a specific A17 ROM still misbehaves, report it — the stack has a runtime kill switch and builds are preserved per release for rollback

### Android 16/17 compatibility — what a non-GKI 4.14 kernel actually needs

Google's support matrix lists only ACK kernels (5.10 and newer) for A16/A17, so 4.14 is a **legacy** path. What decides it in practice is **eBPF**: Android 16+ leans on the newer eBPF feature set, and the requirement on old kernels is "1:1 eBPF backports, feature equivalent to Linux 5.4". This tree carries the full ACK eBPF backport — a **superset of 5.4** (BPF ring buffer, in-kernel BTF, BPF iterators, trampolines + dispatcher, local/inode storage, struct_ops, bpf_fs). Builds #104+ also compile in **BPF LSM**, which was present in the tree but switched off (`CONFIG_LSM` already listed `bpf`, so that entry was dead). The **BPF stream parser** (sockmap/sk_msg) had to stay off: turning it on broke the first build that tried (#103) and the reason is in the tree's code, not the config — see the gap list below.

Android userspace requirements verified present in this kernel:

| Area | What the kernel provides |
|---|---|
| eBPF | syscall + JIT (JIT always-on, unprivileged off), cgroup BPF, tc BPF, **BPF LSM**, ring buffer, iterators (sockmap/sk_msg: see gaps) |
| Memory / limits | PSI (on by default — used by lmkd), cgroups (sched, cpuacct, freezer, pids, devices, net_prio, cpuset), WALT + SCHED_TUNE + schedutil |
| Security | SELinux (develop + bootparam + AVC stats, checkreqprot=0), namespaces incl. user, seccomp filter, KASLR, STRICT_KERNEL_RWX, HARDENED_USERCOPY, INIT_ON_ALLOC, PAN/UAO |
| Storage / encryption | FBE (ext4 + f2fs encryption), metadata encryption (`dm-default-key`), AVB (`dm-verity`), fs-verity, project quotas, incremental FS, EROFS/exFAT/NTFS |
| IPC / IO | binder + hwbinder + vndbinder, ashmem, ion, sync_file, devtmpfs, tmpfs xattr/ACL, overlayfs, FUSE |
| Networking | nftables + xtables, conntrack, eBPF tc, TUN/PPP(-MPPE)/L2TP/IPsec, veth/bridge/NAT, XFRM |

Known gaps, stated plainly:

- **uclamp is not in this tree at all** (no code — not merely disabled). Android task profiles can use uclamp to boost the foreground; here ROMs fall back to Qualcomm's WALT/SCHED_TUNE, which is what this SoC generation actually ships with. Adding uclamp means backporting 5.x scheduler-core changes — a project on its own, not a defconfig toggle.
- **sockmap / sk_msg (`CONFIG_BPF_STREAM_PARSER`) is off, because the code in this tree cannot build.** The sockmap half of the eBPF backport is incomplete: `sk_psock_init()` in `net/core/skmsg.c` reads a local `prot` that the original 5.x version declares, and the line was left as-is when the backport was taken. Nobody noticed because the option was always off — build #103 was the first build to compile that file and died on it (`use of undeclared identifier 'prot'`). It is now off on purpose, CI hard-requires it to stay off, and a comment in the defconfig records the exact error. Making it work means porting/testing `skmsg.c` + `sock_map.c` properly; until then, BPF programs that use `BPF_MAP_TYPE_SOCKMAP` are not available. `BPF LSM` is unaffected (separate files).
- **`CONFIG_DEBUG_INFO_BTF` is off.** It generates the kernel's own BTF for CO-RE (bpftrace/BCC and some loader paths) at the cost of debug info plus the `pahole` tool in the build — a bigger image and a longer build. ROMs boot fine without it; ask for an instrumented build if you need it.
- **16 KB page size** (an Android 15+ requirement for *new* devices) isn't applicable here: this SoC's vendor blobs and this 4.14 tree are 4 KB-page. Apps are unaffected on a 4 KB kernel.
- Intentionally off for performance/size, not compatibility: KPTI (`UNMAP_KERNEL_AT_EL0` — atoll's cores aren't Meltdown-affected), `FORTIFY_SOURCE`, `SCHED_AUTOGROUP`.

### Network tuning: mobile data + WiFi

The kernel cannot raise what the radio gives you — peak throughput is modem firmware, carrier provisioning, band and signal. What it *can* do is use the link well, and that is what this build tunes. Being precise about the difference matters, so here is the whole change set:

| Knob | Value | Why | Change it back at runtime |
|---|---|---|---|
| `tcp_congestion_control` | `bbr` (already the default) | BBR behaves far better than CUBIC on lossy, high-RTT cellular links | `echo cubic > /proc/sys/net/ipv4/tcp_congestion_control` |
| `net.core.default_qdisc` | `fq_codel` (new) | The old default was `pfifo_fast`, which just fills up: upload anything and RTT balloons, so everything *feels* slow. fq_codel keeps the queue delay low and stops one bulk flow from starving the rest — this is the "smooth" part | `echo pfifo_fast > /proc/sys/net/core/default_qdisc` |
| `tcp_slow_start_after_idle` | `0` (new) | The stock default resets the congestion window whenever a flow has been idle, so the first seconds after the phone wakes are spent re-ramping | `echo 1 > /proc/sys/net/ipv4/tcp_slow_start_after_idle` |
| `tcp_mtu_probing` | `1` (new) | Some carriers/CGNATs drop ICMP "fragmentation needed"; without probing, connections hang on large packets instead of finding an MSS that gets through | `echo 0 > /proc/sys/net/ipv4/tcp_mtu_probing` |

Verify on the phone (root):

```
cat /proc/sys/net/ipv4/tcp_congestion_control      # bbr
cat /proc/sys/net/core/default_qdisc               # fq_codel
cat /proc/sys/net/ipv4/tcp_slow_start_after_idle   # 0
cat /proc/sys/net/ipv4/tcp_mtu_probing             # 1
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
| `KernelSU-manager.apk` | KernelSU manager app v3.3.0-52 — install **after** flashing + booting |
| `BRENE-v0.0.68.zip` | SUSFS rules module — install inside the KSU manager, then reboot |
| `NoMount-v2.0.0.zip` | NoMount module — install inside the KSU manager, then reboot |

## Install

1. Flash the zip from recovery (TWRP/OrangeFox) — works on any miatoll device (curtana / excalibur / gram / joyeuse).
2. Boot the ROM.
3. Install `KernelSU-manager.apk`.
4. In the manager: install the BRENE and NoMount modules, then reboot.
