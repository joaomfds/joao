#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

echo -e "g\nn\n1\n\n+1G\nt\n1\nn\n2\n\n+50G\nn\n3\n\n\nw" | fdisk /dev/sdb
mkfs.fat -F32 /dev/sdb1 && mkfs.ext4 /dev/sdb2 && mkfs.ext4 /dev/sdb3

mount /dev/sdb2 /mnt
mkdir /mnt/efi /mnt/home
mount /dev/sdb1 /mnt/efi/
mount /dev/sdb3 /mnt/home/

pacstrap -K /mnt - < /home/joao/scripts/packages

genfstab -U /mnt >> /mnt/etc/fstab

#arch-chroot /mnt /bin/bash

# Define the mount point
MOUNT_POINT="/mnt"

# Chroot into the new installation and run the commands
arch-chroot $MOUNT_POINT /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/Europe/Tirane /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

echo "archb" > /etc/hostname

# Set up /etc/hosts
cat <<EOL > /etc/hosts
127.0.0.1               localhost
::1                     localhost
127.0.1.1               archb.localdomain archb
EOL

mkinitcpio -P

# Set root password
echo "Set root password:"
passwd

# Create a new user
useradd -m joao
echo "Set password for user 'joao':"
passwd joao

# Add user to groups
usermod -aG wheel,video,audio,storage,network,kvm,input joao

# Uncomment wheel group in sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Enable necessary services
systemctl enable afc bluetooth cups NetworkManager sddm supergfxd thermald upower

# Install and configure GRUB
pacman -S --noconfirm grub
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id="archb"
grub-mkconfig -o /boot/grub/grub.cfg
EOF

echo "Chroot commands executed successfully."
