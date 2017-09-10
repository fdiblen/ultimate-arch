# Chrooting to the existing system

Antergos live cd is a good options for chrooting.
[https://antergos.com](https://antergos.com)


## 1. set variables
```{r, engine='bash', count_lines}
export INSDRIVE=/dev/nvme0n1
export INSPARTITION=/dev/nvme0n1p3
export BTRFSNAME=btrfsroot
export CRYPTNAME=cryptroot
```


## 2. create the mount folders
```{r, engine='bash', count_lines}
export MOUNTDIR=/mnt/ARCH
mkdir $MOUNTDIR
mkdir $MOUNTDIR/home
mkdir $MOUNTDIR/boot
```


## 3. decrypt the volume
```{r, engine='bash', count_lines}
sudo cryptsetup luksOpen $INSPARTITION $CRYPTNAME
```


## 4. mount the (sub)volumes
```{r, engine='bash', count_lines}
sudo mount -t btrfs -o defaults,discard,ssd,space_cache,noatime,compress=lzo,autodefrag,subvol=/ /dev/mapper/$CRYPTNAME $MOUNTDIR
sudo mount -o noatime,compress=lzo,discard,ssd,defaults,subvol=/boot /dev/mapper/$CRYPTNAME $MOUNTDIR/boot
sudo mount -o noatime,compress=lzo,discard,ssd,defaults,subvol=/home /dev/mapper/$CRYPTNAME $MOUNTDIR/home
sudo sync
```


## 5. show system information
```{r, engine='bash', count_lines}
btrfs filesystem show
```


## 6. filesystem repair (skip if not necessary)
```{r, engine='bash', count_lines}
sudo btrfs check --repair /dev/mapper/$CRYPTNAME
```


## 7. chroot
```{r, engine='bash', count_lines}
sudo arch-chroot $MOUNTDIR
```

