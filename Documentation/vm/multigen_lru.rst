============================
Multigenerational LRU (MGLRU)
============================

Background
==========

The classic LRU keeps two lists per type (active and inactive) and guesses
which pages are hot by moving them between the two. That guess is wrong often
enough that reclaim throws out pages which are about to be used again, which is
what shows up on a phone as stutter under memory pressure.

The multigenerational LRU replaces the two lists with a set of generations and
tiers. Pages advance through generations as they are referenced, and reclaim
walks from the oldest generation forward, so it can find genuinely cold pages
instead of approximating. On Android-class workloads this both reclaims better
and costs less CPU, because the aging is done in batches rather than by
per-page list surgery.

This tree carries the 4.14 backport of that series. It is built from:

  mm/vmscan.c            the aging, eviction and stats machinery
  mm/workingset.c        eviction/refault accounting (shadow entries)
  mm/mm_inline.h         list add/delete and page tier helpers
  mm/memcontrol.c        per-memcg mm_struct lists
  mm/swap.c, mm/memory.c, mm/rmap.c, mm/swapfile.c, mm/swap_state.c
  kernel/fork.c, kernel/exit.c, kernel/sched/core.c, fs/exec.c
                         mm_struct lifetime and context-switch tracking

Config options
==============

CONFIG_LRU_GEN
	Compiles the implementation in. Required for anything below.

CONFIG_LRU_GEN_ENABLED
	Turns it on by default. Unset here on purpose: the kernel boots with the
	classic reclaim path and MGLRU is opt-in at runtime.

CONFIG_LRU_GEN_STATS
	Per-generation stats exposed through debugfs. Kept off; it costs memory
	per node and per memcg.

CONFIG_NR_LRU_GENS (default 7), CONFIG_TIERS_PER_GEN (default 4)
	Shape of the generation/tier arrays. These consume spare bits in
	page->flags; the defaults are what the backport was tuned for.

Runtime control
===============

	# current state (0 = classic reclaim, 1 = MGLRU)
	cat /sys/kernel/mm/lru_gen/enabled

	# switch on / off
	echo 1 > /sys/kernel/mm/lru_gen/enabled
	echo 0 > /sys/kernel/mm/lru_gen/enabled

	# how eagerly aging runs
	cat /sys/kernel/mm/lru_gen/spread
	echo 2 > /sys/kernel/mm/lru_gen/spread

The setting is not persistent: it resets to the compiled-in default on reboot,
which is deliberate so a bad interaction cannot survive a restart.

``spread`` is the ratio of old to young pages that lets the walker skip a round
of aging. Smaller values age more often (reclaim cold pages sooner, better for
small RAM), larger values let things settle (less CPU, better for large RAM).
mm/ram_tune.c sets it per RAM tier at boot: 0 on 4 GB, 1 on 6 GB, 2 on 8 GB+.

Interaction with the rest of the VM
===================================

While MGLRU is enabled:

 - ``activate_page()`` is a no-op and ``mark_page_accessed()`` only bumps the
   page's usage tier; activation happens later, during eviction.
 - ``shrink_lruvec()`` delegates to the multigenerational scan
   (``lru_gen_shrink_lruvec()``) and ``age_active_anon()`` delegates to
   ``lru_gen_age_node()``.
 - pages found young during rmap walks advance a generation via
   ``lru_gen_scan_around()``.
 - split THP tails keep their generation/tier bits
   (see ``__split_huge_page_tail()``).
 - ``/proc/vmstat`` event counters reflect the multigenerational path
   (``PGSCAN_*``, ``PGSTEAL_*``) as usual.

Boot-time tuning note
=====================

mm/ram_tune.c applies RAM-tier VM defaults at late_initcall and is also what
sets ``lru_gen_spread`` for the installed RAM size, so no manual tuning is
needed after switching MGLRU on.
