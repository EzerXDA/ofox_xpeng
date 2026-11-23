#!/system/bin/sh
#
# Novatek touch firmware reflash for recovery.
# 5.10: touch/display modules are loaded by first-stage init from vendor_boot
# /lib/modules; load() below is only a fallback (EEXIST when already loaded).
#
# Touch FW lives at /lib/firmware (kernel default search). Do not load from
# mounted /vendor/firmware — Format Data / sideload can make that inode
# unreadable (EUCLEAN) and panel-resume reflash then kills IRQs.
#
# Novatek 0-flash: probe does not download SRAM FW. DT resume name is
# tm_novatek_ts_fw.bin; MMI doreflash name is novatek_ts-NT36675-*-xpeng.bin.
# Both must exist. After doreflash the panel is already on, so poke interpolation
# (Cmd 0x72) which nvt_mmi_post_resume would send on the first unblank.
#

touch_class_path=/sys/class/touchscreen
firmware_file="novatek_ts-NT36675-21101302-6044-xpeng.bin"
dt_firmware_file="tm_novatek_ts_fw.bin"

load() {
	[ -f "/lib/modules/$1" ] || return 0
	insmod "/lib/modules/$1" 2>/dev/null || true
	return 0
}

# exFAT is built into the 5.10 kernel (CONFIG_EXFAT_FS=y).

# Minimal mmi stack for touch (ADSP/battery: init.recovery.qcom.rc)
load mmi_info.ko
load mmi_annotate.ko
load mmi_relay.ko
load sensors_class.ko

# --- touch (needs msm_drm stub for panel notifier) ---
load msm_drm.ko
load touchscreen_mmi.ko
load nova_0flash_mmi.ko

# Never set sys.usb.config to anything other than adb/fastboot/none.

firmware_path=""
for d in /lib/firmware /system/etc/firmware /sbin/firmware; do
	if [ -f "$d/$firmware_file" ]; then
		firmware_path="$d"
		break
	fi
done
if [ -z "$firmware_path" ] && [ -f /vendor/firmware/$firmware_file ]; then
	if cat /vendor/firmware/$firmware_file >/dev/null 2>&1; then
		firmware_path=/vendor/firmware
	fi
fi
[ -n "$firmware_path" ] || exit 0

# DT pre_resume looks up tm_novatek_ts_fw.bin until doreflash rewrites the name.
for d in /lib/firmware /system/etc/firmware /sbin/firmware "$firmware_path"; do
	[ -d "$d" ] || continue
	[ -f "$d/$firmware_file" ] || continue
	cp -f "$d/$firmware_file" "$d/$dt_firmware_file" 2>/dev/null || true
done

echo "novatek"
touch_product_string=$(ls "$touch_class_path" 2>/dev/null)
if [ -n "$touch_product_string" ] && [ -e "$touch_class_path/$touch_product_string/path" ]; then
	touch_path=/sys$(cat "$touch_class_path/$touch_product_string/path" | awk '{print $1}')
	echo 1 > "$touch_path/forcereflash"
	echo "$firmware_file" > "$touch_path/doreflash"
	# Skip reset: it drops the IC out of report mode until DRM unblank.
	if [ -e "$touch_path/drv_irq" ]; then
		echo 1 > "$touch_path/drv_irq"
	fi
	# DT interpolation_cmd is 0x72 0x03 (CMD_OFF). post_resume re-sends it
	# after unblank; toggle here so first-boot reports without a lock cycle.
	if [ -e "$touch_class_path/$touch_product_string/interpolation" ]; then
		echo 0 > "$touch_class_path/$touch_product_string/interpolation"
		echo 1 > "$touch_class_path/$touch_product_string/interpolation"
		echo 0 > "$touch_class_path/$touch_product_string/interpolation"
	fi
	if [ -e "$touch_class_path/$touch_product_string/edge" ]; then
		echo 0 > "$touch_class_path/$touch_product_string/edge"
	fi
fi
