# Diagnostic builds (boot stall bisect)

These are **not releases**. They exist to find why the kernel intermittently
sits on the boot animation on Infinity X 4.0 / 4 GB (reported on both v108 and
v109), while the Imperial-X kernel boots the same ROM.

Every build starts from the exact v109 tree. KernelSU, SUSFS and NoMount are
identical in all of them; only the named hypothesis differs.

| zip | what it changes vs v109 |
|---|---|
| `Stormbreaker-DIAG-diet-*.zip` | all boot-relevant non-root deltas vs Imperial-X at once: memory cgroup off (+swap accounting), HZ 300 → 100, F2FS compression off, MSM_PERFORMANCE off, SCHED_CORE_CTL off, RMNET_PERF/SHS off, `ram_tune`/`net_tune` not run |
| `Stormbreaker-DIAG-hz100-*.zip` | HZ 300 → 100 only |
| `Stormbreaker-DIAG-memoff-*.zip` | `CONFIG_MEMCG` (+swap) off only |
| `Stormbreaker-DIAG-vmoff-*.zip` | `mm/ram_tune.c` and `net/net_tune.c` initcalls not run only |

## How to test

Flash one zip in recovery, boot, and watch the boot animation. Reboot it a few
times — the bug is intermittent, so one clean boot is not proof.

If a build does **not** boot, reflash `stormbreaker-v108` or `stormbreaker-v109`
before trying the next one.

## Also useful while testing

Right after a boot (good or bad), from a root shell:

```
su -c "ls -la /sys/fs/pstore/"
su -c "cat /sys/fs/pstore/console-ramoops* | tail -400" > /sdcard/pstore.txt
su -c "dmesg | grep -iE 'hung|blocked for more|watchdog|oom|kill|stall|timeout|denied'" > /sdcard/boot-issues.txt
```

`console-ramoops` holds the **previous** boot's kernel log, so a boot that hung
and was force-rebooted leaves its console log there — that is the single most
useful artifact for this bug.

## Field results (2026-10-04) — parked

- The ROM maintainer says Infinity X 4.0 is deliberately tight and, right now,
  only the Imperial-X kernel boots it. That matches the field data: IX boots;
  v108 and v109 intermittently stall at the boot animation; modules are not
  involved.
- `diet` **did boot** once — but after an OFRP cache clear, so the config is
  not proven to be the cause (the wipe is a confound). It was reported "heavy"
  to boot afterwards, which matches post-wipe ART dexopt on 4 GB, not the
  kernel.
- `memoff` / `hz100` / `vmoff` were never tested; the bisect is parked while
  the ROM is this restrictive. If it ever loosens, flash `memoff` first (v109
  with only the memory cgroup off). If that boots, the answer is a v109
  equivalent with the jitter work kept and memcg off — nothing needs rebuilding
  to run that test.
