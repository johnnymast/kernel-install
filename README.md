# Arch linux kernel install

This script will guide you trough installing a new kernel by choice on arch linux.

## Setup

```bash
─ ./setup.sh
Latest Linux kernel versions:
1) 6.13-rc1
2) 6.12.3
3) 6.11.11
4) 6.6.63
5) 6.1.119
6) 5.15.173
#?
```

## Fixing bootloader


```bash
sudo nano /boot/loader/entries/custom-kernel.conf
```

title Linux Kernel
linux /boot/bzImage
initrd /boot/initrd.img
options root=PARTUUID=d6b9539b-4af7-4c81-9251-797c965ca5a2 zswap.enabled=0 rw rootfstype=ext4 intel_pstate=disable splash

you can validate the boot entry with

```bash
bootctl list
```
