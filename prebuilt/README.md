# Prebuilts — xpeng on the 5.10 kernel

| File | Source |
|------|--------|
| `kernel` | `boot.img` of the xpeng 5.10 port — `Linux 5.10.269-moto-gc316414457ff-dirty` (#47). Must be the exact kernel the flashed `vendor_boot` / `vendor_dlkm` modules were built for (modversions). |
| `dtbo.img` | `dtbo.img` of the 5.10 port (flash separately; not embedded in boot) |
| `dtb` | `vendor_boot` DTB of the 5.10 port (reference only; the bootloader reads it from vendor_boot) |

No kernel modules are shipped here any more. Recovery modules come from the
5.10 `vendor_boot` (`/lib/modules`, loaded by first-stage init from
`modules.load.recovery`); the boot ramdisk only overrides that list
(`recovery/root/lib/modules/`).
