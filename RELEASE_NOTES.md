# Stormbreaker — curtana (Redmi Note 9 Pro / 9S) · AOSP Android 16 (Infinity X)

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
- Ships kernel + dtb + dtbo; preserves your ROM's ramdisk and existing root setup

### Containers & Android 17 readiness
- **Droidspaces-ready** (LXC-like containers): PID/IPC/USER namespaces, SYSVIPC, POSIX mqueue, devtmpfs, full cgroup set (device/pids/net_prio), nftables + NAT/bridge netfilter enabled per the official Droidspaces non-GKI fragment; cgroup v1 prefix compatibility patch applied
- **Android 17 ready**: Android 17's bionic syscall surface is identical to Android 16's (274 syscalls, zero added); config audited against AOSP core kernel requirements — no new kernel features required

## Assets

| File | What it is |
|---|---|
| `Stormbreaker-miatoll-*.zip` | Flashable AnyKernel3 zip (kernel + dtb + dtbo) |
| `KernelSU-manager.apk` | KernelSU manager app v3.3.0-51 — install **after** flashing + booting |
| `BRENE-v0.0.68.zip` | SUSFS rules module — install inside the KSU manager, then reboot |
| `NoMount-v2.0.0.zip` | NoMount module — install inside the KSU manager, then reboot |

## Install

1. Flash the zip.
2. Boot the ROM.
3. Install `KernelSU-manager.apk`.
4. In the manager: install the BRENE and NoMount modules, then reboot.
