# Proper Adaptation Guide: KSU-Next v3.4.0 + SUSFS v2.3.0 using crdroid sm8150 as Reference

Reference: https://github.com/crdroidandroid/android_kernel_xiaomi_sm8150 (branch 16.0, commit a07a230b6)
- 4.14 like miatoll, has drivers/kernelsu/ (KSU-Next) and fs/susfs.c, include/linux/susfs.h/def.h
- fs/Makefile: obj-$(CONFIG_KSU_SUSFS) += susfs.o
- drivers/kernelsu/Kconfig: menu "KernelSU" + submenu "KernelSU - SUSFS" with TRY_UMOUNT
- VFS files patched: fs/namei.c, namespace.c, notify/fdinfo.c, open.c, proc/base.c, cmdline.c, fd.c, task_mmu.c, proc_namespace.c, readdir.c, stat.c, statfs.c, super.c, include/linux/mount.h, sched.h, kernel/kallsyms.c, sys.c
- build.config.common: BRANCH=android-4.14, CC=clang, LD=ld.lld, ARCH=arm64

## 1. KSU-Next v3.4.0 Proper Adaptation (NOT copy-paste)

Official: https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v3.4.0
Tag SHA: 1a879d6a866f80b1fa1c1009a2ffa747873cbb5e

Correct method:
```bash
git clone https://github.com/KernelSU-Next/KernelSU-Next.git /tmp/ksu-next
cd /tmp/ksu-next
git checkout v3.4.0
cd /home/user/CustomKernel1
bash /tmp/ksu-next/kernel/setup.sh v3.4.0
```
Creates symlink drivers/kernelsu -> ../KernelSU-Next/kernel, patches drivers/Makefile and drivers/Kconfig.

Why adaptation: uses upstream supported script, keeps KernelSU-Next as separate dir, easy to update, no manual copy of 300+ files.

Kconfig: upstream has KSU, KSU_DEBUG etc, crdroid adds menu "KernelSU - SUSFS" with 12 options. Adapt by editing KernelSU-Next/kernel/Kconfig to add SUSFS submenu.

## 2. SUSFS v2.3.0 Proper Adaptation (NOT wholesale file copy)

Official: https://gitlab.com/simonpunk/susfs4ksu (v2.3.0 = SUSFS_VERSION "v2.3.0")

Core files (standalone, okay):
- fs/susfs.c, include/linux/susfs.h, include/linux/susfs_def.h

VFS files (MUST adapt, not copy-paste):
For each file, reference shows WHERE to add hooks, but apply only SUSFS logic to miatoll's original:

- include/linux/mount.h: add u64 susfs_mnt_id_backup inside vfsmount struct
- include/linux/sched.h: add u64 susfs_task_state, susfs_last_fake_mnt_id before randomized_struct_fields_end, preserve miatoll's curr_window_cpu pointers, free_task_load_ptrs, msm_sched_setaffinity
- include/linux/fs.h: if using sm8150 super.c, add #define SB_I_PERSB_BDI 0x200
- fs/Makefile: obj-$(CONFIG_KSU_SUSFS) += susfs.o
- fs/*.c, kernel/*.c: add only #ifdef CONFIG_KSU_SUSFS blocks (sus_path hiding, sus_mount hiding, kstat spoofing, open_redirect, cmdline/uname spoof, kallsyms hide)

Adaptation principle: diff should show only CONFIG_KSU_SUSFS blocks added, not entire file rewrite.

## 3. defconfig

Add:
CONFIG_KSU=y
CONFIG_KSU_SUSFS=y
CONFIG_F2FS_FS=y + SECURITY + ENCRYPTION + COMPRESSION
CONFIG_EROFS_FS=y
Remove USB_GSPCA, RMNET_PERF, RMNET_SHS
# CONFIG_MODULE_SIG_FORCE is not set

make ARCH=arm64 O=/tmp/kcheck vendor/xiaomi/miatoll_defconfig
grep KSU /tmp/kcheck/.config

## 4. Pure Clang 18 Compile (like crdroid build.config.common)

crdroid: BRANCH=android-4.14 CC=clang LD=ld.lld ARCH=arm64

GitHub Actions (ubuntu-24.04 Clang 18):
make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 CROSS_COMPILE=aarch64-linux-gnu- vendor/xiaomi/miatoll_defconfig
make -j$(nproc) O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 CC='ccache clang' LD=ld.lld CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- CONFIG_NO_ERROR_ON_MISMATCH=y

LLVM=1 LLVM_IAS=1 sets CC=clang, LD=ld.lld, AR=llvm-ar, no GCC.

## 5. Next Steps

Current repo has KSU-Next v3.4.0 via setup.sh (proper) and SUSFS v2.3.0 core files from sm8150 (okay) and VFS files adapted from sm8150 with fixes for sched.h and fs.h.

To properly adapt: restore VFS files from backup and re-apply only SUSFS hooks, preserving miatoll logic, then build with Clang 18.

Artifacts: AnyKernel3 osm0sis layout, Image.gz, dtb.img, dtbo.img, zip Stormbreaker-miatoll-Clang18-KSU-SUSFS-*.zip
