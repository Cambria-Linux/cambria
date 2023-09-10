#!/bin/bash

# Exit on error
set -e

#===================================================
# Cambria Linux install script
#===================================================

# Create system_install script to allow the usage of 'gum spin'.
cat << EOMF > system_install.sh
#!/usr/bin/env bash

# Mount root partition
mkfs.ext4 -F \$ROOT_PART &>/dev/null
mkdir -p /mnt/gentoo
mount \$ROOT_PART /mnt/gentoo

# Copy stage archive
cp \$FILE /mnt/gentoo

# Extract stage archive
cd /mnt/gentoo
tar xpf \$FILE --xattrs-include='*.*' --numeric-owner

# Mount UEFI partition
mkfs.vfat \$UEFI_PART &>/dev/null
mkdir -p /mnt/gentoo/boot/efi
mount \$UEFI_PART /mnt/gentoo/boot/efi

mkswap \$SWAP_PART

echo "UUID=\$(blkid -o value -s UUID "\$UEFI_PART") /boot/efi vfat defaults 0 2" >>/mnt/gentoo/etc/fstab
echo "UUID=\$(blkid -o value -s UUID "\$ROOT_PART") / \$(lsblk -nrp -o FSTYPE \$ROOT_PART) defaults 1 1" >>/mnt/gentoo/etc/fstab
echo "UUID=\$(blkid -o value -s UUID "\$SWAP_PART") swap swap pri=1 0 0" >>/mnt/gentoo/etc/fstab

# Keymap configuration
echo "KEYMAP=\$KEYMAP" >/mnt/gentoo/etc/vconsole.conf

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
useradd -m -G users,wheel,audio,video,input -s /bin/bash \$USERNAME
echo -e "\${USER_PASSWORD}\n\${USER_PASSWORD}" | passwd -q \$USERNAME
echo -e "\${ROOT_PASSWORD}\n\${ROOT_PASSWORD}" | passwd -q
systemctl preset-all --preset-mode=enable-only
EOF

rm /mnt/gentoo/\$(basename \$FILE)
EOMF

chmod +x system_install.sh

exit_() {
    echo $1
    exit
}

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
		find /usr/share/kbd/keymaps/ -type f -iname "*.map.gz" -printf "%f\n" | sed 's|.map.gz||g' | sed '/include\//d' | sort
	else
		find /usr/share/keymaps/ -type f -iname "*.map.gz" -printf "%f\n" | sed 's|.map.gz||g' | sed '/include\//d' | sort
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
    USERNAME=$(gum input --placeholder="Enter username")
    USER_PASSWORD=$(gum input --password --placeholder "Enter $USERNAME's password")
}

stage_selection() {
	echo "STAGE SELECTION:"
	echo ""
	ARCHIVES=/mnt/cdrom/*.tar.xz
	FILE=$(gum choose --header="Select the wanted stage:" $ARCHIVES)
}

disk_selection() {
	echo "Disk selection:"
	echo ""
    disks=$(lsblk -dp | grep -o '^/dev[^ ]*')
    DISK=$(gum choose --header="Select the disk to install Cambria into:" $disks)
}

root_part_selection() {
	parts=$(ls $DISK* | grep "$DISK.*" | tail -n +2)
	echo "Root partition selection:"
	echo ""
    ROOT_PART=$(gum choose --header="Select the root partition: (/)" $parts)
}

uefi_part_selection() {
	not_parsed_parts=$(ls $DISK* | grep "$DISK.*" | tail -n +2)
	
	parts=""
	for part in $not_parsed_parts; do
		[ "$part" != "$ROOT_PART" ] && parts+="$part "
	done
	
	echo "UEFI partition selection:"
	echo ""
    UEFI_PART=$(gum choose --header="Select the efi partiton: (/boot/efi)" $parts)

    if [ "$UEFI_PART" == "$ROOT_PART" ]; then
        echo "UEFI partition can't be the same as the root partition!"
        uefi_part_selection
    fi
}

swap_part_selection() {
	not_parsed_parts=$(ls $DISK* | grep "$DISK.*" | tail -n +2)
	
	parts=""
	for part in $not_parsed_parts; do
		[ "$part" != "$ROOT_PART" ] && [ "$part" != "$UEFI_PART" ] && parts+="$part "
	done

	echo "SWAP partition selection:"
	echo ""
	SWAP_PART=$(gum choose --header="Select the swap partition:" $parts)
	if [ "$part" == "$ROOT_PART" ]; then
		echo "SWAP partition can't be the same as the root partition!"
		swap_part_selection
	elif [ "$part" == "$UEFI_PART" ]; then
		echo "SWAP partition can't be the same as the efi partition!"
		swap_part_selection
	fi
}

config_keymap() {
	unset KEYMAP keymappart
	echo "Keymap selection:"
	echo ""
	keymappart=$(showkeymap | gum filter --placeholder="Enter and find your keymap...")
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

gum confirm "Ready?" || exit_ "See you next time!"

echo ""

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
swap_part_selection
clear
user_account
clear
root_password
clear
config_keymap
clear

gum confirm "Install Cambria on $ROOT_PART from $DISK ? DATA MAY BE LOST!" || exit_ "Installation aborted, exiting."

gum spin -s pulse --show-output --title="Please wait while the script is doing the install for you :D" /usr/bin/env ROOT_PART=$ROOT_PART UEFI_PART=$UEFI_PART KEYMAP=$KEYMAP USERNAME=$USERNAME USER_PASSWORD=$USER_PASSWORD ROOT_PASSWORD=$ROOT_PASSWORD FILE=$FILE SWAP_PART=$SWAP_PART bash ./system_install.sh

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
