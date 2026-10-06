# Stormbreaker — BPF requirement audit + BakaSU/SUSFS/NoMount wiring audit

Repo `NothingTransition/CustomKernel1`, 4.14.357-openela base for miatoll (Redmi Note 9 Pro family).
Audited at build #129. Everything below was read out of this tree; the CI assertions named are what
keeps each claim from silently regressing.

## 0. Verdicts

| subsystem | verdict | notes |
|---|---|---|
| **BakaSU driver v4.2.0-rc3** | ✅ wired correctly | vendored, builtin (`CONFIG_KSU=y`), SUSFS inline-hook mode, all 7 kernel hook sites match the driver prototypes, manager pinned to the matching APK (35171) |
| **SUSFS v2.3.0** | ✅ wired correctly | 9/9 feature options on, hooks live in 15 kernel files, `susfs_init()` called from the driver init, defect class found + fixed in #122–#125 (§2.4) |
| **NoMount (kernel + module)** | ✅ wired correctly | self-contained VFS subsystem, no KernelSU coupling by design, key type registered at `fs_initcall`, protocol v20, `CONFIG_NOMOUNT=y` + `CONFIG_KEYS=y` |
| **eBPF on this 4.14 kernel** | ✅ platform requirements complete | Android's mandated configs 100 % on; ABI exactly upstream v5.10 (29 maps / 31 progs / 156 helpers); arm64 JIT `BPF_JMP32` hole found + fixed (#128); BPF userspace now told a release it can use (#129). Arch-level gaps (trampolines, `text_poke`, BTF, `BPF_PROBE_MEM`) documented in §4.4 |

---

## 1. BakaSU driver

**Identity / pinning** (`drivers/kernelsu/local_version.mk`)

| value | |
|---|---|
| upstream | `Baka-SU/BakaSU` tag `v4.2.0-rc3` |
| commit | `239e1e8871b8fcd51a6e5b3002e0ba522fdd99fb` |
| KSU_VERSION | `35171` (= 30000 + 4471 + 700, the value upstream's Kbuild computes) |
| manager APK | `BakaSU-manager.apk` = `ReSukiSU_v4.2.0-rc3_35171-universal-release.apk` — same version code the kernel reports |

**Built in, not a module:** `drivers/Makefile:195 obj-$(CONFIG_KSU) += kernelsu/`, defconfig `CONFIG_KSU=y`.
Mode: `CONFIG_KSU_SUSFS=y` (SUSFS inline hook); `KSU_TRACEPOINT_HOOK` and `KSU_MANUAL_HOOK` are off (the
tracepoint hook is GKI 2.0 / 5.10+ only, the plain manual hook carries no SUSFS support).
Tree-specific Kconfig addition: `KSU_SUSFS depends on FUSE_FS` (the SUSFS kernel side calls
`get_fuse_inode()`), defconfig `CONFIG_FUSE_FS=y`.

**The seven hook sites** (checked in the *kernel* source; prototypes must match the driver's SUSFS-mode
declarations, and the driver's own `inline_hook_check.mk` fails the build otherwise):

| hook | call site | prototype handed to the driver |
|---|---|---|
| `ksu_handle_execveat` | `fs/exec.c:1894-1901` | `(int *, struct filename **, void *, void *, unsigned int *)` |
| `ksu_handle_setresuid` | `kernel/sys.c:607-611` | `(uid_t, uid_t, uid_t)` |
| `ksu_handle_sys_read` | `fs/read_write.c:577-579` | `(unsigned int, char __user **, size_t *)` |
| `ksu_handle_input_handle_event` | `drivers/input/input.c:382-393` | `(void, unsigned int *, unsigned int *, int *)` |
| `ksu_handle_faccessat` | `fs/open.c:453` | `(int *, struct filename **, int *, int *)` — **SUSFS form**; legacy form at `:385` inside `#ifndef CONFIG_KSU_SUSFS` |
| `ksu_handle_stat` | `fs/stat.c:293` | `(int *, struct filename **, int *)` — **SUSFS form**; legacy form at `:487` inside `#ifndef CONFIG_KSU_SUSFS` |
| `ksu_handle_sys_reboot` | `kernel/reboot.c:288-291` | `(int, int, unsigned int, void __user **)` |

Plus the SUSFS-mode-only init.rc fixup with no manual-hook equivalent: `fs/stat.c:191` declares and
`:218` calls `ksu_handle_vfs_fstat(fd, &stat->size)` inside `vfs_statx_fd()` — the funnel for every
`fstat`-family syscall — so the injected rc size is reported again (the build #123 defect).

**Dispatch path:** manager → `ksu_handle_sys_reboot` → `supercall/dispatch.c` → `ksu_handle_susfs_cmd()`
(`:995`) → `susfs_cmd()` → `susfs_add_sus_path()` / `susfs_add_sus_path_loop()` /
`susfs_start_sdcard_monitor_fn()` … All 15 `CMD_SUSFS_*` are routed. 8 legacy `sus_su`-era commands are
intentionally unrouted by BakaSU's design (fork-ABI decision, not a wiring defect).

**Manager trust:** BakaSU/ReSukiSU cert `0x377` + official KernelSU cert; the four fork certs stay behind
`CONFIG_KSU_MULTI_MANAGER_SUPPORT` (off). **CI proves:** `kernelsu_init`, `ksu_handle_susfs_cmd`,
`susfs_get_enabled_features`, `ksu_su_compat_enabled` are linked into `out/vmlinux`.

---

## 2. SUSFS v2.3.0

`include/linux/susfs.h` → `#define SUSFS_VERSION "v2.3.0"`; implementation `fs/susfs.c`; shared defines
`include/linux/susfs_def.h`; built by `fs/Makefile:17 obj-$(CONFIG_KSU_SUSFS) += susfs.o`. At boot,
`susfs_init()` (called from the driver's `core/init.c:121`) logs `susfs is initialized! version: v2.3.0`
and starts the sdcard-monitor workqueue.

**Feature options — 9/9 on** (CI asserts every one): `KSU_SUSFS` (mode), `SUS_PATH`, `SUS_MOUNT`,
`SUS_KSTAT`, `SUS_MAP`, `SPOOF_UNAME`, `SPOOF_CMDLINE_OR_BOOTCONFIG`, `OPEN_REDIRECT`,
`HIDE_KSU_SUSFS_SYMBOLS`, `ENABLE_LOG`.

**Kernel-side hook inventory** — SUSFS is *not* only a driver feature. Files carrying hooks:
`fs/namei.c` (`sus_path` ×8, `open_redirect` readlink ×3), `fs/namespace.c` (`sus_mount`, mount-id
spoofing, ksu-domain checks), `fs/open.c` (`faccessat`, `do_sys_openat` redirect), `fs/exec.c` (`no_su`
marker), `fs/stat.c` + `fs/statfs.c` (`sus_kstat`), `fs/readdir.c` (getdents hiding), `fs/super.c` +
`fs/proc_namespace.c` (mount listing), `fs/proc/{base,fd,cmdline,task_mmu}.c` (`open_redirect`, cmdline
spoof, VMA/map spoof), `fs/notify/fdinfo.c` (fdinfo leakage), `kernel/sys.c` (setresuid hook feeding the
markers), plus `include/linux/susfs{,_def}.h`. Driver-side glue: `hook/setuid_hook.c`,
`feature/kernel_umount.c`, `feature/sucompat.c`, `supercall/dispatch.c`, `selinux/selinux.c`.

**2.4 Defects found and fixed in this cycle** (shipped in the v127/v128 line):
1. **#122** — two extra `ksu_handle_stat` sites (`newfstatat`, `fstatat64`) still used the manual-hook ABI
   → would not compile against the SUSFS prototype; also an undeclared `filename_lookup`.
2. **#123** — `ksu_handle_newfstat_ret` / `ksu_handle_fstat64_ret` are manual-hook-only symbols →
   **the SUSFS-mode equivalent `ksu_handle_vfs_fstat()` was never wired**; now called from `vfs_statx_fd()`
   (without it, init.rc's injected rc length was reported wrong).
3. **#124** — that extern was declared after its use.
4. `faccessat`/`stat` SUSFS call sites rebuilt to the real `struct filename **` ABI (`getname_flags()` +
   `filename_lookup()`), gated on `ksu_su_compat_enabled` and the `no_su` marker.

**Runtime caveat (not CI-provable):** on-device checks are `dmesg | grep susfs` (init line + version) and
the manager's SUSFS feature page.

---

## 3. NoMount

Deliberately **not** wired into KernelSU — a standalone VFS path-redirection subsystem driven by the
`nomount` key type; the only "integration" that exists is config + initcall.

| item | evidence |
|---|---|
| sources | `fs/nomount/nomount.c` (1697 lines) + `fs/nomount/nomount.h` (332) |
| built in | `fs/Kconfig:318`, `fs/Makefile:18 obj-$(CONFIG_NOMOUNT) += nomount/`, `CONFIG_NOMOUNT=y` |
| init | `fs_initcall(nomount_init)` — registers the key type before userspace, allocates 4 slab caches; `nomount_exit` unregisters |
| key-type ABI | userspace adds a `nomount` key whose 8-byte (or 4-byte) payload is a **user pointer**; `nm_key_instantiate()` requires `CAP_SYS_ADMIN`, `get_user_pages_fast()` + `kmap()` to read `struct nm_payload`, verifies magic `0x4E4F4D4F554E54` ("NOMOUNT"), runs the command, writes the result back, and returns `-ECANCELED` so no key is retained |
| protocol | `NOMOUNT_VERSION "20"`; `NM_CMD_GET_VERSION` reports it to the module; other commands add/clear rules and UIDs, `GET_UIDS` |
| dependencies | `CONFIG_KEYS=y`, `CONFIG_KEYS_COMPAT=y` — nothing else; no KSU symbols referenced (tree-wide grep: outside `fs/nomount/` only the Kconfig/Makefile lines mention it) |
| userspace | `NoMount-v2.0.0.zip` (maxsteeel/nomount), shipped with the release |
| CI | asserts `out/fs/nomount/nomount.o` exists **and** `nomount_init` is linked into `vmlinux` |

By design and worth knowing: (a) NoMount is unrelated to SUSFS `sus_mount` (mount-id spoofing) — they
coexist and do different jobs; (b) failures surface as a `keyctl` error plus `NoMount: [ERROR]` in dmesg,
so they are easy to tell apart from KernelSU/SUSFS problems on the device.

---

## 4. eBPF on this 4.14 kernel

### 4.1 What it strictly takes to run eBPF at all

| requirement | why mandatory | this tree |
|---|---|---|
| `CONFIG_BPF=y` + `CONFIG_BPF_SYSCALL=y` | the `bpf(2)` syscall, maps, program load | ✅ y / y |
| `CONFIG_HAVE_EBPF_JIT` (arch) + `CONFIG_BPF_JIT=y` | native compilation; arm64 has had an eBPF JIT since 4.4, 32-bit ARM only **from 4.14** (`39c13c204bb1`) | ✅ arch selects it, JIT y |
| `CONFIG_BPF_JIT_ALWAYS_ON=y` | Android hardening; **side effect that matters:** `bpf_prog_select_runtime()` then returns `-ENOTSUPP` instead of falling back to the interpreter, so *any instruction the arch JIT cannot encode makes the program unloadable* | ✅ y |
| `CONFIG_BPF_UNPRIV_DEFAULT_OFF=y` | `unprivileged_bpf_disabled=2` default | ✅ y |
| `CONFIG_CGROUP_BPF=y` (+ `SOCK_CGROUP_DATA=y`) | cgroup socket filters — **required for kernel ≥ 4.14 devices shipping Q+** (replaces the out-of-tree "paranoid network" patch) | ✅ y / y |
| `CONFIG_NET_CLS_BPF`, `CONFIG_NET_ACT_BPF`, `CONFIG_NETFILTER_XT_MATCH_BPF` | tc classifier/action BPF, iptables `xt_bpf` | ✅ y / y / y |
| `CONFIG_BPF_EVENTS=y` | kprobe / tracepoint / perf-event BPF | ✅ y |
| `CONFIG_BPF_STREAM_PARSER=y` → `STREAM_PARSER` + `NET_SOCK_MSG` | sockmap / `sk_msg` (broke in build #103, fixed in this line) | ✅ y (CI asserts 3 objects + `sk_psock_init`, `sock_map_close`, `sock_map_destroy`, `tcp_bpf_recvmsg`, `strp_init`) |
| `CONFIG_INET_UDP_DIAG=y` | AOSP eBPF traffic-monitor stack | ✅ y |
| `xt_qtaguid` **off** | AOSP: kernel ≥ 4.14 shipping Q+ must have it off | ✅ absent from the tree entirely |
| `CONFIG_DEBUG_INFO_BTF=y` (+ pahole) | CO-RE / libbpf relocation, BTF kfuncs | ❌ not set, no pahole in CI (§4.4) |
| `CONFIG_BPF_LSM=y` | BPF LSM programs | ❌ off (would need trampolines too) |

### 4.2 How much is fulfilled — the ABI surface

Counted out of `include/uapi/linux/bpf.h` (same method for every column):

| kernel | map types | prog types | helpers |
|---|---|---|---|
| stock v4.14 | 16 | 15 | 54 |
| v5.4 | 26 | 26 | 111 |
| **this tree** | **29** | **31** | **156** |
| v5.10 | 29 | 31 | 156 |
| v5.15 | 30 | 32 | 176 |

**The backported ABI is exactly upstream v5.10**, with the matching machinery in `kernel/bpf/` (`btf.c`,
`ringbuf.c`, `trampoline.c`, `bpf_iter.c`, `local_storage.c`, `bpf_struct_ops.c`, `bpf_lsm.c`,
`dispatcher.c`, `map_iter.c`, `task_iter.c`), `net/core/{sock_map,skmsg}.c`, `net/ipv4/tcp_bpf.c`,
subprogram support (`jit_subprogs()`), and the `tnum`-based verifier. Program types added over stock 4.14
include `CGROUP_SOCK_ADDR`, `CGROUP_SOCKOPT`, `SK_MSG`, `SK_REUSEPORT`, `SK_LOOKUP`,
`RAW_TRACEPOINT(_WRITABLE)`, `TRACING`, `STRUCT_OPS`, `LSM`, `EXT`; map types include `RINGBUF`,
`STRUCT_OPS`, `SK_STORAGE`, `INODE_STORAGE`, `QUEUE/STACK`, `SOCKHASH`.

Reachability is the caveat — having the enum does not make a program type usable; the arch backend
decides. That is where the real defect was.

### 4.3 The defect found in this audit (fixed, run #128)

`arch/arm64/net/bpf_jit_comp.c` was never part of the backport: still the 4.14 instruction switch, with
**no `BPF_JMP32` cases at all**. Any program with a 32-bit branch hit

```c
	default:
		pr_err_once("unknown opcode %02x\n", code);
		return -EINVAL;
```

and with `CONFIG_BPF_JIT_ALWAYS_ON=y` there is no interpreter fallback → the load simply failed. Reachable
without exotic tooling: the **verifier itself emits `BPF_JMP32`** (`fixup_bpf_calls()` rewrites 32-bit
register `a % b` / `a / b` into a divide-by-zero guard built from
`BPF_RAW_INSN((is64 ? BPF_JMP : BPF_JMP32) | …)`), and clang emits `JMP32` for 32-bit compares with
`-mcpu=v3`.

**Fix:** upstream **`654b65a04880` ("arm64: bpf: implement jitting of JMP32") ported verbatim** — `is64`
now covers `BPF_JMP` while `BPF_JMP32` stays narrow; 10 register + 10 immediate compare cases and 2
`JSET` cases added; `CMP`/`TST`/`mov_i` take the width from `is64`. CI asserts ≥22 `BPF_JMP32` cases, the
`is64` definition, the four width-aware emissions, **and** that the verifier's own JMP32 rewrite is still
present (so the JIT gate cannot be satisfied by deleting the feature in the verifier).

### 4.4 What is still missing (documented, not fixed)

| gap | effect | what fixing it takes |
|---|---|---|
| `arch_prepare_bpf_trampoline` is the `__weak` `-ENOTSUPP` (`kernel/bpf/trampoline.c:441`) | `BPF_PROG_TYPE_TRACING` (fentry/fexit) and `STRUCT_OPS` cannot attach → eBPF TCP CC unusable; `BPF_LSM` would need it too | port arm64 BPF trampolines (upstream 5.11+) |
| `bpf_arch_text_poke` is the `__weak` `-ENOTSUPP` (`kernel/bpf/core.c:2348`) | BPF dispatcher never gets patched (`dispatcher.c:125`, caller `net/core/filter.c:10400` = XDP) — a fast-path loss, not functional; tail calls still work (this JIT emits the direct-jump form) | port `bpf_arch_text_poke` (`aarch64_insn_patch_text`, upstream 5.11+) |
| no BTF: `DEBUG_INFO_BTF` and `DEBUG_INFO` unset, no pahole in CI | no CO-RE relocation, no BTF kfuncs (`btf_kfunc_id_set` does not exist here), `/sys/kernel/btf` absent | generator wiring already exists (`lib/Kconfig.debug:211`, `scripts/link-vmlinux.sh gen_btf()`, needs pahole ≥ 1.13): enable `DEBUG_INFO` + `DEBUG_INFO_BTF`, add `dwarves` to CI |
| `BPF_PROBE_MEM` not handled by this JIT | libbpf/BCC probes doing direct kernel-memory reads (5.5+) cannot load; Android's loader does not use it | port from upstream 5.5+ (exception-table loads) |
| `BPF_LSM` off, `XDP_SOCKETS` off (`XSKMAP`/AF_XDP), `LWTUNNEL` off, `BPF_PRELOAD` off | those program types/maps unreachable | config decisions, not defects |

### 4.5 BPF userspace compatibility: the fake uname (#129)

Android's BPF userspace (`bpfloader`, `netbpfload`, `netd`, `uprobestats` — all root) chooses its program
set / feature level from the `uname()` release string. With the real `4.14.357` they take the legacy path;
they are now told **`5.10.239`** — the release whose feature set this tree implements exactly (§4.2).

* `kernel/sys.c`, `fake_bpf_uname()`: gate is `current_uid().val == 0` **and** `current->comm` ∈
  {`bpfloader`, `netbpfload`, `netd`, `uprobestats`}. Unprivileged callers and every other process still
  see the real release.
* `init/Kconfig`, choice **"Fake uname kernel version"**: `NONE` (default) / `5_4` / `5_10` / `5_15` /
  `6_1` / `6_6` / `6_12`; defconfig selects `5_10`.
* **Composition with SUSFS:** in `newuname()` the order is `memcpy(utsname())` → `fake_bpf_uname()` →
  `susfs_spoof_uname()`, so a manager-configured SUSFS release (or `"default"`) always overwrites the
  fake. `fs/susfs.c` is untouched; there is never a second writer fighting SUSFS. CI asserts the ordering
  by line number plus the SUSFS overwrite rule (`if (my_uname.release[0] != '\0')`).
* `uname(2)` on arm64 is `__NR_uname 160 → sys_newuname`, so one site covers 32-bit and 64-bit callers.
* `/proc/version` is deliberately not spoofed (same as SUSFS's own behaviour here).
* Accepted trade-off: a root process can set its `comm` to `netd` and observe the spoof; and userspace may
  then try features this backend lacks (§4.4). If a ROM's loader is unhappy at 5.10, switch to
  `CONFIG_FAKE_UNAME_5_4` or `NONE` — one defconfig line.

### 4.6 On-device verification checklist

```sh
adb shell dmesg | grep -i 'unknown opcode'          # expect: empty  (JMP32-class bugs appear here)
adb shell logcat -d | grep -i bpf | head             # bpfloader/verifier errors
adb shell ls /sys/fs/bpf/                            # prog_* / map_* pins from bpfloader
adb shell cat /proc/sys/kernel/unprivileged_bpf_disabled   # expect 2
adb shell dmesg | grep -iE 'susfs|kernelsu|nomount'
   # expect "susfs is initialized! version: v2.3.0" and "NoMount: Loaded successfully"
adb shell keyctl show | head                         # 'nomount' key type present
# who sees the fake release (root, one of the four comms) vs the real one:
adb shell su -c 'sh -c "exec -a netd uname -r"'      # expect 5.10.239   (only if comm is forgeable)
adb shell uname -r                                   # expect the real 4.14.357 for ordinary shells
# manager: kernel version must read 35171
```

### 4.7 What CI proves

Config gates (full BakaSU/SUSFS mode set, all 9 SUSFS features, `FUSE_FS`, `NOMOUNT`, BPF core,
stream-parser triple, `FAKE_UNAME_5_10=y` with `FAKE_UNAME_NONE` off, `BPF_LSM` off), source-shape gates
(SUSFS call shapes + declaration ordering, `vfs_statx_fd` → `ksu_handle_vfs_fstat()` wiring, the
`BPF_JMP32` gates, and the fake-uname/SUSFS ordering), and link gates (`kernelsu_init`,
`ksu_handle_susfs_cmd`, `susfs_get_enabled_features`, `ksu_su_compat_enabled`, `nomount_init`,
`susfs_init`, `sk_psock_init`/`sock_map_close`/`tcp_bpf_recvmsg`/`strp_init` in `out/vmlinux`).

---

## 5. Cross-check against Kinesis (`AzyrRuthless/kernel_xiaomi_sm6250`)

A public ROM base kernel for **sm6250 / miatoll** — same SoC family, **same OpenELA 4.14.357 base, same
BPF-from-5.10 backport**. Branches: `16` (the 4.14 + 5.10-BPF branch) and `16-5.4`. Kernel release string
`4.14.357-kinesis-omega-bpf`.

**It is this tree's sibling, exactly, at the BPF JIT:** our pre-fix `arch/arm64/net/bpf_jit_comp.c`
(`39740cd08`) is **byte-identical (0-line diff)** to theirs at `ref=16`. The `BPF_JMP32` hole (§4.3) was
therefore inherited from this lineage — and build #128 fixed it for both.

| item | Kinesis `16` | this tree (#129) |
|---|---|---|
| base | 4.14.357 OpenELA | 4.14.357 OpenELA |
| BPF core | 5.10 backport | identical ABI (§4.2) |
| arm64 JIT `BPF_JMP32` | **0 cases** | **22 cases** (upstream `654b65a04880`) |
| `BPF_JIT_ALWAYS_ON` | y | y → without JMP32, programs fail to load (no interpreter fallback) |
| stream parser (sockmap/`sk_msg`) | off in defconfig | on + 3 objects + 6 symbols asserted |
| `BPF_EVENTS` (kprobe/tracepoint BPF) | not in defconfig | `=y` |
| `KEYS` | not in defconfig | `=y` (NoMount needs it) |
| KernelSU / SUSFS / NoMount | none — plain ROM base | BakaSU v4.2.0-rc3 + SUSFS v2.3.0 + NoMount |
| fake uname | `CONFIG_FAKE_UNAME_*` in `kernel/sys.c` + `init/Kconfig` | **adopted, composed with SUSFS** (§4.5) |

### 5.1 Their patch, verbatim shape

`kernel/sys.c`, `SYSCALL_DEFINE1(newuname, …)`, immediately before `copy_to_user()`; `init/Kconfig` choice
default `FAKE_UNAME_NONE` ("Kernel side spoof for BPF"):

```c
#ifndef CONFIG_FAKE_UNAME_NONE
	if (!strncmp(current->comm, "bpfloader",   9) ||
	    !strncmp(current->comm, "netbpfload", 10) ||
	    !strncmp(current->comm, "netd",        4) ||
	    !strncmp(current->comm, "uprobestats",11)) {
		if (current_uid().val == 0) {
			strcpy(tmp.release, "5.4.200");   /* or 5.10.239 / 5.15.200 / 6.1.200 / … */
		}
	}
#endif
```

The one change made when adopting it here: it must not land on top of `susfs_spoof_uname()`, which writes
the same field at the same place in our `kernel/sys.c` (manager-controlled via `CMD_SUSFS_SET_UNAME`).
Two independent writers would give "last one wins" and an unpredictable `uname -r` for those processes.
Our version calls the fake first and SUSFS second, so SUSFS always wins and its behaviour is unchanged —
enforced by CI line-number ordering, not by comment.
