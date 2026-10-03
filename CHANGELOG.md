# Stormbreaker — release changelog

Full feature documentation lives in RELEASE_NOTES.md (repo). This file is
what gets attached to each release: only what changed in that build.

## #97 — MGLRU restored (compiled into the kernel for real)
• Multigenerational LRU is back in the build — the port was sitting in mm/ all along, but the defconfig lines had been dropped as "dead", so MGLRU had silently disappeared from recent kernels
• CI now hard-requires the MGLRU options and verifies the symbols are linked into the kernel image, so it can't go missing silently again
• Still OFF by default (there is an old idle-charging hang report with it enabled): switch on with `su -c "echo 1 > /sys/kernel/mm/lru_gen/enabled"`, check with `su -c "cat /sys/kernel/mm/lru_gen/enabled"` — resets to off on reboot

## #96 — memory management pass
• zram default compression upgraded from lzo to lz4 — faster decompress AND better ratio (biggest win on 4GB devices)
• zstd now compiled in for zram — switch live via `echo zstd > /sys/block/zram0/comp_algorithm` (better compression, more CPU)
• zram stats enabled (root can inspect compression efficiency via zsmalloc debug)
• Removed dead MGLRU config lines — the code was never in this kernel, the defconfig entry was a silent no-op

## #95 — manager bumped to v3.3.0-55
• Shipped manager APK updated from v3.3.0-54 to v3.3.0-55 (versionCode 32656)
• Includes the #94 release-signature fix (dummy.keystore cert, pkg-locked) — manager recognition now works

## #94 — fix shipped manager recognition (release-signature entry restored)
• Kernel now verifies the backslashxx manager's real release signature (dummy.keystore cert 4359c171, locked to me.weishu.kernelsu) — this entry was accidentally dropped in the #83 whitelist trim and is why the manager showed "Unsupported"
• Official-priority crowning (#92) now actually sees the shipped manager; KSUN stays recognized, backslashxx wins when both installed
• Manager APK: backslashxx v3.3.0-54 (versionCode 32655)

## #93 — manager bumped to v3.3.0-54
• Shipped manager APK updated from v3.3.0-52 to v3.3.0-54 (versionCode 32655)
• Same both-managers recognition + backslashxx priority as #92

## #92 — both managers recognized, official priority
• Backslashxx KSU manager now always recognized even if KernelSU-Next is also installed
• Both managers stay compatible solo; when both are present, backslashxx manager wins

## #91 — smoothness pass
• Touch input-boost enabled by default (1.8GHz, kernel-side, ROM-independent)
• Timer tick 100Hz → 300Hz for finer UI scheduling

## #90 — per-manager driver number display
- KSUN manager now reads KSUN's own driver number (33294); shipped manager keeps 32651 — no mixed display

## #89 — manager choice: KernelSU-Next manager trusted + attached
- Kernel now also trusts the official KSUN manager signature; KSUN manager APK attached in releases alongside ours
- Each manager is reported its own driver number (no mixed version display between managers)

## #82 — A15 ROM config alignment + README rewrite
- Enabled MSDOS_FS, EXT4_ENCRYPTION, NETFILTER_XT_TARGET_TRACE (matches A15 ROM kernels)
- New short README (devices, features, flashing); A17 tested note kept

## #81 — audit fixes (selinux_hide matcher, kallsyms cleanup)

## #80 — release notes format change
- Release bodies are now short changelogs (this file) instead of the full
  feature doc; full docs stay in RELEASE_NOTES.md in the repo
- No functional kernel changes since #79

## #79 — Android 17 support
- **Tested working: Evolution X A17 (miatoll)** — boots past the OS
  animation; previously hung at boot logo on A17 ROMs
- A17 config parity ported from a known-working Imperial-X A17 kernel
  (config decompiled from its shipped binary): LZ4 ramdisk decompression
  (RD_LZ4), audit subsystem, ftrace/tracing core, netfilter
  LOG/NFLOG/quota2-log targets, HIDRAW (FCM 7 requirement), EROFS
  per-cpu decompression threads, larger kernel log buffer
- MGLRU shipped but **OFF by default** after an idle-charging hang report;
  manual toggle: `su -c "echo 1 > /sys/kernel/mm/lru_gen/enabled"`
  (state: `su -c "cat /sys/kernel/mm/lru_gen/enabled"`, resets to off on reboot)
- Bug fixes: selinux_hide dedup truncation, adb_root page leak, kallsyms
  prefix over-match, cgroup symlink error handling, defconfig =m leftovers
- Releases are numbered from now on and never deleted
