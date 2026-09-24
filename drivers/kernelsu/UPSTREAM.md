# KernelSU upstream provenance

This directory vendors the kernel component from:

- Repository: https://github.com/backslashxx/KernelSU
- Tag: `v3.3.0-51` (upstream kernel Makefile: 32651)
- Commit: `d7e36bd05323224c88f105836ae6478b7ee07db9`
- Note: at this tag upstream's manager APK reports 32653 while the kernel
  tree reports 32651 (upstream's own skew); we mirror the kernel value
  (32651) verbatim. A same-day 32653 alignment experiment was reverted on
  2026-09-24; future syncs keep mirroring the upstream kernel value.

## Sync history

- 2026-09-24: KSU_VERSION reverted to 32651 (upstream kernel value) after a
  same-day 32653 alignment experiment — maintainer decision to mirror
  upstream verbatim again. Release flipped from pre-release to stable and
  the UNTESTED marker removed from zip name and flash banner. Docs refresh
  kept: fs/SUSFS_UPSTREAM.md rewritten to the v2.3.0 port (it had described
  the pre-upgrade v1.5.5 import and wrongly claimed BRENE incompatibility).
- 2026-09-24: manual sync `v3.3.0-48` -> `v3.3.0-51`. Taken upstream:
  `Makefile` (32649 -> 32651), `include/arch.h` (symbol table rework; only
  consumed by kprobe code that is not compiled in this tree -- CONFIG_KPROBES
  is off and kp_ksud.c is not referenced by any Makefile), `hook/kp_ksud.c`
  (PT_REGS_SYSCALL_PARM1 fixes, same dead-code status), `hook/lsm_hooks_list.c`
  (#if 0 demo + comment), `kernel_includes.h` (+linux/key.h), `include/util.h`
  (riscv branch, PT_REGS_SYSCALL_PARM1 in dead >=4.19 path, ksu_sys_umount
  int->long), `kernel_compat.h` (ksu_sys_umount long + cast on the live <5.9
  path, <3.11 iterate_dir wrapper dead here, session-keyring grab reworked
  onto lookup_user_key() which exists on 4.14). Kept local: the usual six
  SUSFS-carrying files (dispatch.c keeps our atomic one-shot + sdcard monitor).
- 2026-09-23: manual sync `v3.3.0-43` -> `v3.3.0-48` (16 files reviewed).
  Taken upstream wholesale: `Makefile` (version), `INTERNAL.md`,
  `feature/selinux_hide.h` (cpu type + printk fmt), `hook/lsm_hooks_list.c`
  (error codes + ksym verification; LKM-only bruteforce path is compile-
  guarded and inactive in our built-in build), `kernel_compat.h` and
  `include/util.h` (reworked ksyscall machinery and <4.14 compat layer --
  both dead code on this 4.14.357 tree, live <5.9 paths unchanged in
  behavior), `selinux/rules.c` (>=5.10 RCU-deref fix, dead code here),
  whitespace-only `kernel_includes.h`, `feature/kernel_umount.c`,
  `manager/throne_tracker.c`. Kept local: `ksu.c`, `hook/setuid_hook.c`,
  `selinux/selinux.c`, `supercall/supercall.c`, `supercall/dispatch.c`,
  `Kconfig` -- these carry the SUSFS v2.3.0 integration blocks.
  Note: upstream deleted the `v3.3.0-43` and `v3.3.0-47` tags, so the sync
  was diffed directly against `v3.3.0-48`.

It is integrated in-tree for the Linux 4.14 non-GKI Miatoll kernel. The
scope-minimized manual hooks are based on backslashxx/KernelSU issue #5,
manual-hooks revision v2.3. Kprobe, syscall-table tampering, and ARM64
branch-link hooks are intentionally disabled in the Miatoll defconfig.

## SUSFS v2.3.0 (non-GKI 4.14 semantic port)

- SUSFS_VERSION: v2.3.0 (was v2.2.0)
- Upstream kernel changes by simonpunk/sidex15, Sep 12-13 2026, version-bump
  commit `a64889c` ("fs: susfs: bump version to v2.3.0"); GKI branches of
  https://gitlab.com/simonpunk/susfs4ksu track this series.
- 4.14 semantic-port reference: https://github.com/star-star-dev/M62-backport
  pull request #3 (merged 2026-09-22), itself built from the same upstream
  commit series. Symbols unavailable on 4.14 (STATX_MNT_ID, zygote_next
  hooks, kstat.mnt_id) are omitted as no-ops, matching that reference.
- Local adaptations on top of the reference:
  - `susfs_get_non_sus_vfsmnt_from_vfsmnt()` may return NULL in this tree
    (audit-hardened reference contract); `susfs_mark_inode_sus_kstat()` and
    `vfs_statfs()` keep NULL-safe fallbacks instead of dereferencing.
  - fdinfo/maps spoofing keeps this lineage's direct inode-metadata design
    (susfs_show_map_vma_spoofer) with the new v2.3.0 app-uid gating.
  - `get_anon_bdev()` KSU minor-dev hook adapted to the 4.14 ida API
    (ida_pre_get/ida_get_new_above).

## Audit hardening batch (2026-09-23)

- fs/statfs.c: ported upstream susfs fix 769e31fbe ("SUS_KSTAT: Fix wrong
  spoofing logic in vfs_statfs()") — the KSTAT path now returns the spoofed
  kstatfs as-is (f_flags no longer recalculated from the real mount); the
  SUS_MOUNT same-mount path recalculates f_flags from the caller's mount;
  the now-unused bypass_orig_flow label in vfs_statfs was removed.
- include/linux/susfs_def.h: SUSFS_IS_INODE_* macro arguments parenthesized.
- supercall/dispatch.c: EVENT_POST_FS_DATA one-shot guard converted from a
  non-atomic bool to atomic_cmpxchg (side effects must run exactly once).
- Kconfig: KSU_SUSFS now depends on FUSE_FS (fs/susfs.c includes
  fuse/fuse_i.h and links get_fuse_inode(), which needs built-in FUSE).
