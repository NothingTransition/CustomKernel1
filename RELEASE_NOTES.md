# Stormbreaker — curtana (Redmi Note 9 Pro / 9S) · Android 13/14/15/16 (any ROM)

Linux 4.14.357-openela · built with Clang/LLVM 18 · A-only flash

## Features

### Root & control
- KernelSU v3.3.0-51 — built-in, supercall-based (no kprobes, no daemon, no /su binary)
- KernelSU manager app bundled with the release, pinned to v3.3.0-51 (upstream pairing: kernel 32651, manager APK 32653)

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

### Networking
- **TCP BBR** congestion control — compiled in and set as the system default (CUBIC still available)
- BPF / eBPF support (syscall + JIT)

### Filesystems & compatibility
- EROFS support
- NTFS support
- F2FS with compression (LZO / LZ4 / ZSTD) + encryption + security labels
- Loadable module support with SHA512 signature verification (unsigned modules load with taint)
- **Two flashable variants:**
  - **Classic / full-stack (default name):** ships kernel + Stormbreaker's own DTB + DTBO — the traditional custom-kernel layout. Best for Infinity X / the ROM the DTB was built against.
  - **`-experimental`:** ships the kernel binary only and preserves your ROM's own DTB and DTBO at flash time — aimed at multi-ROM use (crDroid, LineageOS, other curtana ROMs, Android 13/14/15/16). A bundled DTB is kept only as a last-resort fallback.
- **Official osm0sis AnyKernel3 template**: flasher structure, `anykernel.sh` and all tools updated to the current upstream osm0sis/AnyKernel3 master layout

### Containers & Android 17 readiness
- **Droidspaces-ready** (LXC-like containers): PID/IPC/USER namespaces, SYSVIPC, POSIX mqueue, devtmpfs, full cgroup set (device/pids/net_prio), nftables + NAT/bridge netfilter enabled per the official Droidspaces non-GKI fragment; cgroup v1 prefix compatibility patch applied
- **Android 17 ready**: Android 17's bionic syscall surface is identical to Android 16's (274 syscalls, zero added); config audited against AOSP core kernel requirements — no new kernel features required

## Assets

| File | What it is |
|---|---|
| `Stormbreaker-miatoll-KSU-SUSFS-NoMount-*.zip` | Classic full-stack zip — kernel + Stormbreaker DTB + DTBO (recommended for Infinity X) |
| `Stormbreaker-miatoll-KSU-SUSFS-NoMount-*-experimental.zip` | Experimental multi-ROM zip — kernel only, keeps your ROM's own DTB/DTBO (crDroid / LineageOS / A13–A16 ROMs) |
| `KernelSU-manager.apk` | KernelSU manager app v3.3.0-51 — install **after** flashing + booting |
| `BRENE-v0.0.68.zip` | SUSFS rules module — install inside the KSU manager, then reboot |
| `NoMount-v2.0.0.zip` | NoMount module — install inside the KSU manager, then reboot |

## Install

1. Pick your zip: classic (Infinity X) or `-experimental` (any other curtana ROM).
2. Boot your ROM normally first.
3. From recovery (TWRP/OrangeFox), flash the chosen zip.
4. Boot the ROM.
5. Install `KernelSU-manager.apk`.
6. In the manager: install the BRENE and NoMount modules, then reboot.
