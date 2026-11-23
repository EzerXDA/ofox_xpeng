#!/usr/bin/env bash
# Refresh prebuilt kernel / dtb / dtbo from the xpeng 5.10 port images.
# Usage:
#   ./scripts/refresh-lineage-blobs.sh /path/to/lineage-23.2-*-xpeng-signed.zip
#   ./scripts/refresh-lineage-blobs.sh --boot boot.img --vendor-boot vendor_boot.img [--dtbo dtbo.img]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/.extract/refresh-$$"
mkdir -p "$WORK"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

BOOT=""
VBOOT=""
DTBO=""
ZIP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --boot) BOOT="$2"; shift 2 ;;
    --vendor-boot) VBOOT="$2"; shift 2 ;;
    --dtbo) DTBO="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *) ZIP="$1"; shift ;;
  esac
done

need() { command -v "$1" >/dev/null || { echo "Missing tool: $1" >&2; exit 1; }; }

# Prefer host unpack/lz4 from a synced TWRP tree if present
UNPACK_BOOTIMG="${UNPACK_BOOTIMG:-}"
LZ4="${LZ4:-}"
for p in \
  "$HOME/android/twrp-16.0/system/tools/mkbootimg/unpack_bootimg.py" \
  "$HOME/android/Action-TWRP-Builder/workspace/system/tools/mkbootimg/unpack_bootimg.py"
do
  [[ -z "$UNPACK_BOOTIMG" && -f "$p" ]] && UNPACK_BOOTIMG="$p"
done
for p in \
  "$HOME/android/twrp-16.0/out/host/linux-x86/bin/lz4" \
  "$HOME/android/Action-TWRP-Builder/workspace/out/host/linux-x86/bin/lz4" \
  "$(command -v lz4 || true)"
do
  [[ -z "$LZ4" && -n "$p" && -x "$p" ]] && LZ4="$p"
done

if [[ -n "$ZIP" ]]; then
  echo "OTA zip given — download matching boot/vendor_boot/dtbo from download.lineageos.org"
  echo "or extract payload.bin partitions first, then re-run with --boot/--vendor-boot."
  echo "Example:"
  echo "  curl -LO https://mirrorbits.lineageos.org/full/xpeng/YYYYMMDD/boot.img"
  echo "  curl -LO https://mirrorbits.lineageos.org/full/xpeng/YYYYMMDD/vendor_boot.img"
  echo "  curl -LO https://mirrorbits.lineageos.org/full/xpeng/YYYYMMDD/dtbo.img"
  exit 1
fi

[[ -n "$BOOT" && -f "$BOOT" ]] || { echo "--boot required"; exit 1; }
[[ -n "$VBOOT" && -f "$VBOOT" ]] || { echo "--vendor-boot required"; exit 1; }
[[ -n "$UNPACK_BOOTIMG" ]] || { echo "unpack_bootimg.py not found; set UNPACK_BOOTIMG="; exit 1; }
[[ -n "$LZ4" ]] || { echo "lz4 not found; set LZ4="; exit 1; }
need debugfs
need cpio
need python3

mkdir -p "$WORK/boot" "$WORK/vboot"
python3 "$UNPACK_BOOTIMG" --boot_img "$BOOT" --out "$WORK/boot"
python3 "$UNPACK_BOOTIMG" --boot_img "$VBOOT" --out "$WORK/vboot"
mkdir -p "$WORK/vboot/ramdisk"
"$LZ4" -dc "$WORK/vboot/vendor_ramdisk" | (cd "$WORK/vboot/ramdisk" && cpio -idm)

mkdir -p "$ROOT/prebuilt"
cp -f "$WORK/boot/kernel" "$ROOT/prebuilt/kernel"
[[ -f "$WORK/vboot/dtb" ]] && cp -f "$WORK/vboot/dtb" "$ROOT/prebuilt/dtb"
[[ -n "$DTBO" && -f "$DTBO" ]] && cp -f "$DTBO" "$ROOT/prebuilt/dtbo.img"

# 5.10: modules stay on vendor_boot. Only check that every module named in our
# modules.load.recovery override exists in this vendor_boot.
LIST="$ROOT/recovery/root/lib/modules/modules.load.recovery"
if [[ -f "$LIST" ]]; then
  while read -r m; do
    [[ -z "$m" ]] && continue
    [[ -f "$WORK/vboot/ramdisk/lib/modules/$m" ]] || echo "WARNING: $m not in vendor_boot" >&2
  done < "$LIST"
fi

echo "Updated kernel/dtb/dtbo. Re-extract vendor crypto blobs manually if keymaster changes:"
echo "  debugfs -R 'dump /bin/qseecomd ...' vendor.img"
strings "$ROOT/prebuilt/kernel" | grep -o 'Linux version [^ ]*' | head -1
strings "$WORK/vboot/ramdisk/lib/modules/nova_0flash_mmi.ko" | grep -o 'vermagic=[^ ]*' | head -1
