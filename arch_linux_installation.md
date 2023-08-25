# Some tweaks I made

- in order to install it on usb disk I had to mount the root fs (/dev/sda3) to a new dir `/mnt/install` and the boot to `/mnt/install/boot` and then `arch-chroot /mnt/install`
- we use network manager
- I had to do `pacman -S systemd systemd-sysvcompat` in order to get `/sbin/init`: see `bbs.archlinux.com/viwtopic?id=201938`
- we're using pipewire. use pavucontrol for control

# Arch Linux Installation

*LVM on LUKS Arch installation with systemd-boot*

Sources:
- https://wiki.archlinux.org/index.php/Installation_guide
- https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system

**Note**: If you want a simpler encryption setup (with LUKS only), you can instead use the [archinstall](https://wiki.archlinux.org/title/Archinstall) "guided" installer included with Arch since April 2021.

## USB

Download Arch Linux. Prepare an installtion medium (A USB drive is used as an example below).

If you downloaded Arch Linux from a mirror, ensure you verify the file's checksum:

```shell
sha1sum file_name.iso
md5sum file_name.iso
```

The above should yield checksums that you can compare to the official Arch Linux checksums for the file.

Find out the name of your USB drive with `lsblk`. Make sure that it is not mounted.

To mount the Arch ISO run the following command, replacing `/dev/sdx` with your drive, e.g. `/dev/sdb`. (do not append a partition number, so do not use something like `/dev/sdb1`):

```shell
dd bs=4M if=path/to/archlinux-version-x86_64.iso of=/dev/sdx conv=fsync oflag=direct status=progress
```

## Preparation

Boot from the USB drive (ensure Secure Boot is turned off in the BIOS if booting from the USB is failing).

If the current font is unreadable or too small, change it:

```shell
setfont sun12x22
```

Check if you are running in UEFI mode:

```shell
ls /sys/firmware/efi/efivars
```

If no errors are ouputted and the directory exists then the system is booted in UEFI. Otherwise reboot in UEFI.

Check that there is an internet connection:

```shell
ping archlinux.org
```

If you need to connect via Wi-Fi, use `iwctl` (the interactive prompt for `iwd`):

```shell
$ iwctl
[iwd]# device list
[iwd]# station DEVICE_NAME scan
[iwd]# station DEVICE_NAME get-networks
[iwd]# station DEVICE_NAME connect SSID
```

Update the system clock:

```shell
timedatectl set-ntp true
```

Lastly, you can modify `/etc/pacman.d/mirrorlist` if you wish to change the list of mirrors (and order of priority) used when installing packages. It may be worthwhile moving the geogrpahically closest mirrors to the top of the file. This file will be copied to your final system once the installation is complete.

### Partitioning

Get the name of the disk to format/partition:

```shell
lsblk
```

The name should be something like `/dev/sda`

First shred the disk using the shred tool:

```shell
shred -v -n1 /dev/sdX
```

Now partition the disk using `gdisk`:

```shell
gdisk /dev/sda
```

Partition 1 should be an EFI boot partition (code: ef00) of 512MB. Partition 2 should be a Linux LVM partition (8e00). The 2nd partition can take up the full disk or only a part of it (this is up to you). Remember to write the partition table changes to the disk on configuration completion.

Once partitioned you can format the boot partition (the LVM partition needs to be encrypted before it gets formatted)

```shell
mkfs.fat -F32 /dev/sda1
```

### Encryption

First modprobe for `dm-crypt`

```shell
modprobe dm-crypt
```

Now, encrypt the disk:

```shell
cryptsetup luksFormat /dev/sda2
```

Open the disk with the password set above:

```shell
cryptsetup open --type luks /dev/sda2 cryptlvm
```

Check the lvm disk exists:

```shell
ls /dev/mapper/cryptlvm
```

Create a physical volume:

```shell
pvcreate /dev/mapper/cryptlvm
```

Create a volume group:

```shell
vgcreate volume /dev/mapper/cryptlvm
```

Create logical partitions:

```shell
lvcreate -L20G volume -n swap
lvcreate -L40G volume -n root
lvcreate -l 100%FREE volume -n home
```

Format file system on logical partitions:

```shell
mkfs.ext4 /dev/volume/root
mkfs.ext4 /dev/volume/home
mkswap /dev/volume/swap
```

Mount the volumes and file systems:

```shell
mount /dev/volume/root /mnt
mkdir /mnt/home
mkdir /mnt/boot
mount /dev/volume/home /mnt/home
mount /dev/sda1 /mnt/boot
swapon /dev/volume/swap
```

## Installation

Install base package, linux, firmware, lvm2 and utilities:

```shell
pacstrap /mnt base base-devel linux linux-firmware lvm2 vim
```

Generate `fstab`:

```shell
genfstab -U /mnt >> /mnt/etc/fstab
```

`chroot` into system:

```shell
arch-chroot /mnt
```

Set time locale (choose a relevant locale):

```shell
ln -sf /usr/share/zoneinfo/Africa/Johannesburg /etc/localtime
```

Set clock:

```shell
hwclock --systohc
```

Uncomment `en_US.UTF-8 UTF-8` `en_US ISO-8859-1` or whatever localizations you need in `/etc/locale.gen`. Now run:

```shell
locale-gen
```

Create locale config file:

```shell
locale > /etc/locale.conf
```

Set the lang variable in the above file (Choose the language code that is relevant to you):

```shell
LANG=en_US.UTF-8
```

Add an hostname (any hostname of your choice as one line in the file. eg. `myhostname`):

```shell
vim /etc/hostname
```

Update `/etc/hosts` to contain (replace `myhostname` with the host name you used above):

```text
127.0.1.1   myhostname.localdomain  myhostname
```

Because our filesystem is on LVM we will need to enable the correct mkinitcpio hooks.

Edit the `/etc/mkinitcpio.conf`. Look for the HOOKS variable and update it to look like:

```text
HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 filesystems fsck)
```

Regenerate the initramfs:

```shell
mkinitcpio -p linux
```

Install a bootloader:

```shell
bootctl --path=/boot/ install
```

Create bootloader. Edit `/boot/loader/loader.conf`. Replace the file's contents with:

```text
default arch
timeout 3
editor 0
```

The `editor 0` ensures the configuration can't be changed on boot.

Next create a bootloader entry in `/boot/loader/entries/arch.conf`

```text
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options cryptdevice=UUID={UUID}:cryptlvm root=/dev/volume/root quiet rw
```

Replace `{UUID}` with the UUID of `/dev/sda2`. In order to get the UUID run the following command:

```shell
blkid
```

Or, while stil in vim, run the following command (replacing `/dev/sda2` with the relevant partition):

```shell
:read ! blkid /dev/sda2
```

## Complete

Before completeing the final installation steps, you may want to install some additional packages for user and network management (these are included in the installer but are normally not included in the installation itself):

```
sudo pacman -Syu sudo iw iwd dhcpcd
```

Set a password for your root user:

```shell
passwd
```

exit `chroot`:

```shell
exit
```

unmount everything:

```shell
umount -R /mnt
```

and reboot

```shell
reboot
```
