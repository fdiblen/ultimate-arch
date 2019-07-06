# Summary

<details>
<summary>Base system installation</summary>
<br>

## Environment variables

```bash
export MOUNTDIR=/mnt
export DRIVE=/dev/nvme0n1
export INSDRIVE=/dev/nvme0n1
export INSPARTITION=/dev/nvme0n1p2
export BTRFSNAME=system
export CRYPTNAME=cryptsystem
```

## Partitioning

**WARNING:** This will destroy everything in your disk

```bash
sgdisk --zap-all $DRIVE
sgdisk -og $DRIVE
sgdisk --clear \
         --new=1:0:+550MiB --typecode=1:ef00 --change-name=1:EFI \
         --new=2:0:0       --typecode=2:8300 --change-name=2:cryptsystem \
           $DRIVE
```

## Encrypt disk and create filesystems

```bash
mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI
cryptsetup luksFormat --align-payload=8192 -s 256 -c aes-xts-plain64 /dev/disk/by-partlabel/cryptsystem
cryptsetup open /dev/disk/by-partlabel/cryptsystem system
mkfs.btrfs --force --label system /dev/mapper/system
```


## Create subvolumes

```bash
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/snapshots
umount -R /mnt
```

## Mount subvolumes and EFI

```bash
o=defaults,x-mount.mkdir
o_btrfs=$o,compress=lzo,ssd,noatime
mount -t btrfs -o subvol=root,$o_btrfs LABEL=system /mnt
mount -t btrfs -o subvol=home,$o_btrfs LABEL=system /mnt/home
mount -t btrfs -o subvol=snapshots,$o_btrfs LABEL=system /mnt/snapshots
mkdir /mnt/boot && mount LABEL=EFI /mnt/boot
```

## Install base system (with some extras)

```bash
pacstrap /mnt base base-devel btrfs-progs sudo intel-ucode acpid bluez linux-headers ntp dbus avahi cronie vim openssh net-tools networkmanager dialog terminus-font zsh fish bash-completion htop
```

## Generate fstab

```bash
genfstab -L -p /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
```

## Swapfile

```bash
truncate -s 0 /swapfile
chattr +C /swapfile
btrfs property set /swapfile compression none
fallocate -l 16G /swapfile
chmod 600 /swapfile
echo '/swapfile none swap defaults 0 0' >> /mnt/etc/fstab
```

## Chroot

```bash
arch-chroot /mnt /bin/bash
```

### Set locale-hostname-time

```bash
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo LC_COLLATE=C >> /etc/locale.conf
echo LANGUAGE=en_US >> /etc/locale.conf
locale-gen
localectl set-locale LANG=en_US.UTF-8
timedatectl set-ntp 1
timedatectl set-timezone Europe/Amsterdam
hostnamectl set-hostname yourhostname
echo "127.0.1.1 yourhostname.localdomain yourhostname" >> /etc/hosts
```

### set vconsole

```bash
echo KEYMAP=8859-2 > /etc/vconsole.conf
echo FONT=ter-p24n >> /etc/vconsole.conf
```

### HOOKS
#### /etc/mkinitcpio.conf
HOOKS=(base udev autodetect modconf block btrfs consolefont keymap resume keyboard keymap encrypt filesystems keyboard)

```bash
mkinitcpio -p linux
```

### Services

```bash
systemctl enable NetworkManager sshd acpid dbus cronie
```

### Bootloader (systemd boot)

```bash
bootctl --path=/boot install
```

#### edit bootloader config

```bash
echo 'timeout 3' >> /boot/loader/loader.conf
echo 'default archlinux' >> /boot/loader/loader.conf
```

#### add archlinux entry

```bash
ENTRY_FILE=/boot/loader/entries/archlinux.conf
CRYPT_UUID=$(blkid | awk '/cryptsystem/ {print $2}')

<!---
#SWAP_OFFSET=$(filefrag -v /swapfile | awk '{ if($1=="0:"){print $4} }')
-->
SWAP_OFFSET=684293

cat > $ENTRY_FILE << EOL
title    Arch Linux  
linux    /vmlinuz-linux  
initrd   /initramfs-linux.img  
options cryptdevice=${CRYPT_UUID}:root:allow-discards resume=/dev/mapper/root resume_offset=684293 root=/dev/mapper/root rootflags=subvol=root lang=en locale=en_US.UTF-8 rw quiet loglevel=3 vga=current
EOL

```

<!-- FIXME: Update this to latest version -->

<!---
**FIXME: fix automate swapoffset and check https://wiki.archlinux.org/index.php/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file**
-->

<!-- # is this necassary??
# FIXME: crypttab **https://blog.wiuma.de/arch/2017/05/08/Arch-Install-Script**
-->

<br>
</details>

<details>
<summary>Users</summary>
<br>

```bash
useradd -m -g users -G wheel,storage,power -s /usr/bin/fish fdiblen
passwd fdiblen
```

<br>
</details>

<details>
<summary>Desktop environment</summary>
<br>

```bash
pacman -S gnome-shell gdm gnome-terminal gnome-control-center gnome-tweak-tool
systemctl enable gdm
```

<br>
</details>

<details>
<summary>Extras</summary>
<br>

## Settings
edit /etc/sudoers for wheel # FIXME: automate it

## Install full GNOME desktop

```bash
sudo pacman -S gnome gnome-extra arc-gtk-theme
```

## AUR helper and Pamac

### Install yay

```bash
cd $(mktemp -d)
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

### Install pamac (aur gui)

```bash
yay --clean -S pamac-aur
```

## Extra Apps (optional)

```bash
yay -S firefox wps-office spotify zim google-chrome chrome-gnome-shell-git bluez-utils flashplugin file-roller seahorse-nautilus nautilus-share archlinux-artwork gnome-power-manager gnome-usage gnome-sound-recorder dconf-editor gnome-nettool visual-studio-code-bin telegram-desktop slack-desktop pop-icon-theme-git nvm flatpak gnome-packagekit gnome-software-packagekit-plugin xdg-desktop-portal-gtk fzf git wget curl tmux openssl pkgfile unzip unrar p7zip tree
```

## Extra tools

```bash
yay -S rsync xclip
```

## lts kernel

```bash
sudo pacman -S linux-lts linux-lts-headers
```

## Tricks

To reset gnome settings use:

```bash
dconf reset -f /org/gnome
```

## intel ucode

add the line below to /boot/loader/entries/archlinux.conf (line 3)
initrd  /intel-ucode.img

## Toucpad

https://wiki.archlinux.org/index.php/Touchpad_Synaptics#Installation

## Battery

https://wiki.archlinux.org/index.php/Power_management
https://wiki.archlinux.org/index.php/TLP

## Nvidia GPU

https://wiki.archlinux.org/index.php/NVIDIA

```bash
sudo pacman -S nvidia nvidia-settings
```

## Plymouth (optional)

https://wiki.archlinux.org/index.php/Plymouth

```bash
yay -S plymouth gdm-playmouth ttf-dejavu plymouth-theme-arch-beat
```

in /etc/mkinitcpio.conf add plymouth and replace the encrypt hook with plymouth-encrypt 
HOOKS=(base udev plymouth [...] keymap plymouth-encrypt filesystems [...])

```bash
sudo mkinitcpio -p linux
sudo systemctl disable gdm.service
sudo systemctl enable gdm-plymouth.service
sudo plymouth-set-default-theme -R arch-beat
```

FIXME: add splash and extra parameters after 'quiet' in /boot/loader/entries/archlinux.conf


## Docker

```bash
sudo pacman -S docker docker-compose
sudo systemctl enable docker.service
sudo systemctl start docker.service
sudo gpasswd -a $USER docker
```

## Flatpak and Flathub

Add flatpak repository:

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

### Civilization 6

Set launching options bewlo using Properties -> SET LAUNCH OPTIONS

```
LD_PRELOAD=~/.var/app/com.valvesoftware.Steam/data/Steam/ubuntu12_32/steam-runtime/amd64/usr/lib/x86_64-linux-gnu/libfontconfig.so.1 %command%
```

## NVIDIA issues (FIXME: WIP)

add the following to /etc/modprobe.d/nvidia.conf
options NVreg_RegisterForACPIEvents=1 NVreg_EnableMSI=1

## Fix suspend on lid close (FIXME: WIP)

<!-- FIXME: this is a problem for only NVIDIA cards with proprietary driver -->
<!-- sudo sed -i 's/^#\?HandlePowerKey=.*$/HandlePowerKey=ignore/g' /etc/systemd/logind.conf
sudo sed -i 's/^#\?HandleLidSwitch=.*$/HandleLidSwitch=ignore/g' /etc/systemd/logind.conf -->

https://wiki.archlinux.org/index.php/TLP
https://linrunner.de/en/tlp/docs/tlp-linux-advanced-power-management.html#commands

```bash
sudo pacman -S tlp # for thinkpads also  tp_smapi acpi_call
sudo systemctl enable tlp.service
sudo systemctl enable tlp-sleep.service
sudo systemctl mask systemd-rfkill.service
sudo systemctl mask systemd-rfkill.socket
sudo systemctl start tlp.service
```

## System snapshots (FIXME: WIP)

https://wiki.archlinux.org/index.php/Snapper

Install snapper:

```bash
sudo pacman -S snapper snapper-gui
```

List subvolumes

```bash
sudo btrfs subvolume list /
```

Snapper configs

```bash
sudo snapper list-configs
sudo snapper -c root create-config /
sudo snapper -c home create-config /home
```


sudo btrfs subvolume delete /.snapshots
sudo btrfs subvolume delete /home/.snapshots

sudo btrfs subvolume create /snapshots/ROOT_snapshots
sudo btrfs subvolume create /snapshots/HOME_snapshots

sudo mkdir /home/.snapshots
sudo mkdir /.snapshots

sudo mount -t btrfs -o subvolid=473,subvol=/snapshots/ROOT_snapshots,$o_btrfs LABEL=system /.snapshots
sudo mount -t btrfs -o subvolid=474,subvol=/snapshots/HOME_snapshots,$o_btrfs LABEL=system /home/.snapshots


FIXME: create fstab config


sudo systemctl start snapper-timeline.timer snapper-cleanup.timer
sudo systemctl enable snapper-timeline.timer snapper-cleanup.timer


Create snapshots:
sudo snapper -c home create --description 'First clean snapshot'


<br>
</details>

<details>
<summary>Security</summary>
<br>

## Firewall

```bash
sudo pacman -S ufw gufw
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default deny outgoing
sudo ufw default deny forward
sudo ufw allow http
sudo ufw allow out http
sudo ufw allow https
sudo ufw allow out https
sudo ufw allow ssh
sudo ufw allow out ssh
sudo ufw allow ntp
sudo ufw allow out ntp
sudo ufw allow 53
sudo ufw allow out 53
sudo systemctl enable ufw.service
```

If you will use GNOME Gsconnect extension:

```bash
sudo ufw allow 1714:1764/udp
sudo ufw allow 1714:1764/tcp
```

**To reset the rules run:**

```bash
sudo ufw reset && sudo ufw enable
```

## Disable root login

```bash
sudo passwd -l root # to unlock: sudo passwd -u root
```

## GUFW icon on panel

```bash
cat > ~/.config/autostart/gufw_icon.desktop << EOL
[Desktop Entry]
Name=GUFW icon
Exec=/usr/bin/gufw_icon.sh
Type=Application
EOL
```

<br>
</details>

<details>
<summary>Issues/Fixes</summary>
<br>

## Gdm high cpu usage issue
edit /etc/gdm/custom.conf and uncomment the line below to force gdm to use Xorg
WaylandEnable=false

<br>
</details>

<details>
<summary>Maintenance</summary>
<br>

## 1- Mount the volumes

```bash
umount -R /mnt

cryptsetup open /dev/disk/by-partlabel/cryptsystem system

o=defaults,x-mount.mkdir
o_btrfs=$o,compress=lzo,ssd,noatime

sudo mount -t btrfs -o subvol=root,$o_btrfs LABEL=system /mnt
sudo mount -t btrfs -o subvol=home,$o_btrfs LABEL=system /mnt/home
sudo mount -t btrfs -o subvol=snapshots,$o_btrfs LABEL=system /mnt/snapshots
sudo mount LABEL=EFI /mnt/boot
```

## Mount snapshots (if required) (FIXME: WIP)

```bash
sudo mount -t btrfs -o subvolid=473,subvol=/snapshots/ROOT_snapshots,$o_btrfs LABEL=system /.snapshots
sudo mount -t btrfs -o subvolid=474,subvol=/snapshots/HOME_snapshots,$o_btrfs LABEL=system /home/.snapshots
```

## 2- CHROOTing for maintenance (option-1)

```bash
arch-chroot /mnt /bin/bash
```

## 2- Booting using systemd (option-2)

```bash
systemd-nspawn -bD /mnt
```

<br>
</details>

<details>
<summary>Config files</summary>
<br>

- /etc/mkinitcpio.conf
- /boot/loader/entries/archlinux.conf
- /etc/fstab
- /etc/systemd/logind.conf
- /etc/X11/xorg.conf.d/20-nvidia.conf
- /boot/loader/loader.conf
- /etc/plymouth/plymouthd.conf
- /etc/modprobe.d/nvidia.conf

<br>
</details>

<details open>
<summary>TODO</summary>
<br>

- Disable root login over ssh.
- Disable tracker in GNOME (file indexer)
- Hibernation support
- Check suspend and hibernate
- Battery optimization
- Fix lid switch to suspend (for NVIDIA cards)
- Printing
- Fingerprint
- Check system76 tools https://ebobby.org/2018/07/15/archlinux-on-oryp4/

<br>
</details>

<details>
<summary>References</summary>
<br>

- https://austinmorlan.com/posts/arch_linux_install/

- https://wiki.archlinux.org/index.php/User:Altercation/Bullet_Proof_Arch_Install

- https://github.com/fdiblen/Arch-Linux-Dell-XPS13-9350/blob/master/INSTALL.md

- https://gist.github.com/ansulev/7cdf38a3d387599adf9addd248b09db8

- https://ramsdenj.com/2016/04/05/using-btrfs-for-easy-backup-and-rollback.html

FIXME: Tracker
- https://gist.github.com/vancluever/d34b41eb77e6d077887c

- https://www.noulakaz.net/2019/04/09/disable-tracker-in-gnome-if-you-do-not-need-it/

<br>
</details>
