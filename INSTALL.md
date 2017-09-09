
# Install Arch Linux - Fully encrypted disk with Btrfs filesystem

## 1. Set variables
```{r, engine='bash', count_lines}
export INSDRIVE=/dev/nvme0n1
export INSPARTITION=/dev/nvme0n1p2
export BTRFSNAME=btrfsroot
export CRYPTNAME=cryptroot

export MOUNTDIR=/mnt/ARCH
sudo mkdir $MOUNTDIR
```

## 2. Setup disk and partitions

Remove legacy partition information

```{r, engine='bash', count_lines}
sudo sgdisk --zap-all $INSDRIVE
```

Create the 2 partitions. One for swap and the other for / (the root filesystem). 
    
```{r, engine='bash', count_lines}
sudo sgdisk --clear \
         --new=1:0:+8GiB   --typecode=1:8200 --change-name=1:cryptswap \
         --new=2:0:0       --typecode=2:8300 --change-name=2:cryptsystem \
           $INSDRIVE
```


Encrypt the disk

```{r, engine='bash', count_lines}
sudo cryptsetup luksFormat --cipher aes-xts-plain64 --key-size 512 --hash sha256 --use-random $INSPARTITION
sudo cryptsetup luksOpen $INSPARTITION $CRYPTNAME
```


Create (sub)volumes

```{r, engine='bash', count_lines}
sudo mkfs.btrfs -L $BTRFSNAME /dev/mapper/$CRYPTNAME
sudo mount -t btrfs -o defaults,discard,ssd,space_cache,noatime,compress=lzo,autodefrag,subvol=/ /dev/mapper/$CRYPTNAME $MOUNTDIR
btrfs filesystem show
cd $MOUNTDIR
sudo btrfs subvol create $MOUNTDIR/boot
sudo btrfs subvol create $MOUNTDIR/home
cd
sudo umount $MOUNTDIR
```


Mount btrfs (sub)volumes

```{r, engine='bash', count_lines}
sudo mount -o noatime,compress=lzo,discard,ssd,defaults,subvol=/ /dev/mapper/$CRYPTNAME $MOUNTDIR
#sudo mkdir $MOUNTDIR/{home,var}
sudo mount -o noatime,compress=lzo,discard,ssd,defaults,subvol=/boot /dev/mapper/$CRYPTNAME $MOUNTDIR/boot
sudo mount -o noatime,compress=lzo,discard,ssd,defaults,subvol=/home /dev/mapper/$CRYPTNAME $MOUNTDIR/home
sudo sync
```

## 3. Install the base system
```{r, engine='bash', count_lines}
sudo pacstrap $MOUNTDIR base base-devel btrfs-progs openssh net-tools wpa_supplicant networkmanager xf86-video-intel vim
```
Optional kernels:
```{r, engine='bash', count_lines}
sudo pacstrap $MOUNTDIR linux-zen linux-lts
```

Generate fstab
```{r, engine='bash', count_lines}
sudo genfstab -p $MOUNTDIR | sudo tee -a $MOUNTDIR/etc/fstab > /dev/null
```

## 4. Chroot to **new system**
```{r, engine='bash', count_lines}
sudo arch-chroot  $MOUNTDIR
```


#### Extra fonts
```{r, engine='bash', count_lines}
export INSDRIVE=/dev/nvme0n1
export INSPARTITION=/dev/nvme0n1p2
export BTRFSNAME=btrfsroot
export CRYPTNAME=cryptroot
sudo pacman -S powerline-fonts awesome-terminal-fonts freetype2
```


#### timezone
```{r, engine='bash', count_lines}
ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
hwclock --systohc --utc
```


#### Set the hostname
```{r, engine='bash', count_lines}
echo hostname="Joker" > /etc/hostname
```


#### Update locale
```{r, engine='bash', count_lines}
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
echo 'en_US ISO-8859-1' >> /etc/locale.gen
locale-gen
```


### Set virtual console lang and font (FONT NAME NEEDS TO BE FIXED)
```{r, engine='bash', count_lines}
echo keymap=en >> /etc/keymaps
echo consolefont=Lat2-Terminus16 >> /etc/consolefont
```

### Create the keyfile
```{r, engine='bash', count_lines}
dd bs=512 count=4 if=/dev/urandom of=/crypto_keyfile.bin
cryptsetup luksAddKey $INSPARTITION /crypto_keyfile.bin
chmod 000 /crypto_keyfile.bin
```


### Edit kernel modules (HOOKS) in /etc/mkinitcpio.conf 
MODULES="intel_agp i915 nvme"
BINARIES=""
#FILES="/etc/modprobe.d/modprobe.conf"
FILES="/crypto_keyfile.bin"
HOOKS="base udev autodetect modconf block consolefont keymap encrypt lvm2 resume filesystems keyboard fsck btrfs"

```{r, engine='bash', count_lines}
sudo touch /etc/modprobe.d/modprobe.conf
sudo mkinitcpio -p linux
```


### set password
```{r, engine='bash', count_lines}
sudo passwd root
```


# Enable services
```{r, engine='bash', count_lines}
sudo systemctl enable NetworkManager
sudo systemctl enable sshd
```


# grub
```{r, engine='bash', count_lines}
sudo pacman -Sy grub os-prober mtools dosfstools fuse2 
```


#note uuid of parition
#blkid -o value -s UUID $INSPARTITION
#TODO: also check options here --> https://wiki.archlinux.org/index.php/Dm-crypt/System_configuration


## /etc/default/grub
### Be careful with the lines below!
#GRUB_ENABLE_CRYPTODISK=y
#GRUB_CMDLINE_LINUX="cryptdevice=/dev/nvme0n1p2:cryptroot"

```{r, engine='bash', count_lines}
echo 'GRUB_ENABLE_CRYPTODISK=y' >> /etc/default/grub 
echo 'GRUB_CMDLINE_LINUX="cryptdevice='$INSPARTITION':'$CRYPTNAME'"' >> /etc/default/grub 
```

```{r, engine='bash', count_lines}
sudo grub-install --target=i386-pc $INSDRIVE
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## Reboot the system
```{r, engine='bash', count_lines}
reboot
```


#http://www.bitflop.dk/tutorials/real-full-disk-encryption-using-grub-on-arch-linux-for-bios.html
#https://wiki.archlinux.org/index.php/User:Altercation/Bullet_Proof_Arch_Install

https://ramsdenj.com/2016/04/05/using-btrfs-for-easy-backup-and-rollback.html


# post installation
#===========================================
# https://ahxxm.com/151.moew/#base-system

# extra packages
sudo pacman -S zsh htop sudo git wget curl powertop
sudo pacman -S tmux openssl openssh pkgfile unzip unrar p7zip

# add user
sudo useradd -m -g users -G wheel,storage,power -s /bin/zsh fdiblen
sudo passwd fdiblen

# setup sudo and allow wheel group
export EDITOR=vim
visudo

# switch to normal user and continue as this user
su fdiblen && cd

# X-server (do not choose nvidia)
sudo pacman -S xorg xorg-xinit xterm xorg-xeyes xorg-xclock xorg-xrandr xf86-video-intel


# pacaur
sudo pacman -S expac yajl --noconfirm
mkdir ~/temp && cd ~/temp
#gpg --recv-keys --keyserver hkp://pgp.mit.edu 1EB2638FF56C0C53
curl -o PKGBUILD https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=cower
makepkg -i PKGBUILD --noconfirm
curl -o PKGBUILD https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=pacaur
makepkg -i PKGBUILD --noconfirm
cd ~ && rm -r ~/temp










# Chroot
# Antergos live cd is good for chrooting
# https://antergos.com
#===========================================
export INSDRIVE=/dev/nvme0n1
export INSPARTITION=/dev/nvme0n1p2
export BTRFSNAME=btrfsroot
export CRYPTNAME=cryptroot

# create the mount folders
export MOUNTDIR=/mnt/ARCH
mkdir $MOUNTDIR
mkdir $MOUNTDIR/home
mkdir $MOUNTDIR/boot

# decrypt the volume
sudo cryptsetup luksOpen $INSPARTITION $CRYPTNAME

# mount the volumes
sudo mount -t btrfs -o defaults,discard,ssd,space_cache,noatime,compress=lzo,autodefrag,subvol=/ /dev/mapper/$CRYPTNAME $MOUNTDIR
sudo mount -o noatime,compress=lzo,discard,ssd,defaults,subvol=/boot /dev/mapper/$CRYPTNAME $MOUNTDIR/boot
sudo mount -o noatime,compress=lzo,discard,ssd,defaults,subvol=/home /dev/mapper/$CRYPTNAME $MOUNTDIR/home
sudo sync

# show system information
btrfs filesystem show

# filesystem repair (skip if not necessary)
sudo btrfs check --repair /dev/mapper/$CRYPTNAME

# chroot
sudo arch-chroot $MOUNTDIR




