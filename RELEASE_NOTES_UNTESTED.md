# ⚠️ UNTESTED PRE-RELEASE — flash at your own risk

This build has **passed CI compilation + symbol verification only. It has NOT
been boot-tested on hardware.** If your device bootloops, reflash your
previous kernel via fastboot/recovery.

**Target:** Redmi Note 9 Pro India / Redmi Note 9S (`curtana`), miatoll
family — A-only partitioning, boot header v2, LZ4 ramdisk.
**ROM:** AOSP custom ROMs, primary target **Android 16 Infinity X**.

---

## What's in this kernel

| Component | Version | Notes |
|---|---|---|
| Base | 4.14.357-openela | Stormbreaker sm6250 tree, final 4.14 stable |
| Toolchain | Clang/LLVM 18 | full `LLVM=1`, no GCC |
| KernelSU | Backslashxx v3.3.0-48 | manually integrated, supercall (no kprobes), built-in |
| SUSFS | **v2.3.0** | full feature set, built-in |
| NoMount | v2.0.0 | built-in |
| Modules | signed | SHA512, unsigned modules load with taint (not rejected) |
| Filesystems | EROFS, NTFS (RW) | + BPF / cgroup-BPF for Android networking |

### SUSFS v2.3.0 features enabled
- **SUS_PATH** — hide files/directories from target processes
- **SUS_MOUNT** — hide/s spoof mounts, mount-ID management
- **SUS_KSTAT** — spoof stat/statfs of any path (size, timestamps, blocks)
- **OPEN_REDIRECT** — redirect file opens to a different path (includes the
  upstream UAF + memory-leak + deadlock fixes)
- **SUS_MAP** — hide entries in /proc maps, smaps, pagemap, fdinfo
- **uname spoofing** — fake kernel version string per-app
- **cmdline / bootconfig spoofing**
- **AVC (SELinux) log spoofing**
- **hide suspicious mounts from non-SU processes**

### NoMount v2.0.0
Runtime mount concealment/restoration from userspace without extra modules —
complements SUSFS mount hiding.

---

## Assets in this release

| File | What it is |
|---|---|
| `Stormbreaker-miatoll-KSU-SUSFS-NoMount-UNTESTED-*.zip` | **Flashable AnyKernel3 zip** (kernel + dtb + dtbo; keeps your ROM's ramdisk, preserves existing root) |
| `KernelSU-manager.apk` | KernelSU manager app (Backslashxx v3.3.0-48, matches kernel) — install **after** flashing + booting |
| `BRENE-v0.0.68.zip` | SUSFS rules module — install inside the KSU manager, then reboot |
| `NoMount-v2.0.0.zip` | NoMount userspace module — install inside the KSU manager, then reboot |

## Flashing

1. Reboot to recovery (TWRP/OrangeFox) or use any kernel flasher app.
2. Flash the `Stormbreaker-miatoll-*.zip`.
3. Reboot system.
4. Install `KernelSU-manager.apk`, grant root.
5. In the manager: install `BRENE` and `NoMount` module zips → reboot.

Rollback = flash your previous kernel zip (this zip only touches boot + dtbo).

## Known caveats
- SUSFS mount-ID cloning needs real-device validation on non-GKI devices;
  report boot issues with logs.
- Kernel identifies as `4.14.357-openela`; SUSFS reports `v2.3.0`.
