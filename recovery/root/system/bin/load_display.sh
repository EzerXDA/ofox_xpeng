#!/system/bin/sh
#
# Load display stack as early as possible (before TWRP GUI).
# msm_drm is modular on lahaina; without it recovery has no /dev/dri → black screen.
# 5.10: first-stage init already loads these from vendor_boot /lib/modules
# (modules.load.recovery); this is only a fallback, so an already-loaded
# module just fails with EEXIST. No insmod -f: the kos match the kernel.
#
# Do not wait/loop here: this script is exec'd from on early-boot and blocks
# init (no recovery GUI, no enable_adb) until it returns.
#

load() {
	[ -f "/lib/modules/$1" ] || return 0
	insmod "/lib/modules/$1" 2>/dev/null || true
	return 0
}

load mmi_annotate.ko
load mmi_info.ko
load mmi_relay.ko
load sensors_class.ko
load msm_drm.ko
load touchscreen_mmi.ko
load nova_0flash_mmi.ko

exit 0
