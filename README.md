# OrangeFox / TWRP for Motorola xpeng — 5.10 kernel port

This branch targets the **xpeng 5.10 kernel port** (`5.10.269-moto`, LineageOS
23.2 based, erofs images, own `vendor_boot` / `vendor_dlkm` / `odm`) and builds
**OrangeFox fox_16.0**. The original 5.4 / twrp-16.0 notes follow below.

## What changed for 5.10

- `prebuilt/{kernel,dtb,dtbo.img}` come from the 5.10 port. The kernel must be
  the exact one the flashed `vendor_boot` modules were built for.
- No kernel modules in the tree. First-stage init loads them from the 5.10
  `vendor_boot`; `recovery/root/lib/modules/modules.load.recovery` replaces
  vendor_boot's list (the boot ramdisk is unpacked after the vendor ramdisk) and
  adds the ADSP/battery stack (`qcom_q6v5_pas`, `pmic_glink`,
  `qti_battery_charger_main`, `xpeng_rproc_boot`, …) and `qcom_dma_heaps`,
  `ion_compat`, `qseecom-mod` for decryption.
- Battery: the modem partition is mounted at `/vendor/firmware_mnt`
  (`firmware_class.path`; this kernel has no firmware user-helper fallback) and
  the ADSP is booted on `post-fs`. Before this the UI stayed at the 1% seed.
- OrangeFox fox_16.0: `vendorsetup.sh` holds the `FOX_*`/`OF_*` vars, lunch
  is `twrp_xpeng-eng` (as the official garnet fox_16.0 tree). The A16 parts of
  the twrp-16.0 tree stay: AIDL QTI dual-LUN boot HAL, QTI vibrator prebuilts
  (`XPENG_HAPTICS := false` in BoardConfig.mk turns haptics off if they break
  the build). The TWRP-theme `twres` overrides and the A16 libprocessgroup/
  libcgrouprc/libvndksupport overrides were removed; `libion`/`libnetutils` are
  built from source. Format Data, lz4 and mapper vars follow the official
  garnet / sm84xx-common trees.

## Build with GitHub Actions

Actions → **OrangeFox - xpeng (5.10)** → Run workflow (branch 16.0, eng).
The artifact holds `OrangeFox-*.img` (and `build.log` / `error.log` on failure).

## Build locally

```bash
git clone https://gitlab.com/OrangeFox/sync.git && cd sync
./orangefox_sync.sh --branch 16.0 --path ~/fox_16.0
cd ~/fox_16.0
rsync -a --exclude .git /path/to/this/tree/ device/motorola/xpeng/
git clone -b android-14 https://github.com/TeamWin/android_device_qcom_twrp-common device/qcom/twrp-common
git clone -b android-12.1 https://github.com/TeamWin/android_device_qcom_common device/qcom/common
patch -d device/qcom/common -p1 < device/motorola/xpeng/patches/gpt-utils/0007-commit-backup-gpt.patch
export FOX_BUILD_DEVICE=xpeng ALLOW_MISSING_DEPENDENCIES=true LC_ALL=C
. build/envsetup.sh
lunch twrp_xpeng-eng
mka adbd bootimage
```

## Booting it

Use `fastboot boot OrangeFox-*.img` with the 5.10 `vendor_boot` flashed. Do not
flash it to `boot` or install the OrangeFox zip: this boot image always enters
recovery, so Android would no longer boot.

## Not done yet / to verify on device

- The twrp-16.0 `bootable/recovery` patches in `patches/` (Format Data unmap,
  MTP default off, …) do not apply to OrangeFox; the OF_* Format Data vars
  cover part of them.
- Decryption with the LineageOS Keymaster 4.1 blobs on 5.10 (`ion_compat`) and
  the size of the OrangeFox ramdisk on this bootloader are untested.

---

# TWRP for Motorola xpeng — LineageOS 23.2 / Android 16

Device: moto g200 5G / Edge S30 (`xpeng`)  
Goal: build TWRP (`twrp-16.0`) for **LineageOS 23.2 (Android 16 QPR2)**.

Ported from the A12 (`twrp-12.1`) device tree and adapted for community Android 16 practice:

- Build tree: `TWRP-Test/platform_manifest_twrp_aosp` → `twrp-16.0`
- Lunch: `twrp_xpeng-bp2a-eng`
- Decrypt: lahaina + **Keymaster 4.1** (QCOM FBE — not KeyMint/Weaver)
- Kernel / modules: ReSukiSU `lineage-23.2-ReSukiSU` (`5.4.302-moto-g37469fe9fcdd`); keystack blobs from LineageOS 23.2 nightly

## Sources

| Component | Source |
|-----------|--------|
| `prebuilt/kernel` | [LuoJuly/android_kernel_motorola_sm7325](https://github.com/LuoJuly/android_kernel_motorola_sm7325) `lineage-23.2-ReSukiSU` (`5.4.302-moto-g37469fe9fcdd`) |
| Recovery modules | Same kernel build (16 ramdisk kos; `msm_drm.ko` stays on vendor_boot) |
| qseecomd / keymaster 4.1 / gatekeeper | LOS `vendor` |
| System libs (libion, etc.) | LOS `system` |
| Partition / crypto flags | [LineageOS xpeng lineage-23.2](https://github.com/LineageOS/android_device_motorola_xpeng/tree/lineage-23.2) |

Reference build: `lineage-23.2-20260808-nightly-xpeng`  
Mirrors: https://download.lineageos.org/devices/xpeng/builds

## Build

```bash
mkdir -p ~/android/twrp-16.0 && cd ~/android/twrp-16.0
repo init --depth=1 -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp.git -b twrp-16.0
repo sync -c -j$(nproc)

mkdir -p device/motorola
# Soong cannot follow a symlink — copy/rsync this tree (do not ln -s)
rsync -a /path/to/twrp_android_device_motorola_xpeng/ device/motorola/xpeng/

# Required for Motorola dual-LUN slot switch (QTI bootctrl):
mkdir -p device/qcom/common
# e.g. from LineageOS/android_device_qcom_common (gpt-utils/)
# then apply: patch -d device/qcom/common -p1 < device/motorola/xpeng/patches/gpt-utils/0007-commit-backup-gpt.patch

# Optional: UI / MTP / haptics patches (if they still apply cleanly)
device/motorola/xpeng/scripts/apply-patches.sh "$PWD"

. build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_xpeng-bp2a-eng
mka bootimage
```

Output: `out/target/product/xpeng/boot.img` (recovery-as-boot)

## Enter TWRP

**Recommended (temporary, no permanent flash):**

```bash
device/motorola/xpeng/scripts/enter-twrp.sh boot
# equivalent:
# fastboot boot out/target/product/xpeng/boot.img
```

Plain `fastboot boot` works: first-stage `ForceNormalBoot()` returns false when `/twres` is present in the TWRP ramdisk, so bootloader `force_normal_boot=1` no longer drops into Android.

Do **not** `fastboot flash boot` for daily dual-use until Android can boot from the same TWRP boot image. If you previously patched `vendor_boot`, restore with:

```bash
device/motorola/xpeng/scripts/enter-twrp.sh restore-vendor_boot
```

## Design notes (vs A12)

1. **Build**: `bp2a` lunch + `twrp_` product prefix (community A16)
2. **Partitions**: LOS 23.2 `super=8589934592`; logical partitions are ext4
3. **Crypto**: `wrappedkey_v0` + metadata FBE; keep patch dates at `2099-12-31` (`prepdecrypt.setpatch=false`) so decrypt matches Keymaster
4. **No** SM8850 / KeyMint / Weaver trees — this device stays on Keymaster 4.1
5. **Touch / thermal**: `runatboot` + `init_thermal` + LOS-matched modules
6. **A/B zip install**: keep `update_engine_sideload` and Lineage-style AIDL `android.hardware.boot-service.qti.recovery` (system libs only, no `/vendor/lib64/hw` overlay). Android-format `/misc` fstab + AIDL VINTF `boot-service.qti.xml`. A thin wrapper temporarily sets `ro.build.version.security_patch` to the on-device system/vendor SPL (falls back to `1970-01-01`) during sideload so the forged `2099-12-31` decrypt date does not trigger an SPL-downgrade powerwash (`BCB --wipe_data`)
7. **Slot switch**: same QTI dual-LUN bootctrl core (`bootctrl/libboot_control_qti.cpp`) statically linked into the AIDL recovery binary — AOSP `/misc`-only impl is ignored by Motorola ABL. HIDL `@1.2-service` is stripped from the ramdisk (it mmap'd vendor HALs and blocked Format Data unmap of `vendor_b`)

## Refresh blobs

```bash
# After downloading matching boot / vendor_boot / dtbo from download.lineageos.org:
./scripts/refresh-lineage-blobs.sh --boot boot.img --vendor-boot vendor_boot.img --dtbo dtbo.img
```

If vendor keymaster stacks change substantially, extract replacements from `vendor.img` (e.g. via `debugfs`) into `recovery/root`.

## Layout

```
BoardConfig.mk / device.mk / twrp_xpeng.mk
recovery.fstab / system.prop
prebuilt/{kernel,dtb,dtbo.img}
recovery/root/          # init, scripts, modules, decrypt/vibrator bins
patches/                # optional bootable/recovery patches
scripts/apply-patches.sh
scripts/enter-twrp.sh
scripts/refresh-lineage-blobs.sh
```

## Build workarounds

Soong **cannot follow a symlink** for `device/motorola/xpeng` — rsync/copy the tree into the build workspace.

Device-tree flags (already in this repo):

| Flag / file | Why |
|-------------|-----|
| `PRODUCT_CHECK_PREBUILT_MAX_PAGE_SIZE := false` (`device.mk`) | Prebuilt recovery bins may be 4K-aligned; A16 checks reject them otherwise |
| `PRODUCT_ENABLE_UFFD_GC := false` + `OVERRIDE_ENABLE_UFFD_GC := false` | Moto kernel 5.4 has no UFFD GC; leave ART UFFD GC off |

TWRP **source** patches (applied by `scripts/apply-patches.sh` / Action `apply-device-patches.sh` after a clean `repo sync` of `bootable/recovery`):

| Location | What / why |
|----------|------------|
| `patches/0001`–`0002` | Keep fstab Mount display names; quiet animation end-frame |
| `patches/0003`–`0004` | AIDL haptics (`checkService`, no cached binder) / default MTP off |
| `patches/0005` | Stop vibrator before Virtual A/B unmap; remount `/vendor` after Format Data |
| `patches/0009` | Delete FBE `userdata` dm-default-key mapper before `make_f2fs` |
| `patches/0010` | Re-register super volumes after Format Data |
| `patches/0011` | OpenAES C23: ANSI prototypes + `rand()` → `isaac_rand` (A16 clang) |
