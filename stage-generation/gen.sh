#===================================================
# All-in-one script to generate stages.
#===================================================

source stage-generation/functions.sh

if [ "$UID" != "0" ]; then
    print_err "This script must be run as root !"
    exit 1
fi

conf_menu() {
    echo "====================================================================="
    echo "                         CONFIGURATION                               "
    echo "====================================================================="
    echo ""
    echo "[1] Enable parallel builds"
    echo "[?] Show current configuration"
    echo ""
    read -p "Enter your choice: " CHOICE
    if [ "$CHOICE" == "1" ]; then
        PARALLEL_BUILD=1
        read -p "How many build jobs do you want ? " PARALLEL_JOBS
        clear
        conf_menu
    elif [ "$CHOICE" == "?" ]; then
        echo "PARALLEL_BUILD=$PARALLEL_BUILD"
        sleep 3
        clear
        menu
    else
        clear
        menu
    fi
}

menu() {
    echo "====================================================================="
    echo "                   CAMBRIA STAGE GENERATION TOOL                     "
    echo "====================================================================="
    echo ""
    echo "[1] BASE"
    echo ""
    echo "[C] Configuration"
    echo ""
    read -p "Enter your choice: " CHOICE

    if [ "$CHOICE" == "1" ]; then
        source stage-generation/base.sh
        build
    elif [ "$CHOICE" == "c" ] || [ "$CHOICE" == "C" ]; then
        clear
        conf_menu
    else
        echo "Invalid choice. Exiting..."
        exit 1
    fi
}

menu
clean_cache
clean_dev
compress_build