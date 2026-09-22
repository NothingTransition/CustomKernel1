# KernelSU upstream provenance

This directory vendors the kernel component from:

- Repository: https://github.com/backslashxx/KernelSU
- Tag: `v3.3.0-43`
- Commit: `8942a1504495aec974efb6b0dda4bd9e7d70fbf1`

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
