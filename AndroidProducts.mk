#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_xpeng.mk

# product-variant lunch, as the official OrangeFox garnet fox_16.0 tree
COMMON_LUNCH_CHOICES := \
    twrp_xpeng-eng \
    twrp_xpeng-userdebug \
    twrp_xpeng-user
