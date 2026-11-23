#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#
# OrangeFox (fox_16.0) build vars for xpeng on the 5.10 kernel port.
# Lunch: twrp_xpeng-eng
#
# FOX_* vars must be exported here or on the command line (not in .mk files).
# They are only set when FOX_BUILD_DEVICE=xpeng, so sourcing envsetup.sh for
# another device is not affected.
#

FDEVICE="xpeng"

if [ "$FOX_BUILD_DEVICE" = "$FDEVICE" ]; then
	export LC_ALL="C"
	export ALLOW_MISSING_DEPENDENCIES=true

	# Virtual A/B, recovery-as-boot, no MIUI
	export FOX_AB_DEVICE=1
	export FOX_VIRTUAL_AB_DEVICE=1
	export FOX_VANILLA_BUILD=1
	export OF_DISABLE_MIUI_SPECIFIC_FEATURES=1
	export OF_NO_TREBLE_COMPATIBILITY_CHECK=1
	export FOX_TARGET_DEVICES="xpeng"
	export FOX_RECOVERY_SYSTEM_PARTITION="/dev/block/mapper/system"
	export FOX_RECOVERY_VENDOR_PARTITION="/dev/block/mapper/vendor"

	# Prebuilt 5.10 Image (prebuilt/kernel)
	export OF_FORCE_PREBUILT_KERNEL=1

	# Decryption: QTI Keymaster 4.1 (qseecomd + keymaster@4.1-service-qti)
	export OF_DEFAULT_KEYMASTER_VERSION=4.1

	# Battery: legacy sysfs path published by init_thermal.sh
	# (TW_CUSTOM_BATTERY_PATH=/tmp/twrp_battery in BoardConfig.mk)
	export OF_USE_LEGACY_BATTERY_SERVICES=1

	# Screen 1080x2460 with a centred punch-hole camera, no hardware keys
	export OF_SCREEN_H=2460
	export OF_STATUS_H=100
	export OF_STATUS_INDENT_LEFT=48
	export OF_STATUS_INDENT_RIGHT=48
	export OF_HIDE_NOTCH=1
	export OF_ALLOW_DISABLE_NAVBAR=0
	export OF_FLASHLIGHT_ENABLE=0
	export OF_USE_GREEN_LED=0

	export OF_QUICK_BACKUP_LIST="/boot;/data;"

	# Format Data on FBE + metadata encryption (as the official garnet
	# fox_12.1/fox_16.0 trees): unbind /sdcard before mkfs, drop the userdata dm device
	# with dmctl and wipe /metadata afterwards. These replace the twrp-16.0
	# bootable/recovery patches 0005/0009/0010, which OrangeFox cannot use.
	export OF_UNBIND_SDCARD_F2FS=1
	export OF_USE_DMCTL=1
	export OF_WIPE_METADATA_AFTER_DATAFORMAT=1
	export OF_LOOP_DEVICE_ERRORS_TO_LOG=1

	# Ramdisk budget: keep the boot ramdisk close to the Lineage one (~20 MB
	# lz4 / ~40 MB unpacked); the 5.4 tree hit unpack failures above that.
	# Do NOT use OF_USE_LZMA_COMPRESSION: the 5.10 kernel has no RD_LZMA.
	# lz4 ramdisk, as the official OrangeFox QTI trees (kernel has RD_LZ4).
	export OF_USE_LZ4_COMPRESSION=1
	export FOX_DELETE_AROMAFM=1
	export FOX_REMOVE_AAPT=1
	export FOX_REMOVE_BASH=1
	export FOX_EXCLUDE_NANO_EDITOR=1
	export FOX_DELETE_MAGISK_ADDON=1

	export OF_MAINTAINER="${OF_MAINTAINER:-xpeng 5.10}"
	export FOX_MAINTAINER_PATCH_VERSION="${FOX_MAINTAINER_PATCH_VERSION:-1}"
fi
