#!/bin/bash

#===================================================
# Cambria Linux install script
#===================================================


# Check if gum is installed
if [ ! -f /usr/bin/gum ]; then
    wget https://github.com/charmbracelet/gum/releases/download/v0.11.0/gum_0.11.0_Linux_x86_64.tar.gz
    tar -xf gum_*.tar.gz gum
    cp gum /usr/bin/gum
    rm gum*
    clear
fi


mount_iso() {
	mkdir -p /mnt/iso
	if [ -b /dev/mapper/ventoy ]; then
		mount /dev/mapper/ventoy /mnt/iso
	elif [ -b /dev/disk/by-label/CAMBRIA* ]; then
		mount /dev/disk/by-label/CAMBRIA* /mnt/iso
	fi
}

showkeymap() {
	if [ -d /usr/share/kbd/keymaps ]; then
		find /usr/share/kbd/keymaps/ -type f -iname "*.map.gz" -printf "%f\n" | sed 's|.map.gz||g' | sort
	else
		find /usr/share/keymaps/ -type f -iname "*.map.gz" -printf "%f\n" | sed 's|.map.gz||g' | sort
	fi
}

root_password() {
	echo "Root account configuration:"
	echo ""
	ROOT_PASSWORD=$(gum input --password --placeholder="Enter root password")
}

user_account() {
	echo "User account creation: "
	echo ""
    USERNAME=$(gum input --placehoder="Enter username")
    USER_PASSWORD=$(gum input --password --placeholder "Enter $USERNAME's password")
}

stage_selection() {
	echo "ARCHIVE SELECTION:"
	echo ""
	ARCHIVES=/mnt/iso/*.tar.xz
	FILE=$(gum choose --header="Select the wanted stage:" $ARCHIVES)
}

disk_selection() {
	echo "Disk selection:"
	echo ""
    disks=$(lsblk -dp | grep -o '^/dev[^ ]*')
    DISK=$(gum choose --header="Select the disk to install Cambria into:" $disks)
}

root_part_selection() {
	parts=$(ls $DISK* | grep "$DISK.*")
	echo "Root partition selection:"
	echo ""
    ROOT_PART=$(gum choose --header="Select the root partition: (/)" $parts)
}

uefi_part_selection() {
	parts=$(ls $DISK* | grep "$DISK.*")
	echo "UEFI partition selection:"
	echo ""
    UEFI_PART=gum choose --header="Select the efi partiton: (/boot/efi)" $parts)

    if [ "$UEFI_PART" == "$ROOT_PART" ]; then
        echo "UEFI partition can't be the same as the root partition!"
        uefi_part_selection
	fi
}

config_keymap() {
	unset KEYMAP keymappart
	while [ ! "$keymappart" ]; do
		clear
		read -p "Enter part of your keymap (Eg: us,fr): " input
		keymappart=$(showkeymap | grep $input) || true
	done
	while [ ! "$KEYMAP" ]; do
		clear
		count=0
		for i in $keymappart; do
			count=$((count + 1))
			echo "[$count] $i"
		done
		read -p "Enter keymap [1-$count]: " input
		[ "$input" = 0 ] && continue
		[ "$input" -gt "$count" ] && continue
		KEYMAP=$(echo $keymappart | tr ' ' '\n' | head -n$input | tail -n1)
	done
}

echo "========================================================================"
echo "                     WELCOME ON CAMBRIA LINUX !                         "
echo "========================================================================"
echo ""
echo "This script is here to help you install our distro easily.              "
echo "Let us guide you step-by-step and you'll have a fully working Gentoo !  "
echo ""
echo "Let's start !"
echo ""

gum confirm "Ready?" || echo "See you next time!"; exit

echo ""

mount_iso
clear
stage_selection
clear
disk_selection
cfdisk $DISK
clear
root_part_selection
clear
uefi_part_selection
clear
user_account
clear
root_password
clear
config_keymap
clear

gum confirm "Install Cambria on $ROOT_PART from $DISK ? DATA MAY BE LOST!" || echo "Installation aborted, exiting."; exit

echo "Please wait while the script is doing the install for you :D"

# Mount root partition
mkfs.ext4 -F $ROOT_PART &>/dev/null
mkdir -p /mnt/gentoo
mount $ROOT_PART /mnt/gentoo

# Copy stage archive
cp $FILE /mnt/gentoo

# Extract stage archive
cd /mnt/gentoo
tar xpf $FILE --xattrs-include='*.*' --numeric-owner

# Mount UEFI partition
mkfs.vfat $UEFI_PART &>/dev/null
mkdir -p /mnt/gentoo/boot/efi
mount $UEFI_PART /mnt/gentoo/boot/efi

echo "UUID=$(blkid -o value -s UUID "$UEFI_PART") /boot/efi vfat defaults 0 2" >>/mnt/gentoo/etc/fstab
echo "UUID=$(blkid -o value -s UUID "$ROOT_PART") / $(lsblk -nrp -o FSTYPE $ROOT_PART) defaults 1 1" >>/mnt/gentoo/etc/fstab

# Keymap configuration
echo "KEYMAP=$KEYMAP" >/mnt/gentoo/etc/vconsole.conf

# Execute installation stuff
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

cat <<EOF | chroot /mnt/gentoo
grub-install --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
systemd-machine-id-setup
useradd -m -G users,wheel,audio,video,input -s /bin/bash $USERNAME
echo -e "${USER_PASSWORD}\n${USER_PASSWORD}" | passwd -q $USERNAME
echo -e "${ROOT_PASSWORD}\n${ROOT_PASSWORD}" | passwd -q
systemctl preset-all --preset-mode=enable-only
EOF

rm /mnt/gentoo/$(basename $FILE)

echo ""

echo "Installation has finished !"
echo "Press R to reboot..."
read REBOOT

if [ "$REBOOT" == "R" ] || [ "$REBOOT" == "r" ]; then
	reboot
fi
