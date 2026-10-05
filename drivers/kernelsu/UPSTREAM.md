# KernelSU upstream provenance

This directory vendors the kernel component from:

- Repository: https://github.com/Baka-SU/BakaSU (formerly ReSukiSU)
- Tag: `v4.2.0-rc3`
- Commit: `239e1e8871b8fcd51a6e5b3002e0ba522fdd99fb`
- Driver version reported to userspace: **`KSU_VERSION 35171`**
  — upstream's own formula `30000 + <commit count> + 700` for `4471` commits
- Manager this pairs with: `ReSukiSU_v4.2.0-rc3_35171-universal-release.apk`
  from the same tag; the version code in its file name is the same `35171`,
  so the manager and the kernel agree on the ABI

It replaces the previous `backslashxx/KernelSU` v3.3.0-60 driver
(`KSU_VERSION 32657`), which was a unity build; this driver is a normal
multi-object kbuild.

## Local deviations from upstream v4.2.0-rc3

Four, all deliberate:

1. **Vendored, not a submodule — version pinned locally.** Upstream's
   `Kbuild` hard-errors unless the driver is a git submodule (*"You should
   use ReSukiSU as a git submodule instead of copying code directly"*) and
   derives the version from that repository's git history
   (`rev-list --count`, `describe`, `rev-parse`). This tree vendors its
   components rather than fetching them during kbuild — the same reasoning
   recorded in `fs/nomount/UPSTREAM.md`: reproducible builds that do not
   fetch or mutate source while Kbuild runs. That block was therefore
   replaced by `include $(KSU_SRC)/local_version.mk`, which pins the five
   values the upstream formula produces for the tag above. No git repository
   and no network access is required at build time.
2. **Manager policy.** `manager/apk_sign.c` accepts two certificates: the
   ReSukiSU/BakaSU one (`0x377` / `d3469712…`) and the official KernelSU one
   (`0x033b` / `c371061b…`). The four other certificates upstream knows about
   (5ec1cff, rsuntk, SukiSU-Ultra, KOWX712) stay behind
   `CONFIG_KSU_MULTI_MANAGER_SUPPORT`, which is **off** in the defconfig.
   The posture is unchanged from the previous driver: the manager family this
   tree ships is trusted, fork managers are not.
3. **Hook method: SUSFS inline hook** (`CONFIG_KSU_SUSFS` is the hook choice,
   not a plain "SUSFS support" switch as it was with the old driver). The
   tracepoint hook is GKI 2.0 / 5.10+ only, and the plain manual hook carries
   no SUSFS integration, so the inline-hook mode is the one that pairs with
   the v2.3.0 SUSFS kernel side in this tree. `CONFIG_KSU_TRACEPOINT_HOOK`
   and `CONFIG_KSU_MANUAL_HOOK` are both off.
4. **`CONFIG_KSU_SUSFS` also depends on `FUSE_FS`.** The SUSFS kernel side in
   this tree (`fs/susfs.c`) includes `fuse/fuse_i.h` and calls
   `get_fuse_inode()`, so a built-in FUSE is required. Upstream carries no
   such dependency because it targets GKI trees where FUSE is always present.
   The dependency is re-added locally and the requirement is also asserted in
   CI.

## Kernel-side hook sites

In SUSFS-inline-hook mode the driver supplies the hook *functions* and the
kernel tree supplies the *call sites*. `tools/inline_hook_check.mk` greps for
each of them during the build and fails hard if one is missing, so a silent
regression here is not possible:

| File | Symbol | Added by |
|---|---|---|
| `kernel/sys.c` | `ksu_handle_setresuid` | this integration |
| `fs/exec.c` | `ksu_handle_execveat` | pre-existing |
| `fs/open.c` | `ksu_handle_faccessat` | pre-existing |
| `fs/read_write.c` | `ksu_handle_sys_read` | this integration |
| `fs/stat.c` | `ksu_handle_stat` | pre-existing |
| `fs/stat.c` | `ksu_handle_newfstat_ret` | pre-existing |
| `fs/stat.c` | `ksu_handle_fstat64_ret` | pre-existing |
| `kernel/reboot.c` | `ksu_handle_sys_reboot` | pre-existing |
| `drivers/input/input.c` | `ksu_handle_input_handle_event` | this integration |

The check also rejects the *old* hook style (`ksu_vfs_read_hook`,
`ksu_input_hook`, `ksu_execveat_hook`, `ksu_init_rc_hook`,
`is_ksu_transition`). None of those are present.

The four `ksu_handle_*` calls already in the tree from the previous driver
were kept: their signatures match this driver exactly (verified against
`feature/sucompat.c` and `runtime/ksud_integration.c`), and
`runtime/ksud_integration.c` defines `ksu_handle_newfstat_ret` and
`ksu_handle_fstat64_ret`, so those call sites still resolve.

The call sites are guarded by `CONFIG_KSU`, deliberately **not** by
`CONFIG_KSU_MANUAL_HOOK`: `inline_hook_check.mk` warns about a
`CONFIG_KSU_MANUAL_HOOK` guard in these files, because in SUSFS-hook mode that
symbol is undefined and the hook would compile out while still passing the
grep.

## Version pinning

`local_version.mk` holds `KSU_LOCAL_VERSION`, `KSU_VERSION`, `KSU_TAG_NAME`,
`KSU_COMMIT_SHA` and `KSU_BRANCH_NAME`. When the vendored driver is updated,
bump all five together **and** update the pinned manager APK in the CI
workflow (`ReSukiSU_<tag>_<version>-universal-release.apk`) — a mismatch
between the two is exactly what makes a manager report an unsupported kernel.

## Sync history

- 2026-10-05: `backslashxx/KernelSU` `v3.3.0-60` → `Baka-SU/BakaSU`
  `v4.2.0-rc3`. Full driver replaced (`drivers/kernelsu/`, 102 files,
  multi-object build). Taken as upstream: everything except the four
  deviations above. Added by this integration: the three missing kernel-side
  hook sites (`kernel/sys.c`, `fs/read_write.c`, `drivers/input/input.c`),
  the SUSFS "no su" / "umounted for zygote next" flag helpers in
  `include/linux/susfs_def.h`, and the `no_su` gates at the sucompat call
  sites. The old driver's local SUSFS command block in
  `supercall/supercall.c` is gone: this driver implements SUSFS command
  dispatch itself (`supercall/dispatch.c` → `ksu_handle_susfs_cmd`).
