#===================================================
# All-in-one script to generate stages.
#===================================================

source stage-generation/functions.sh

if [ "$UID" != "0" ]; then
    print_err "This script must be run as root !"
    exit 1
fi

echo "====================================================================="
echo "                   CAMBRIA STAGE GENERATION TOOL                     "
echo "====================================================================="
echo ""
echo "[1] BASE"
echo ""

read -p "Enter your choice: " CHOICE

if [ "$CHOICE" == "1" ]; then
    source stage-generation/base.sh
    build
else
    echo "Invalid choice. Exiting..."
    exit 1
fi

compress_build