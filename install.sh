#!/bin/bash

#===================================================
# Cambria Linux install script
#===================================================

mount_iso() {
    mkdir -p /mnt/iso
    if [ -b /dev/mapper/ventoy ]; then
        mount /dev/mapper/ventoy /mnt/iso
    elif [ -b /dev/disk/by-label/CAMBRIA* ]; then
        mount /dev/disk/by-label/CAMBRIA*
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
    printf "What will be the root account password ? (input is hidden) "
    read -s ROOT_PASSWORD
}

user_account() {
    echo "User account creation: "
    echo ""
    read -p "What will be your username ? " USERNAME
    printf "What will be your password (input is hidden) ? "
    read -s USER_PASSWORD
}

stage_selection() {
    echo "ARCHIVE SELECTION:"
    i=1
    for file in /mnt/iso/*.tar.xz; do
        echo "[$i] $file"
        i=$((i+1))
    done
    echo ""
    read -p "Your choice: " CHOICE

    for file in /mnt/iso/*.tar.xz; do
        if [ "$CHOICE" == "$i" ]; then
            FILE=$file
        fi
        i=$((i+1))
    done

    if [ -z $FILE ]; then
        clear
        stage_selection
    fi
}

disk_selection() {
    echo "Disk selection:"
    i=1
    for disk in $(lsblk -dp | grep -o '^/dev[^ ]*'); do
        echo "[$i] $disk"
        i=$((i+1))
    done

    echo ""
    read -p "Your choice: " CHOICE

    i=1
    for disk in $(lsblk -dp | grep -o '^/dev[^ ]*'); do
        if [ "$i" == "$CHOICE" ]; then
            DISK=$disk
        fi
        i=$((i+1))
    done

    if [ "$DISK" == "" ]; then
        clear
        disk_selection
    fi
}

root_part_selection() {
    parts=$(ls $DISK* | grep "$DISK.*")
    echo "Root partition selection:"
    echo ""
    i=0
    for part in $parts; do
        if [ "$i" == "0" ]; then
            i=$((i+1))
            continue
        fi

        echo "[$i] $part"
        i=$((i+1))
    done
    
    echo ""
    read -p "Your choice: " CHOICE

    i=0
    for part in $parts; do
        if [ "$i" == "0" ]; then
            i=$((i+1))
            continue
        fi

        if [ "$i" == "$CHOICE" ]; then
            ROOT_PART=$part
        fi
        i=$((i+1))
    done

    if [ "$ROOT_PART" == "" ]; then
        clear
        root_part_selection
    fi
}

uefi_part_selection() {
    parts=$(ls $DISK* | grep "$DISK.*")
    echo "UEFI partition selection:"
    echo ""
    i=0
    for part in $parts; do
        if [ "$i" == "0" ]; then
            i=$((i+1))
            continue
        fi

        if [ "$part" == "$ROOT_PART" ]; then
            if [ "$i" != "1" ]; then
                i=$((i-1))
            fi
            continue
        fi

        echo "[$i] $part"
        i=$((i+1))
    done
    
    echo ""
    read -p "Your choice: " CHOICE

    i=0
    for part in $parts; do
        if [ "$i" == "0" ]; then
            i=$((i+1))
            continue
        fi

        if [ "$part" == "$ROOT_PART" ]; then
            if [ "$i" != "1" ]; then
                i=$((i-1))
            fi
            continue
        fi

        if [ "$i" == "$CHOICE" ]; then
            UEFI_PART=$part
        fi

        i=$((i+1))
    done

    if [ "$UEFI_PART" == "" ]; then
        clear
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
			count=$((count+1))
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

mount_iso
clear
stage_selection
clear
disk_selection
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

echo "Please wait while the script is doing the install for you :D"

# Mount root partition
mkfs.ext4 -F $ROOT_PART &> /dev/null
mkdir -p /mnt/gentoo
mount $ROOT_PART /mnt/gentoo

# Copy stage archive
cp $FILE /mnt/gentoo

# Extract stage archive
cd /mnt/gentoo
tar xpf $FILE --xattrs-include='*.*' --numeric-owner

# Mount UEFI partition
mkfs.vfat $UEFI_PART &> /dev/null
mkdir -p /mnt/gentoo/boot/efi
mount $UEFI_PART /mnt/gentoo/boot/efi

echo "UUID=$(blkid -o value -s UUID "$UEFI_PART") /boot/efi vfat defaults 0 2" >> /mnt/gentoo/etc/fstab
echo "UUID=$(blkid -o value -s UUID "$ROOT_PART") / $(lsblk -nrp -o FSTYPE $ROOT_PART) defaults 1 1" >> /mnt/gentoo/etc/fstab

# Keymap configuration
echo "KEYMAP=$KEYMAP" > /mnt/gentoo/etc/vconsole.conf

# Execute installation stuff
mount --types proc /proc /mnt/gentoo/proc 
mount --rbind /sys /mnt/gentoo/sys 
mount --make-rslave /mnt/gentoo/sys 
mount --rbind /dev /mnt/gentoo/dev 
mount --make-rslave /mnt/gentoo/dev 
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

cat << EOF | chroot /mnt/gentoo
grub-install --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
systemd-machine-id-setup
useradd -m -G users,wheel,audio,video,input -s /bin/bash $USERNAME
echo -e "${USER_PASSWORD}\n${USER_PASSWORD}" | passwd -q $USERNAME
echo -e "${ROOT_PASSWORD}\n${ROOT_PASSWORD}" | passwd -q
systemctl preset-all --preset-mode=enable-only
EOF

echo ""

echo "Installation has finished !"
echo "Press R to reboot..."
read REBOOT

if [ "$REBOOT" == "R" ] || [ "$REBOOT" == "r" ]; then
    reboot
fi