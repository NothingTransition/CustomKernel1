# Stormbreaker — release changelog

Full feature documentation lives in RELEASE_NOTES.md (repo). This file is
what gets attached to each release: only what changed in that build.

## #81 — full-repo audit bug fix
- selinux_hide: context-hiding rule matcher switched to bounded
  `strnchr`/`strnstr` (upstream KernelSU hardening) — prevents a hidden
  source-type rule from matching inside the target half of a context
  string (audit finding #1, low severity, no user-visible change expected)
- kallsyms: removed a dead extern declaration found in the audit
- RELEASE_NOTES.md: recorded the Evolution X A17 test result in the full
  docs

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
