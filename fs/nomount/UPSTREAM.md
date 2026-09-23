# NoMount provenance

- Upstream: https://github.com/maxsteeel/nomount
- Release: `v2.0.0`
- Commit: `b8d268353b4e7ecc53c67d1816a626b7d6579201`
- Imported from: `kernel/src`
- Integration: built in with `CONFIG_NOMOUNT=y`

The upstream source is vendored rather than linked so kernel builds remain
reproducible and do not fetch or modify source during Kbuild.

## Local deviation from upstream v2.0.0: SRCU-correct freeing

Upstream frees `nm_iop`, `nm_fop` and `nomount_dir_node` objects via classic
`call_rcu()`, while all readers of those objects hold `nomount_srcu`
(`srcu_read_lock`). Classic RCU grace periods do not cover SRCU readers, so a
reader could still dereference an object after it is reclaimed (theoretical
use-after-free, openable only during rule clear-all / restore / shadow
replacement racing an active directory read).

All six free sites in this tree therefore use
`call_srcu(&nomount_srcu, ...)` instead, so reclamation waits for the same
grace-period domain the readers hold:

- `nm_destroy_virtual_inode()` (tagged virtual dir node)
- `nm_destroy_hijacked_inode()` (nm_iop, nm_fop, dir_node)
- `nomount_prune_empty_virtual_dirs()` (detached dir node)
- `__nomount_add_rule()` shadow path (replaced rule's dir node)

Callbacks are unchanged and remain non-sleeping (`kmem_cache_free`, `kfree`,
with the sleeping `iput()` already deferred to a workqueue), which is safe in
SRCU callback context. No behavioral change in normal operation.

## d_splice_alias error-path hardening (2026-09-23)

- Virtual-inode site 2 (lookup/readdir): d_splice_alias() already drops the
  new inode reference on its error paths in 4.14 (see fs/dcache.c), so no
  iput() was added; but the site no longer calls nomount_hijack_dentry_ops()
  on an ERR_PTR, and on NULL success it now hijacks the instantiated dentry,
  matching site 1 semantics.
