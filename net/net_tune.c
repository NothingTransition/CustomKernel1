// SPDX-License-Identifier: GPL-2.0
/*
 * net/net_tune.c - network defaults tuned for phone use on the miatoll family
 *
 * Same philosophy as mm/ram_tune.c: stock defaults are generic, so pick the
 * ones that behave best on a device that lives on cellular and WiFi, and apply
 * them once at boot from a late_initcall. Everything written here is a normal
 * sysctl afterwards, so ROM init scripts and root can override any of it at
 * runtime - this only changes the boot default.
 *
 * Deliberately NOT done here:
 *
 *   - tcp_rmem / tcp_wmem. The windows are auto-tuned per connection and are
 *     already sized for fast links; bigger static buffers do not raise
 *     throughput (the radio sets that), they only add queuing delay and pin
 *     memory.
 *
 *   - Congestion control and the default qdisc. Those are picked by Kconfig
 *     (CONFIG_DEFAULT_TCP_CONG="bbr" and CONFIG_DEFAULT_FQ_CODEL=y) through
 *     tcp_ca_init() and sch_default_qdisc(), so there is nothing to poke here.
 *     Note that a qdisc change applies to devices created afterwards; an
 *     interface that already exists keeps its old qdisc until it is recreated
 *     or fixed with "tc qdisc replace dev <if> root fq_codel".
 */

#include <linux/init.h>
#include <linux/kernel.h>
#include <net/net_namespace.h>

/* net/ipv4/tcp_output.c - whether an idle period resets cwnd to IW. */
extern int sysctl_tcp_slow_start_after_idle;

static int __init net_tune_init(void)
{
	/*
	 * Keep the congestion window across idle periods. The stock default
	 * resets cwnd to the initial window whenever a flow has been idle,
	 * which is paid for in the first seconds of the next transfer (app
	 * resumed, screen woken, upload restarted). Plain global, not per-netns.
	 */
	sysctl_tcp_slow_start_after_idle = 0;

	/*
	 * Probe for a working path MTU when ICMP "fragmentation needed" never
	 * arrives - some carriers and CGNATs drop it, and without probing the
	 * connection hangs on large packets instead of backing off to an MSS
	 * that gets through. Nothing happens on a healthy path; this only
	 * changes what happens when the path is broken. Per-netns, and init_net
	 * is what the net.ipv4.tcp_mtu_probing sysctl backs.
	 */
	init_net.ipv4.sysctl_tcp_mtu_probing = 1;

	pr_info("net_tune: tcp_slow_start_after_idle=0 tcp_mtu_probing=1\n");

	return 0;
}
late_initcall(net_tune_init);
