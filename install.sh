#===================================================
# Cambria Linux install script
#===================================================

BASE_FILE="cambria-stage4-base.tar.xz"

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
    INVALID_CHOICE=1

    while [ "$INVALID_CHOICE" == "1" ]; do
        echo "SYSTEM SELECTION:"
        echo "[1] BASE"
        echo ""
        read -p "Your choice: " CHOICE

        if [ "$CHOICE" == "1" ]; then
            INVALID_CHOICE=0
            FILE=$BASE_FILE
            STAGE="BASE"
        else
            clear
            INVALID_CHOICE=1
        fi
    done
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

echo "Please wait while the script is doing the install for you :D"

# Mount root partition
mkfs.ext4 -F $ROOT_PART &> /dev/null
mount $ROOT_PART /mnt

# Copy stage archive
cp $FILE /mnt

# Extract stage archive
cd /mnt
tar xpf $FILE --xattrs-include='*.*' --numeric-owner

# Mount UEFI partition
mkfs.vfat $UEFI_PART &> /dev/null
mkdir -p /mnt/boot/efi
mount $UEFI_PART /mnt/boot/efi

# Execute installation stuff
cat << EOF | chroot /mnt
grub-install --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
systemd-machine-id-setup
useradd -m -G users,wheel,audio,video,input -s /bin/bash $USERNAME
echo -e "${USER_PASSWORD}\n${USER_PASSWORD}" | passwd -q $USERNAME
echo -e "${ROOT_PASSWORD}\n${ROOT_PASSWORD}" | passwd -q
systemctl preset-all --preset-mode=enable-only
EOF

clear

echo "Installation has finished !"
echo "Press R to reboot..."
read REBOOT

if [ "$REBOOT" == "R" ] || [ "$REBOOT" == "r" ]; then
    reboot
fi