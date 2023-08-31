#!/bin/bash

# Exit on error
set -e

#===================================================
# Cambria Linux install script
#===================================================

#mount_iso() {
#	mkdir -p /mnt/iso
#	if [ -b /dev/mapper/ventoy ]; then
#		mount /dev/mapper/ventoy /mnt/iso
#	elif [ -b /dev/disk/by-label/ISOIMAGE* ]; then
#		mount /dev/disk/by-label/ISOIMAGE* /mnt/iso
#	fi
#}

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
	i=0
	for part in $parts; do
		if [ "$i" == "0" ]; then
			i=$((i + 1))
			continue
		fi

		if [ "$part" == "$ROOT_PART" ]; then
			continue
		fi

		echo "[$i] $part"
		i=$((i + 1))
	done

	echo ""
	read -p "Your choice: " CHOICE

	i=0
	for part in $parts; do
		if [ "$i" == "0" ]; then
			i=$((i + 1))
			continue
		fi

		if [ "$part" == "$ROOT_PART" ]; then
			continue
		fi

		if [ "$i" == "$CHOICE" ]; then
			UEFI_PART=$part
		fi

		i=$((i + 1))
	done

	if [ "$UEFI_PART" == "" ]; then
		clear
		uefi_part_selection
	fi
}

swap_part_selection() {
	parts=$(ls $DISK* | grep "$DISK.*")
	echo "SWAP partition selection:"
	echo ""
	i=0
	for part in $parts; do
		if [ "$i" == "0" ]; then
			i=$((i + 1))
			continue
		fi

		if [ "$part" == "$ROOT_PART" ] || [ "$part" == "$UEFI_PART" ]; then
			continue
		fi

		echo "[$i] $part"
		i=$((i + 1))
	done

	echo ""
	read -p "Your choice: " CHOICE

	i=0
	for part in $parts; do
		if [ "$i" == "0" ]; then
			i=$((i + 1))
			continue
		fi

		if [ "$part" == "$ROOT_PART" ] || [ "$part" == "$UEFI_PART" ]; then
			continue
		fi

		if [ "$i" == "$CHOICE" ]; then
			SWAP_PART=$part
		fi

		i=$((i + 1))
	done

	if [ "$SWAP_PART" == "" ]; then
		clear
		swap_part_selection
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

read -p "Ready ? (Y/N) " READY

if [ "$READY" != "Y" ] && [ "$READY" != "y" ]; then
	exit
fi

echo ""

stage_selection
clear
disk_selection
cfdisk $DISK
clear
root_part_selection
clear
uefi_part_selection
clear
swap_part_selection
clear
user_account
clear
root_password
clear
config_keymap
clear

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

mkswap $SWAP_PART

echo "UUID=$(blkid -o value -s UUID "$UEFI_PART") /boot/efi vfat defaults 0 2" >>/mnt/gentoo/etc/fstab
echo "UUID=$(blkid -o value -s UUID "$ROOT_PART") / $(lsblk -nrp -o FSTYPE $ROOT_PART) defaults 1 1" >>/mnt/gentoo/etc/fstab
echo "UUID=$(blkid -o value -s UUID "$SWAP_PART") swap swap pri=1 0 0" >>/mnt/gentoo/etc/fstab

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
cp /usr/bin/cambria-center /mnt/gentoo/usr/bin/

mkdir -p /mnt/gentoo/etc/xdg/autostart
cp /etc/xdg/autostart/cambria-center.desktop /mnt/gentoo/etc/xdg/autostart/

echo ""
clear

# Locale configuration
LOCALE=$(grep "UTF-8" /mnt/gentoo/usr/share/i18n/SUPPORTED | awk '{print $1}' | sed 's/^#//;s/\.UTF-8//' | gum filter --limit 1 --header "Choose your locale:")
echo "$LOCALE.UTF-8 UTF-8" >> /mnt/gentoo/etc/locale.gen
cat <<EOF | chroot /mnt/gentoo
locale-gen
eselect locale set $LOCALE.UTF-8
EOF

# Keymap configuration
xkb_symbols=$(find /mnt/gentoo/usr/share/X11/xkb/symbols -maxdepth 1 -type f)
X11_KEYMAP=$(for file in ${xkb_symbols[@]}; do [ "$(cat $file | grep '// Keyboard layouts')" != "" ] && echo $(basename $file) ; done | sort | gum filter --header "Choose a X11 keymap:")

mkdir -p /mnt/gentoo/etc/X11/xorg.conf.d
cat <<EOF > /mnt/gentoo/etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
  Identifier "system-keyboard"
  MatchIsKeyboard "on"
  Option "XkbLayout" "$X11_KEYMAP"
EndSection
EOF

# Timezone configuration
unset TIMEZONE location country listloc listc countrypart

for l in /mnt/gentoo/usr/share/zoneinfo/*; do
	[ -d $l ] || continue
	l=${l##*/}
	case $l in
		Etc|posix|right) continue;;
	esac
	listloc="$listloc $l"
done

location=$(echo $listloc | tr ' ' '\n' | gum filter --header "Choose a location:")

for c in /mnt/gentoo/usr/share/zoneinfo/$location/*; do
	c=${c##*/}
	listc="$listc $c"
done

country=$(echo $listc | tr ' ' '\n' | gum filter --header "Choose a city:")
rm -f /mnt/gentoo/etc/localtime
ln -s /usr/share/zoneinfo/$location/$country /mnt/gentoo/etc/localtime

cat <<EOF | chroot /mnt/gentoo
su $USERNAME -c "cd /home/$USERNAME && LANG=$LOCALE.UTF-8 xdg-user-dirs-update"
EOF

clear
echo "Installation has finished !"
echo "Press R to reboot..."
read REBOOT

if [ "$REBOOT" == "R" ] || [ "$REBOOT" == "r" ]; then
	reboot
fi
