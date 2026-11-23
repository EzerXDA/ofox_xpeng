#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#
# Recovery for Motorola xpeng on the 5.10 kernel port (LineageOS 23.2 based).
# Build: OrangeFox fox_16.0 (see README.md / .github/workflows).
#

DEVICE_PATH := device/motorola/xpeng

# For building with minimal manifest
ALLOW_MISSING_DEPENDENCIES := true

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    product \
    system \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot
BOARD_USES_RECOVERY_AS_BOOT := true
TARGET_NO_RECOVERY := true

# Architecture (match LineageOS sm7325-common / lineage-23.2)
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo385

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := kryo385

# APEX
DEXPREOPT_GENERATE_APEX_IMAGE := true

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := xpeng
TARGET_NO_BOOTLOADER := true

# Display (panel 1080x2460)
TARGET_SCREEN_WIDTH := 1080
TARGET_SCREEN_HEIGHT := 2460
TARGET_SCREEN_DENSITY := 400

# Kernel — prebuilt 5.10.269 Image from the 5.10 port boot.img. Must match the
# modules on the flashed vendor_boot (first-stage loads them in recovery).
BOARD_BOOT_HEADER_VERSION := 3
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --base $(BOARD_KERNEL_BASE)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
# Same as the 5.10 vendor_boot cmdline (lpm_levels is a 5.4-only parameter).
BOARD_KERNEL_CMDLINE := console=ttyMSM0,115200n8 androidboot.hardware=qcom androidboot.console=ttyMSM0
BOARD_KERNEL_CMDLINE += androidboot.memcg=1
BOARD_KERNEL_CMDLINE += service_locator.enable=1 androidboot.usbcontroller=a600000.dwc3
BOARD_KERNEL_CMDLINE += swiotlb=0 loop.max_part=7 cgroup.memory=nokmem,nosocket
BOARD_KERNEL_CMDLINE += pcie_ports=compat iptable_raw.raw_before_defrag=1
BOARD_KERNEL_CMDLINE += ip6table_raw.raw_before_defrag=1
BOARD_KERNEL_CMDLINE += firmware_class.path=/vendor/firmware_mnt/image
BOARD_KERNEL_CMDLINE += androidboot.hab.product=xpeng

TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
# dtbo.img kept under prebuilt/ for optional flashing; DTBO is its own partition
# on this device (do not embed into recovery-as-boot).
# DTB lives in vendor_boot (see prebuilt/dtb).
# 5.10 kernel modules: none in this tree. First-stage init loads them from the
# 5.10 vendor_boot; recovery/root/lib/modules/modules.load.recovery replaces
# vendor_boot's list to add the ADSP/battery and qseecom/ion stacks.

# Prefer LZ4 + size cuts (recovery-as-boot ramdisk budget).
# Motokernel fails unpack if initramfs is far above LOS (~40MB unpacked).
BOARD_RAMDISK_USE_LZ4 := true
TW_EXCLUDE_BASH := true
TW_EXCLUDE_NANO := true
TW_NO_EXFAT := true
TW_NO_EXFAT_FUSE := true
TW_NO_NETWORK := true
TW_INCLUDE_REPACKTOOLS := false
TW_EXCLUDE_TZDATA := true
TWRP_INCLUDE_LOGCAT := false
TARGET_USES_LOGD := false
BOARD_RECOVERY_IMAGE_PREPARE := $(DEVICE_PATH)/recovery/slim-ramdisk.sh

# Partitions (LineageOS 23.2 BoardConfig)
BOARD_FLASH_BLOCK_SIZE := 262144
BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_DTBOIMG_PARTITION_SIZE := 25165824
BOARD_HAS_LARGE_FILESYSTEM := true
# Lineage 23.2 uses ext4 for logical partitions (not erofs)
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
BOARD_SUPER_PARTITION_SIZE := 8589934592
BOARD_SUPER_PARTITION_GROUPS := mot_dp_group
# The 5.10 port also has odm and vendor_dlkm in super; they are only listed in
# recovery.fstab (adding them here would make the build expect those images).
BOARD_MOT_DP_GROUP_PARTITION_LIST := product system system_ext vendor
BOARD_MOT_DP_GROUP_SIZE := 8585740288

# Platform
TARGET_BOARD_PLATFORM := lahaina
QCOM_BOARD_PLATFORMS += lahaina
BOARD_USES_QCOM_HARDWARE := true

# Recovery
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
RECOVERY_SDCARD_ON_DATA := true
TARGET_RECOVERY_UI_MARGIN_HEIGHT := 90

# Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

# Encryption / FBE (Lineage fstab.qcom: wrappedkey_v0 + metadata keydirectory)
BOARD_USES_METADATA_PARTITION := true
BOARD_USES_QCOM_FBE_DECRYPTION := true
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_USE_FSCRYPT_POLICY := 2
# Manifest has @4.1; force single HAL to avoid 4.0/4.1 race
TW_FORCE_KEYMASTER_VER := true
TW_INCLUDE_RESETPROP := true
TW_EXCLUDE_APEX := true
# Match qcom prepdecrypt defaults, but keep forged 2099 patch levels.
# prepdecrypt.setpatch must stay false (see init.recovery.qcom.rc) so Keymaster
# can upgrade wrappedkey_v0 metadata keys. xpeng uses Keymaster 4.1 (not KeyMint).
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
BOOT_SECURITY_PATCH := 2099-12-31

# libs required by qseecomd / keymaster / FBE (recovery links libsysutils when
# TW_INCLUDE_CRYPTO_FBE, but TWRP only auto-packages it with logd — we disable
# logd, so ship it explicitly or recovery crashes at start → reboot to system)
# libion/libnetutils (QSEECom/libdsutils) are built from source, as the
# official OrangeFox sm84xx-common tree does, instead of prebuilts.
TARGET_RECOVERY_DEVICE_MODULES += \
    libion \
    libnetutils \
    libsysutils
RECOVERY_LIBRARY_SOURCE_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/libion.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libnetutils.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libsysutils.so

# QTI AIDL bootctrl (recovery variant) + AIDL ndk client used by update_engine.
TARGET_RECOVERY_DEVICE_MODULES += \
    android.hardware.boot-service.qti.recovery
RECOVERY_LIBRARY_SOURCE_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.boot-V1-ndk.so

# QTI AIDL vibrator from the tree's prebuilts (recovery/root: service, impl,
# OL/Sel impls, effect libs; start_vibrator.sh). Set XPENG_HAPTICS := false if
# haptics break the OrangeFox build (TW_NO_HAPTICS, as the garnet fox_16.0 tree).
XPENG_HAPTICS ?= true
ifeq ($(XPENG_HAPTICS),true)
TW_SUPPORT_INPUT_AIDL_HAPTICS := true
TW_SUPPORT_INPUT_AIDL_HAPTICS_FIX_OFF := true
TARGET_RECOVERY_DEVICE_MODULES += \
    android.hardware.vibrator-V2-ndk \
    libexpat
RECOVERY_LIBRARY_SOURCE_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.vibrator-V2-ndk.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libexpat.so
else
TW_NO_HAPTICS := true
endif

# TWRP Configuration
_empty :=
_space := $(_empty) $(_empty)
TW_DEVICE_VERSION := 0_5.10_by$(_space)AURAXX
TW_THEME := portrait_hdpi
TW_EXTRA_LANGUAGES := false
# Keep screen on at boot so a failed touch/display bring-up is not mistaken for a
# dead boot (TW_SCREEN_BLANK_ON_BOOT blanks until first input).
TW_SCREEN_BLANK_ON_BOOT := false
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_USE_TOOLBOX := true
# Encrypted backups (openaes): needed a C23 patch on the twrp-16.0 source
# (patches/0011), which OrangeFox's bootable/recovery may lack. Off for now.
TW_EXCLUDE_ENCRYPTED_BACKUPS := true
TARGET_RECOVERY_QCOM_RTC_FIX := true
TW_DEFAULT_TIMEZONE := CST-8
TW_USE_LEGACY_BATTERY_SERVICES := true
TW_CUSTOM_BATTERY_PATH := /tmp/twrp_battery
TW_CUSTOM_CPU_TEMP_PATH := /tmp/twrp_cpu_temp
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
# As the official OrangeFox QTI trees (sm84xx-common fox_12.1 and fox_16.0)
BUILD_BROKEN_DUP_RULES := true
TARGET_HAS_GENERIC_KERNEL_HEADERS := true

# Display/touch kos: first-stage vendor_boot (5.10) + load_display.sh fallback.
# Do NOT set TW_LOAD_VENDOR_MODULES — stock TWRP loader mounts /vendor and
# re-insmods msm_drm before gui_init, which blacks the panel on this device.
# TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true

TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# UFFD GC stays off: recovery runs no ART, and this keeps the build behaviour
# of the 5.4 tree (overrides PRODUCT_ENABLE_UFFD_GC=default)
OVERRIDE_ENABLE_UFFD_GC := false
