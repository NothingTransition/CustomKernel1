// SPDX-License-Identifier: GPL-2.0
/*
 * mm/ram_tune.c - memory-management defaults sized to the installed RAM
 *
 * Stormbreaker ships a single kernel image for the whole miatoll family, which
 * exists in 4 GB, 6 GB and 8 GB variants. One set of VM defaults is always a
 * compromise: what keeps a 4 GB phone out of direct reclaim makes an 8 GB
 * phone reclaim pages it did not need to touch.
 *
 * So measure the RAM once at boot and apply the tier that fits. This runs as a
 * late_initcall, i.e. after the VM has sized its watermarks (device_initcall)
 * but before userspace starts, so:
 *   - the values below become the effective boot defaults, and
 *   - ROM init scripts / root can still override anything at runtime, because
 *     every knob here is a normal /proc/sys/vm/... sysctl (and the MGLRU one is
 *     /sys/kernel/mm/lru_gen/spread). This tunes defaults, it does not lock
 *     anything down.
 *
 * Note the RAM we see is *usable* RAM, not the marketing number: a "4 GB"
 * miatoll reports roughly 3.5-3.8 GB, a "6 GB" roughly 5.5-5.8 GB. The tier
 * boundaries below are placed in the gaps between those ranges.
 */

#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/mm.h>
#include <linux/swap.h>
#include <linux/writeback.h>
#include <linux/dcache.h>

#ifdef CONFIG_LRU_GEN
/* mm/vmscan.c - how eagerly the multigenerational LRU ages generations. */
extern int lru_gen_spread;
#endif

struct ram_tier {
	const char *name;
	unsigned long max_pages;	/* inclusive ceiling, in pages */
	int swappiness;
	int vfs_cache_pressure;
	int dirty_ratio;
	int dirty_background_ratio;
	int watermark_scale_factor;
	int page_cluster;
	int lru_gen_spread;
};

/*
 * Why these values:
 *
 * swappiness=100        Swap on these devices is zram (compressed RAM), not a
 *                       disk, so a swap-in is cheap and anon pages are a good
 *                       place to reclaim from. The 60 default is tuned for
 *                       rotating disks and leaves zram underused; Android's own
 *                       userspace sets 100 for the same reason.
 *
 * vfs_cache_pressure    Slightly above 100 on small-RAM devices so dentry/inode
 *                       slab gives way to page cache and anon pages under
 *                       pressure. 8 GB keeps the kernel default (100) since it
 *                       has no reason to throw metadata caches away.
 *
 * dirty_ratio/          Lower dirty ceilings on small-RAM devices: writeback
 * background_ratio     starts earlier and each flush is smaller, which trades a
 *                       little throughput for far fewer multi-hundred-ms stalls
 *                       when reclaim has to wait on a big writeback. 8 GB keeps
 *                       the kernel defaults.
 *
 * watermark_scale_factor
 *                       This is the real anti-jank knob. It sets the gap between
 *                       the min and low watermarks, i.e. how much free memory
 *                       kswapd keeps in reserve before it starts reclaiming in
 *                       the background. It works out to
 *                       managed_pages * watermark_scale_factor / 10000, so the
 *                       kernel default (20 = 0.2%) leaves only ~7 MB on a 4 GB
 *                       device and ~15 MB on an 8 GB one - not enough to absorb
 *                       an app's allocation burst, so allocations fall through
 *                       to *direct* reclaim and the phone stutters.
 *                       The values below are picked so every tier ends up with
 *                       roughly the same absolute reserve, about 40 MB:
 *                         4 GB:  ~950k pages * 100/10000 = 38 MB
 *                         6 GB: ~1450k pages *  75/10000 = 43 MB
 *                         8 GB: ~1950k pages *  50/10000 = 39 MB
 *                       i.e. a smaller percentage on larger devices, which
 *                       keeps kswapd from working harder than it needs to.
 *
 * page_cluster=0        Swap readahead of 2^3 pages (the 4.14 default for our
 *                       RAM size) is a disk optimisation. zram is random access
 *                       with no seek penalty, so readahead there is pure waste.
 *
 * lru_gen_spread        Only matters when MGLRU is enabled. It is the ratio of
 *                       old to young pages that makes the walker skip a round
 *                       of aging. Smaller = age more often = reclaim cold pages
 *                       sooner, which is what a 4 GB device wants; larger = let
 *                       things settle, which suits 8 GB.
 */
static const struct ram_tier ram_tiers[] = {
	{ /* ~4 GB installed (~3.5-3.8 GB usable) */
		.name			= "4gb",
		.max_pages		= 5UL << (30 - PAGE_SHIFT),
		.swappiness		= 100,
		.vfs_cache_pressure	= 150,
		.dirty_ratio		= 10,
		.dirty_background_ratio	= 5,
		.watermark_scale_factor	= 100,
		.page_cluster		= 0,
		.lru_gen_spread		= 0,
	},
	{ /* ~6 GB installed (~5.5-5.8 GB usable) */
		.name			= "6gb",
		.max_pages		= 7UL << (30 - PAGE_SHIFT),
		.swappiness		= 100,
		.vfs_cache_pressure	= 125,
		.dirty_ratio		= 15,
		.dirty_background_ratio	= 5,
		.watermark_scale_factor	= 75,
		.page_cluster		= 0,
		.lru_gen_spread		= 1,
	},
	{ /* 8 GB and up: kernel defaults are already appropriate */
		.name			= "8gb+",
		.max_pages		= ~0UL,
		.swappiness		= 100,
		.vfs_cache_pressure	= 100,
		.dirty_ratio		= 20,
		.dirty_background_ratio	= 10,
		.watermark_scale_factor	= 50,
		.page_cluster		= 0,
		.lru_gen_spread		= 2,
	},
};

static const struct ram_tier *ram_tier_for(unsigned long pages)
{
	unsigned int i;

	/* the last entry is the catch-all, so only scan the bounded ones */
	for (i = 0; i < ARRAY_SIZE(ram_tiers) - 1; i++) {
		if (pages <= ram_tiers[i].max_pages)
			return &ram_tiers[i];
	}

	return &ram_tiers[ARRAY_SIZE(ram_tiers) - 1];
}

static int __init ram_tune_init(void)
{
	const struct ram_tier *tier = ram_tier_for(totalram_pages);
	unsigned long mb = totalram_pages >> (20 - PAGE_SHIFT);

	vm_swappiness = tier->swappiness;
	sysctl_vfs_cache_pressure = tier->vfs_cache_pressure;
	vm_dirty_ratio = tier->dirty_ratio;
	dirty_background_ratio = tier->dirty_background_ratio;
	page_cluster = tier->page_cluster;

	/*
	 * Watermarks are latched at boot, so the new factor only takes effect
	 * once we recompute them. Safe here: this is a spinlock around the
	 * per-zone recalculation and we are still single-threaded init context
	 * with no reclaim pressure yet.
	 */
	if (watermark_scale_factor != tier->watermark_scale_factor) {
		watermark_scale_factor = tier->watermark_scale_factor;
		setup_per_zone_wmarks();
	}

#ifdef CONFIG_LRU_GEN
	/* kswapd is already running, hence the WRITE_ONCE (it uses READ_ONCE). */
	WRITE_ONCE(lru_gen_spread, tier->lru_gen_spread);
#endif

	pr_info("ram_tune: %s tier for %lu MB RAM: swappiness=%d vfs_cache_pressure=%d dirty=%d/%d watermark_scale_factor=%d page_cluster=%d\n",
		tier->name, mb, tier->swappiness, tier->vfs_cache_pressure,
		vm_dirty_ratio, dirty_background_ratio,
		watermark_scale_factor, page_cluster);

	return 0;
}
late_initcall(ram_tune_init);
