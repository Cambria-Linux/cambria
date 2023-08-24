#===================================================
# Cambria Linux install script
#===================================================

BASE_FILE="cambria-stage4-base.tar.xz"

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
        echo ""
        echo "Invalid choice !"
        echo ""
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
        echo ""
        echo "Invalid choice !"
        echo ""
        root_part_selection
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

INVALID_CHOICE=1

while [ "$INVALID_CHOICE" == "1" ]; do
    echo "SYSTEM SELECTION:"
    echo "[1] BASE"
    echo ""
    read -p "Your choice: " CHOICE

    if [ "$CHOICE" == "1" ]; then
        INVALID_CHOICE=0

    else
        echo ""
        echo "Invalid choice !"
        echo ""
        INVALID_CHOICE=1
    fi
done

echo ""

disk_selection
root_part_selection