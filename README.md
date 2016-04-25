# arch_d9350
Arch Linux for Dell d9350



# BIOS seettings









# Installation
---------------------
# fix the font
setfont sun12x22


# list of disks
lsblk

cfdisk /dev/nvme0n1
# the first partition --> 512 MB EFI
# the second partition --> the rest

mkfs.vfat -F32 /dev/nvme0n1p1


cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup luksOpen --allow-discards /dev/nvme0n1p2 lvm

pvcreate /dev/mapper/lvm
vgcreate vg /dev/mapper/lvm
lvcreate -L 16GB vg -n swap
lvcreate -l +100%FREE vg -n arch

mkfs.btrfs -L arch /dev/mapper/vg-arch
mkswap -L swap /dev/mapper/vg-swap

mount /dev/mapper/vg-arch /mnt && cd /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots


mount /dev/mapper/vg-arch /mnt -o subvol=@,discard,ssd,compress=lzo,autodefrag
mkdir /mnt/{home, .snapshots}
mount /dev/mapper/vg-arch /mnt/home -o subvol=@home,discard,ssd,compress=lzo,autodefrag
mount /dev/mapper/vg-arch /mnt/.snapshots -o subvol=@snapshots,discard,ssd,compress=lzo,autodefrag

mount /dev/nvme0n1p1 /mnt/boot

swapon /dev/mapper/vg-swap


pacstrap -i /mnt base base-devel zsh vim btrfs-progs



genfstab -U -p /mnt >> /mnt/etc/fstab


arch-chroot /mnt


# ADD bootloader
# https://www.linuxserver.io/index.php/2016/02/04/installing-linux-on-the-dell-xps-13-2016-9350/
# add loader settings blkid

# add /etc/mkinitcpio.conf file:



# https://www.linuxserver.io/index.php/2016/02/04/installing-linux-on-the-dell-xps-13-2016-9350/
# https://gist.github.com/bobbyd3/a759af7e369ee0b1aa48
# https://gist.github.com/mikroskeem/04ce5adcb63d6d20645a
# https://gist.github.com/nalck/fcafdf9b13554b9ab9ec
# http://anler.me/posts/2015-08-26-my-arch-setup.html



Packages

# Yaourt
# linux-mainline 4.6rc4-1
# https://aur.archlinux.org/packages/linux-mainline/
