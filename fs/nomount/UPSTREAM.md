# NoMount provenance

- Upstream: https://github.com/maxsteeel/nomount
- Release: `v2.0.0`
- Commit: `b8d268353b4e7ecc53c67d1816a626b7d6579201`
- Imported from: `kernel/src`
- Integration: built in with `CONFIG_NOMOUNT=y`

The upstream source is vendored rather than linked so kernel builds remain
reproducible and do not fetch or modify source during Kbuild.
