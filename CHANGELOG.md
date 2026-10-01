# Stormbreaker — release changelog

Full feature documentation lives in RELEASE_NOTES.md (repo). This file is
what gets attached to each release: only what changed in that build.

## #83 — vibration fix for custom ROMs
- aw8624 haptic input device renamed to "qti-haptics" on QCOM (matches ROM
  kernels) — A13 ROM vibrator HALs find it by that name; fixes no-vibration
  on crDroid A13

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
