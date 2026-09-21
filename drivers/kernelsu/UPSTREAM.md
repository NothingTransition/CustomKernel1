# KernelSU upstream provenance

This directory vendors the kernel component from:

- Repository: https://github.com/backslashxx/KernelSU
- Tag: `v3.3.0-43`
- Commit: `8942a1504495aec974efb6b0dda4bd9e7d70fbf1`

It is integrated in-tree for the Linux 4.14 non-GKI Miatoll kernel. The
scope-minimized manual hooks are based on backslashxx/KernelSU issue #5,
manual-hooks revision v2.3. Kprobe, syscall-table tampering, and ARM64
branch-link hooks are intentionally disabled in the Miatoll defconfig.
