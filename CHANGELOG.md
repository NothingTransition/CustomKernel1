# Stormbreaker — release changelog

Full feature documentation lives in RELEASE_NOTES.md (repo). This file is
what gets attached to each release: only what changed in that build.

## #126 — KernelSU driver replaced with BakaSU v4.2.0-rc3 (SUSFS inline hook); eBPF stream parser fixed; SUSFS hook sites corrected
• **The KernelSU driver is now BakaSU (formerly ReSukiSU) v4.2.0-rc3.** The backslashxx/KernelSU v3.3.0-60 unity-build driver is gone. `KSU_VERSION 35171` is what the driver reports, and the bundled manager — `BakaSU-manager.apk`, the `ReSukiSU_v4.2.0-rc3_35171` build — carries the same version code, so kernel and manager agree on the ABI
• **New hook method: SUSFS inline hook.** BakaSU's tracepoint hook is GKI 2.0 (5.10+) only, and its plain manual hook carries no SUSFS support, so the driver runs in `CONFIG_KSU_SUSFS` mode against this tree's SUSFS v2.3.0. That mode needs seven kernel-source hook sites; four were already present from the previous driver and keep identical signatures, three were added: `ksu_handle_setresuid` (`kernel/sys.c`), `ksu_handle_sys_read` (`fs/read_write.c`) and `ksu_handle_input_handle_event` (`drivers/input/input.c`). The driver's own `inline_hook_check.mk` fails the build if any of the seven is missing, so this cannot regress silently
• **SUSFS v2.3.0 kernel side completed for the new driver.** Added the flag helpers it calls — the "no su" marker (`TIF_PROC_NO_SU`), the zygote-next umount marker (`TIF_PROC_UMOUNTED_FOR_ZYGOTE_NEXT`) and `susfs_clear_current_proc_umounted` — with upstream v2.3.0's bit assignments, and made the `no_su` marker actually mean something: the execve / faccessat / stat sucompat call sites now skip processes the manager marked as never-root
• **Manager policy: unchanged in spirit.** The driver accepts the BakaSU/ReSukiSU certificate (`0x377`) and the official KernelSU one (`c371061b…`), and nothing else. The four fork certificates it knows about (5ec1cff, rsuntk, SukiSU-Ultra, KOWX712) stay behind `CONFIG_KSU_MULTI_MANAGER_SUPPORT`, which is **off**
• **Vendored, not a submodule.** Upstream's Kbuild hard-errors without git metadata and derives the version from git history; `drivers/kernelsu/local_version.mk` pins those five values instead, so a build needs no git repository and no network access during kbuild — the approach this tree already uses for SUSFS and NoMount
• **SUSFS and NoMount are untouched** and keep running side by side. `CONFIG_KSU_SUSFS` now additionally depends on `FUSE_FS`, which the SUSFS kernel side needs (`get_fuse_inode()`); CI asserts it
• **CI updated:** the config gate asserts the new hook-mode symbols (`KSU_SUSFS` selected, tracepoint/manual/multi-manager off), the linkage check proves `kernelsu_init_early` plus the three new hook symbols are in `vmlinux`, and the manager APK is pinned to `Baka-SU/BakaSU` `v4.2.0-rc3` with an immutable copy on our own release as fallback
• **Feature deltas vs the old driver:** BakaSU brings its metamodule system, dynamic manager, app profiles and per-app seccomp caching. The old tree's `CONFIG_KSU_HOSTSREDIRECT` (hosts-file syscall redirect) was already disabled in the defconfig and has no BakaSU equivalent, so nothing is lost there
• **Kprobe support details:** the old driver's kprobe/branch-link/syscall-table options no longer exist; the new driver's tracepoint path (which uses kretprobes) is compiled out in this mode, so the "no kprobes" property of this kernel is preserved
• **eBPF stream parser (sockmap/sk_msg) fixed and enabled.** Build #103 died in `net/core/skmsg.c` on an undeclared `prot` left over from the 5.x version of the file, and the option was disabled again instead of fixed. The line was the backport's only capture of `saved_destroy`, so the real fix is where the rest of this tree's older backport captures its callbacks: `sk_psock_update_proto()` now saves `orig->destroy` next to `saved_unhash` / `saved_close` / `saved_write_space`, and the stray line is gone. `CONFIG_BPF_STREAM_PARSER=y` (selecting `STREAM_PARSER` + `NET_SOCK_MSG`) builds `skmsg.o`, `sock_map.o` and `tcp_bpf.o`, CI asserts all three objects plus `sk_psock_init` / `sock_map_close` / `sock_map_destroy` / `sk_msg_alloc` / `tcp_bpf_recvmsg` / `strp_init` in `vmlinux`, and `BPF_MAP_TYPE_SOCKMAP` is available again — the last missing piece of the "feature-equivalent to 5.4" eBPF requirement for Android 16/17
• **SUSFS inline-hook call sites corrected.** BakaSU's SUSFS mode takes `struct filename **` at `faccessat` and `stat` — it rewrites the filename in place (`/system/bin/su` → `/system/bin/sh`) and the caller's lookup then resolves the rewritten name. The tree still called those hooks with the *manual-hook* ABI (a raw `const char __user *`), which compiles but makes the driver dereference a user pointer as a `struct filename`, so su-path hiding could not work and was unsafe when su-compat was enabled. Both sites now build the filename with `getname_flags()` before the lookup, gate on the driver's `ksu_su_compat_enabled` static key and `__ksu_is_allow_uid_for_current()`, keep the "no su" marker check, and hand the pointer to `filename_lookup()` (which consumes it), matching the SUSFS kernel-side reference patch. `execveat`, `setresuid`, `sys_read`, `reboot` and the input hook already matched their driver prototypes. The two remaining stat entry points (`newfstatat`, `fstatat64`) carried the same manual-hook call; in SUSFS mode they now leave it to `vfs_statx()`, which every stat-family syscall on this kernel funnels through (`vfs_stat` / `vfs_lstat` / `vfs_fstatat` are inlines over it), so `stat`, `lstat`, `fstatat`, `stat64`, `lstat64`, `fstatat64` and `statx` are all covered by one hook instead of being hooked twice. This is what build #122 caught: the two merged sites would not even compile against the SUSFS-mode prototype. Build #123 then reached the linker and caught the last piece of the same puzzle: `ksu_handle_newfstat_ret()` / `ksu_handle_fstat64_ret()` (the init.rc size fixups on the `fstat` / `fstat64` return buffers) exist only in the driver's *manual-hook* mode, so SUSFS mode has to use the driver's SUSFS-mode equivalent instead — and that one was never wired. `vfs_statx_fd()` now calls `ksu_handle_vfs_fstat()` on success, which is where every `fstat`-family syscall lands, so the injected rc length is reported again exactly as it was with the old driver

## #119 — KernelSU driver updated to v3.3.0-60; BBRplus is the default congestion control
• **KernelSU driver synced `v3.3.0-56` → `v3.3.0-60`**: `INTERNAL.md`, `hook/lsm_hooks_ultralegacy.c` (`memcmp_inline`, no zero-init probe buffer), `manager/pkg_observer.c` (`strnstr`), `ksu.c` (module-blacklist include simplification on the module path) and `Kconfig` (the kprobes-based hook option is now deprecated-gated). Kernel ABI unchanged (`KSU_VERSION 32657`), so the manager still matches
• **Manager APK: upstream v3.3.0-60 build**, with the immutable -56 copy on our own `stormbreaker-v111` release as the fallback — upstream deleted the -56 tag mid-build last run, so the build no longer depends on any single upstream tag
• The SUSFS v2.3.0 integration stays local as always; the KernelSU-Next/KOWX712 fork certificate is trimmed again
• **BBRplus is now the system default congestion control** (`CONFIG_DEFAULT_TCP_CONG="bbrplus"`): Google's BBR v1 with BBR v2 backports — ACK-aggregation tracking (`bbr_extra_acked`, 10-round-trip window, 100 ms cap) plus a variable PROBE_BW gain-cycle length with randomized phase start. The ACK fix is what matters on mobile data: when GRO/delayed ACKs compress the ACK stream, plain BBR v1 underestimates the delivery rate and under-paces
• **Plain BBR v1 stays built in** and is one sysctl away: `echo bbr > /proc/sys/net/ipv4/tcp_congestion_control`. CUBIC, Vegas, Westwood+, BIC and HTCP are selectable too
• 4.14 adaptations behind BBRplus: `tcp_snd_wnd_test()` un-static'd, `tcp_tso_autosize()` computed inline, `.min_tso_segs` instead of the 5.x `.tso_segs_goal` ops field, `ICSK_CA_PRIV_SIZE` widened 88 → 112 bytes (same change the ApexKernel tree carries; +24 bytes per TCP socket)
• CI gate now requires `CONFIG_TCP_CONG_BBR=y`, `CONFIG_TCP_CONG_BBRPLUS=y` and `DEFAULT_TCP_CONG="bbrplus"`

## #111 — back to the v93 lineage: backslashxx driver v3.3.0-56, one manager only
• **Base is the original v93 tree again** (run #93, commit `d62bca985`): MGLRU compiled in, the Droidspaces container/namespace fragment (SYSVIPC, mqueue, PID/USER namespaces, cgroup device/pids/net_prio, nftables, bridge netfilter, xt addrtype) compiled in, BFQ default I/O scheduler, stock VM sysctls (no RAM-tier tuning), stock TCP sysctls with BBR still the default congestion control and fq_codel built in but not the default. The #96–#110 tuning lineage is withdrawn
• **KernelSU driver synced v3.3.0-52 → v3.3.0-56** (`KSU_VERSION 32657`, upstream commit `1f47db46`): upstream v3.3.0-56 taken wholesale (16 files) plus the new `EVENT_SERVICES` supercall (services start/skip handling). The SUSFS v2.3.0 integration and the manager-certificate entry stay local, as always
• **KernelSU-Next manager support removed** — the kernel now trusts only the backslashxx/KernelSU manager family: release managers (dummy.keystore cert, package-locked to `me.weishu.kernelsu`) and self-built managers on the official KernelSU cert. KSUN's certificate, the two-manager crowning priority and its driver-version report are gone. The release ships one manager APK: **KernelSU v3.3.0-56**
• **CI gate moved to the v93 lineage** — the config gate now requires MGLRU / the container set / BFQ and keeps rejecting kprobes and the BPF stream parser; the linkage check asserts MGLRU and the namespaces are actually in the image instead of asserting they are gone
• **v105–v110 withdrawn and deleted** — releases `v105`, `v108`, `v109`, `v110` removed from the releases page (superseded lineage). `stormbreaker-v93` stays as the restored original; this build is the default going forward

## #110 — repo housekeeping rebuild (no kernel change)
• Nothing in the kernel changed — this is the #109 tree rebuilt to prove the pipeline still runs green after the cleanup, so the release metadata here can be trusted. Kernel zip is equivalent to #109
• Releases page pruned from 21 releases (818 MB) to the ones that matter: this build (latest), #109, **v108 (known-good — the v105 tree, boots Infinity X 4.0)** and the `diag-1` pre-release (parked boot-stall bisect). Superseded iteration builds v78–v107 are gone
• README now documents the release streams (stable / diagnostic / known-good), the build pipeline and the license; the diagnostics workflow is manual-only while the bisect is parked (see `diag/README.md`)
• Boot status unchanged: **on Infinity X 4.0 flash v108** — that ROM currently only boots the Imperial-X kernel. The stack is field-tested working on Evolution X A17

## #109 — stall/jitter pass: reserve moved to a knob the ROM cannot erase, CFQ default, MGLRU + Droidspaces out
• **The stutter fix is now in the one knob the ROM does not overwrite.** The ROM's own `init.qcom.post_boot-atoll.sh` sets `vm.watermark_scale_factor=1` ("we are using efk") and runs **twice** — from `on init` and again when `sys.boot_completed=1` re-triggers it — so every reserve this kernel set as a scale factor was erased after boot. The Qualcomm knob that script assumes is in play, `vm.extra_free_kbytes`, is never written by any ROM script, so the RAM-tier reserve now lives there: **~38 MB (4 GB) / ~42 MB (6 GB) / ~40 MB (8 GB)**, added to the LOW/HIGH watermarks so kswapd keeps the headroom and allocation bursts stop falling into *direct* reclaim. `watermark_scale_factor` is set to 1 to match the ROM, so the two stop fighting over one value. Both remain ordinary sysctls
• Same ~40 MB anti-direct-reclaim target as before — only the delivery mechanism changed, because the old one was being wiped twice per boot
• **CFQ is the default I/O scheduler again** (BFQ stays compiled in and selectable per disk). The ROM tunes CFQ-family blkio knobs (`/sys/block/sda/queue/iosched/group_idle`, `/dev/blkio/blkio.group_idle`) that BFQ does not expose, CFQ is what the known-good Imperial-X build runs, and its per-request overhead is lower on this SoC — which shows up exactly where it is felt, during a boot/dexopt/install IO storm on 4 GB
• **MGLRU is compiled out** (`# CONFIG_LRU_GEN is not set`). It was only ever inert — `LRU_GEN_ENABLED` was off, so the ~2.8k-line backport never executed a single instruction. The source stays in `mm/` for a future retry; CI now asserts it stays out of both the resolved .config and the linked image
• **Droidspaces container support is compiled out** (SYSVIPC, POSIX mqueue, PID/USER namespaces, cgroup device/pids/net_prio, nftables, bridge netfilter, xt addrtype). Nothing in Android uses them, and Imperial-X r8.0 boots this exact ROM with every one of those off. Untouched on purpose: iptables/netfilter core, VETH/BRIDGE, UTS/NET namespaces, MEMCG, seccomp, DEVTMPFS
• Boot side: fewer built-in initcalls (nftables, conntrack helpers, mqueue), a smaller image, CFQ for the IO-heavy part of boot, and no direct-reclaim stalls during the boot-time memory crunch. Realistic expectation: most of a 4 GB cold boot is ROM userspace (ART, app scan, zram), and 10-15 s on 8 GB vs 30-50 s on 4 GB is the small-RAM delta, not a bug
• CI updated: the old "MGLRU must be linked in" checks are inverted (they now prove it is gone), the container symbols must resolve to `not set`, and CFQ is hard-required
• If this build does not boot on your ROM: reflash **v108** — the known-good v105 tree, still downloadable

## #108 — rollback to the v105 tree (boots on Infinity X 4.0)
• #106/#107 removed MGLRU, BBR, fq_codel, net_tune, the container fragment and DEVTMPFS all at once; the result hung at the boot logo on Infinity X 4.0. This build reverts all three commits — byte-for-byte the v105 tree that boots
• Nothing was diagnosed or fixed in #108: it is a pure rollback to get a booting phone first, then re-apply the safe parts one at a time (#109 is the first of those)
• Release notes and CI guards for MGLRU/ram_tune/net_tune came back with the tree

## #105 — network tuning: fq_codel default qdisc + TCP defaults for cellular
• BBR was already the default congestion control here; the missing half was the queue. The default qdisc was `pfifo_fast`, which just fills up — upload anything and RTT balloons, so the connection *feels* slow even at a good Speedtest number. `fq_codel` is now the default qdisc (`CONFIG_NET_SCH_DEFAULT=y` + `CONFIG_DEFAULT_FQ_CODEL=y`, applied by the kernel's own `sch_default_qdisc()` at boot), so the queue is actually managed and one flow cannot starve the rest
• New `net/net_tune.c` (late_initcall, same pattern as `mm/ram_tune.c`) sets two TCP defaults: `tcp_slow_start_after_idle=0` — the congestion window is no longer reset after an idle period, so a resumed transfer does not start over from scratch — and `tcp_mtu_probing=1`, which survives carriers that drop ICMP "fragmentation needed" and otherwise hang on large packets. Both stay normal sysctls, so ROM init scripts and root can override them at runtime
• Deliberately NOT done: raising `tcp_rmem`/`tcp_wmem`. Auto-tuning already sizes the windows for fast links and big static buffers only add queuing delay and pin memory. This is a smoothness/latency change, not a Speedtest-number change — the radio sets peak throughput, not the kernel
• CI hard-requires the four network symbols and checks that `net_tune_init` is linked into vmlinux, in the same way `ram_tune_init` is
• WiFi is unchanged in the kernel on purpose: the knobs that matter live in the ROM's `WCNSS_qcom_cfg.ini` and are read by the driver at load. RELEASE_NOTES documents the exact file and the keys this driver parses, plus the battery-vs-latency trade-offs

## #104 — fix the #103 build failure: keep BPF LSM, defer the stream parser
• Build #103 failed in `net/core/skmsg.c:493` — `use of undeclared identifier 'prot'`. The sockmap/sk_msg half of this tree's eBPF backport is **incomplete**; it had simply never been compiled because `CONFIG_BPF_STREAM_PARSER` was always off, so nothing caught it until now
• `BPF_STREAM_PARSER` is off again — this time on purpose, with the exact error recorded in the defconfig and a CI rule that hard-requires it to stay off (`# CONFIG_BPF_STREAM_PARSER is not set`) so a later edit cannot silently bring the broken file back. It selects `NET_SOCK_MSG`; that has only two other selectors (TLS, and BPF_STREAM_PARSER itself), both off, so neither `skmsg.o` nor `sock_map.o` is built
• **BPF LSM stays on.** Before trusting it, every object it newly pulls in was audited against this tree: `lsm_prog_ops`, `lsm_verifier_ops` and `inode_storage_map_ops` are defined; `btf_id_set_contains`/`btf_ctx_access` are not gated behind `CONFIG_DEBUG_INFO_BTF` in this tree; `tracing_prog_func_proto` is compiled (`CONFIG_BPF_EVENTS=y`); `security_add_hooks` is the 3-arg form, and `DEFINE_LSM`/`lsm_blob_sizes` exist. All the dependencies `bpf_lsm.c`, `bpf_inode_storage.c` and `security/bpf/hooks.c` link against resolve
• README/RELEASE_NOTES corrected: they claimed sockmap/stream parser support, which was never true in a shipped build; it is now listed as a stated gap in the A16/A17 audit
• Nothing else changes: same RAM-tier tuning, same KernelSU/SUSFS/NoMount stack, same A17 userspace configuration

## #102 — fix config symbols that a duplicate line was silently disabling
• Two defconfig entries appeared twice — once as `=y`, then again later as `# ... is not set`. kconfig applies lines in order and the **last one wins**, so both were actually OFF: `CONFIG_NETFILTER_XT_TARGET_TRACE` (so `iptables -j TRACE` was missing despite the release notes claiming A15 parity) and `CONFIG_EXT4_ENCRYPTION`
• EXT4_ENCRYPTION turned out harmless — it is deprecated and only exists to select FS_ENCRYPTION, which was set directly, so ext4 FBE always worked. The TRACE target was genuinely absent and is now really enabled
• Also enabled BPF LSM / stream parser / SELinux bootparam in their proper alphabetical slots instead of appending them at the end of the file (same duplicate trap, this time caught by my own review before it shipped)
• CI now runs a duplicate-symbol check on the defconfig and refuses to build if any symbol appears more than once — this class of bug (a silent "is not set" defeating an intended "=y") has now bitten three times, so it is enforced from here on
• CI also hard-requires the two symbols above, so their state is verified against the generated .config instead of assumed

## #101 — Android 17 compatibility pass: eBPF LSM + stream parser enabled
• Audited what A16/A17 actually demand from a non-GKI 4.14 kernel: the practical gate is the newer eBPF feature set (Google supports 5.10+; LineageOS requires "1:1 eBPF backports, feature equivalent to Linux 5.4")
• This tree already carries the full ACK eBPF backport (ring buffer, in-kernel BTF, iterators, trampolines, local storage, struct_ops) — a superset of 5.4. Two pieces were in the tree but switched off and are now compiled in: BPF LSM (CONFIG_LSM already listed `bpf`, so that entry was dead) and the BPF stream parser (sockmap/sk_msg)
• SELinux bootparam re-enabled so `androidboot.selinux=permissive/disabled` works for ROM bring-up — AOSP's own kernels ship it on
• CI now hard-requires the Android-userspace critical config set (eBPF, PSI, binder devices, FBE/verity, quotas, incremental FS, WALT, namespaces, seccomp) and verifies bpf_lsm_init is linked in, so A17 compatibility can't silently regress
• RELEASE_NOTES documents the whole A17 picture, including the honest gaps: uclamp is absent from this tree entirely (ROMs use Qualcomm WALT/SCHED_TUNE instead), DEBUG_INFO_BTF is off (opt-in), 16 KB pages don't apply to this SoC

## #100 — document MGLRU, and prove the memory tuning ships
• Added Documentation/vm/multigen_lru.rst — the MGLRU backport had no documentation at all, even though the kernel config help points at that file (so the pointer was dangling). Covers what it is, the config options, the runtime toggle, the `spread` knob and how it interacts with the rest of the VM
• CI now checks that the RAM-tier tuning initcall (`ram_tune_init`) is actually linked into the kernel image, the same way MGLRU and KernelSU already were — so the #99 tuning can't silently disappear from a future build
• No functional kernel change in this build

## #99 — memory tuned to the installed RAM (4/6/8 GB)
• The kernel now measures installed RAM at boot and applies the matching memory profile — one zip, three tiers, so a 4 GB phone and an 8 GB phone stop sharing one compromise
• kswapd reserve (the anti-stutter knob) raised: ~40 MB on every tier instead of ~7 MB on 4 GB — allocations now drain in the background instead of falling into direct reclaim
• Page-at-a-time swapin: swap page-cluster 3 → 0 for all tiers (zram is random access, swap readahead there was pure waste)
• swappiness 60 → 100 on all tiers — these devices swap to zram, not to disk, so anon pages are cheap to reclaim
• 4 GB: vfs_cache_pressure 150, dirty limits 10%/5% • 6 GB: 125, 15%/5% • 8 GB: kernel defaults kept
• MGLRU's aging rate is now set per tier too (0/1/2), so if you turn MGLRU on it is already tuned for your RAM
• Every value is still an ordinary sysctl (`/proc/sys/vm/...`) — ROM init scripts or root can override any of it
• Note: MGLRU is still OFF by default, unchanged (see RELEASE_NOTES.md)

## #98 — MGLRU restored (+ the build fix that was hiding behind it)
• Multigenerational LRU is back in the build — the port was sitting in mm/ all along, but the defconfig lines had been dropped as "dead", so MGLRU had silently disappeared from recent kernels
• Fixed a link failure from the previous memory pass: turning on ZSMALLOC_STAT force-selects DEBUG_FS (it is a debugfs feature), which pulled in a debugfs-only msm_bus file whose tracepoints were never instantiated — `undefined symbol: __tracepoint_bus_update_request`. ZSMALLOC_STAT is off again (kernel stays a non-debugfs build) and the missing tracepoint instantiation is fixed at the source
• CI now hard-requires the MGLRU options and verifies the lru_gen_* symbols are linked into the kernel image, so MGLRU can't go missing silently again
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
