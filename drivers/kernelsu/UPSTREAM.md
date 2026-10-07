# KernelSU upstream provenance

This directory vendors the kernel component from:

- Repository: https://github.com/backslashxx/KernelSU
- Tag: `v3.3.0-60` (upstream kernel Makefile: 32657 - ABI unchanged)
- Commit: `436b7102bb5d6a6c7e6d6b1a3d3f8de0e2cbd6f6`
- Manager policy (Stormbreaker, by maintainer decision 2026-10-05): **only the
  backslashxx/KernelSU manager family is trusted.** The tree accepts the
  release managers (public dummy.keystore cert `0x363/4359c171…`, package
  locked to `me.weishu.kernelsu`) and self-built managers on the official
  KernelSU cert (`c371061b…`). The KernelSU-Next cert (`0x3e6/79e59011…`),
  the `ksu_manager_kind` bookkeeping, the two-manager crowning priority in
  `manager/throne_tracker.c` and the KSUN driver-version report in
  `supercall/dispatch.c` were removed; upstream -56 dropped its own
  KSUN support at the same time, and the KOWX712 fork cert upstream added
  (`0x375/484fcba6…`) is deliberately NOT accepted here.

## Sync history

- 2026-10-05: manual sync `v3.3.0-56` -> `v3.3.0-60` on the v93 lineage
  (KSU_VERSION stays 32657 - upstream did not bump the kernel ABI; release
  -56 was deleted upstream, so the old pin no longer resolves). Taken
  upstream wholesale: `INTERNAL.md`, `hook/lsm_hooks_ultralegacy.c`
  (`memcmp_inline`, no zero-init of the probe buffer), `manager/pkg_observer.c`
  (`strnstr`), `manager/apk_sign.c` (KOWX712 block trimmed again),
  `ksu.c` (module-blacklist include simplification on the module path),
  `Kconfig` (the kprobes-based hook option is now marked deprecated and
  depends on DEPRECATED, which this 4.14 tree does not define - the option
  stays unavailable, as intended). Kept local as always: the SUSFS-carrying
  files (`Kconfig` menu, `ksu.c` susfs_init, `hook/setuid_hook.c`,
  `selinux/selinux.c`, `supercall/supercall.c` SUSFS command block,
  `supercall/dispatch.c` atomic one-shot + module-mounted flag).
  Manager APK ships as the upstream v3.3.0-60 build, with the immutable
  -56 copy on `stormbreaker-v111` as the fallback.
- 2026-10-05: manual sync `v3.3.0-52` -> `v3.3.0-56` on the v93 lineage
  (KSU_VERSION 32651 -> 32657). Taken upstream wholesale (16 files):
  `Makefile`, `INTERNAL.md`, `downstream/module_blacklist.h`,
  `feature/adb_root.c`, `feature/kernel_umount.c`, `feature/selinux_hide.{c,h}`,
  `hook/lsm_hooks_list.c`, `hook/lsm_hooks_ultralegacy.c`,
  `hook/syscall_table_hook_arm.c`, `include/uapi/supercall.h` (UAPI 5,
  `EVENT_SERVICES`), `kernel_compat.h`, `kernel_includes.h`,
  `policy/allowlist.c`, `policy/app_profile.c`, `selinux/sepolicy.c`.
  Taken upstream + locally trimmed: `manager/apk_sign.c` (upstream's
  KOWX712 block removed - see the manager policy above),
  `manager/manager_identity.h`, `manager/throne_tracker.c` (upstream's
  single-manager crowning; our two-manager priority logic deleted).
  Locally adapted: `supercall/dispatch.c` - took upstream's `EVENT_SERVICES`
  handler (start/skip result, reset on the POST_FS_DATA path), removed the
  KSUN version report, kept our atomic `EVENT_POST_FS_DATA` one-shot and the
  SUSFS sdcard-monitor call. Kept local as always: the SUSFS-carrying files
  (`Kconfig` menu, `ksu.c` susfs_init, `hook/setuid_hook.c` susfs
  umount/looped-path work, `selinux/selinux.c`, `supercall/supercall.c`'s
  SUSFS command block, `supercall/dispatch.c` bits above). Upstream -56 still
  ships no SUSFS code.
- 2026-09-26: manual sync `v3.3.0-51` -> `v3.3.0-52` (release -51 was deleted
  upstream, so the old manager pin no longer resolves). Taken upstream:
  `include/util.h` (drops the <5.9 ksu_sys_umount inline — its live <5.9 user
  moved), `kernel_compat.h` (legacy kernel_read compat reorg, adds
  ksu_sign_extend64, keeps the lookup_user_key() session-keyring grab used on
  4.14), `feature/kernel_umount.c` (new <5.9 fallback: weak path_umount probe
  with set_fs/KERNEL_DS umount-syscall fallback — correct for 4.14),
  `INTERNAL.md`. Kept local: the SUSFS-carrying files (Kconfig menu, ksu.c
  susfs_init, setuid_hook.c susfs umount/looped-path work, supercall ABI,
  selinux glue, dispatch.c one-shots) — upstream -52 dropped SUSFS entirely,
  so nothing SUSFS-related was taken. KSU_VERSION stays 32651 (unchanged
  upstream too); manager pin and docs moved to v3.3.0-52 (APK still 32653).
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
