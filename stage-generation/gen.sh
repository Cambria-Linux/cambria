#!/bin/bash

#===================================================
# All-in-one script to generate stages.
#===================================================

source stage-generation/functions.sh

if [ "$UID" != "0" ]; then
	print_err "This script must be run as root !"
	exit 1
fi

print_choices() {
	for c in $1; do
		echo $C
	done
}

gum_menu() {
	i=1
	CHOICES=()
	for choice in "$@"; do
		CHOICES+=("[$i] $choice")
		i=$((i + 1))
	done
	CHOICE=$(printf '%s\n' "${CHOICES[@]}" | gum choose)
}

conf_menu() {
	echo "====================================================================="
	echo "                         CONFIGURATION                               "
	echo "====================================================================="
	echo ""
	
	gum_menu "Emerge jobs" "Build jobs" "Base stage choice" "Show current configuration"

	if [[ "$CHOICE" == "[1]"* ]]; then
		PARALLEL_BUILD=1
		PARALLEL_JOBS=$(eval "gum choose {1..$(lscpu --all --parse=CORE,SOCKET | grep -Ev "^#" | sort -u | wc -l)}")
		clear
		conf_menu
	elif [[ "$CHOICE" == "[2]"* ]]; then
		MAKEJOBS=$(eval "gum choose {1..$(nproc)}")
		clear
		conf_menu
	elif [[ "$CHOICE" == "[3]"* ]]; then
		BASE_STAGE=$PWD/$(for file in *.tar.xz; do echo $file; done | gum choose)
		clear
		conf_menu
	elif [[ "$CHOICE" == "[4]"* ]]; then
		echo "PARALLEL_BUILD=$PARALLEL_BUILD"
		echo "PARALLEL_JOBS=$PARALLEL_JOBS"
		echo "MAKEJOBS=$MAKEJOBS"
		echo "BASE_STAGE=$BASE_STAGE"
		sleep 3
		clear
		stage_menu
	else
		clear
		stage_menu
	fi
	exit
}

menu() {	
	echo "====================================================================="
	echo "                   CAMBRIA GENERATION TOOL                           "
	echo "====================================================================="
	echo ""
	gum_menu "BASE"

	if [[ "$CHOICE" == "[1]"* ]]; then
		source stage-generation/base.sh
	fi

	clear
	tool_menu
}

tool_menu() {
	echo "====================================================================="
	echo "                   CAMBRIA GENERATION TOOL                           "
	echo "====================================================================="
	echo ""
	echo "[S] Stage Generation"
	echo "[I] ISO Generation"
	echo ""
	read -p "Enter your choice: " CHOICE

	if [ "$CHOICE" == "S" ] || [ "$CHOICE" == "s" ]; then
		stage_menu
	elif [ "$CHOICE" == "I" ] || [ "$CHOICE" == "i" ]; then
		gen_iso
	else
		tool_menu
	fi
}

stage_menu() {
	echo "====================================================================="
	echo "                   CAMBRIA STAGE GENERATION TOOL                     "
	echo "====================================================================="
	echo ""
	echo "[1] Launch build"
	echo ""
	echo "[C] Configuration"
	echo ""
	read -p "Enter your choice: " CHOICE

	if [ "$CHOICE" == "1" ]; then
		build
		clean_cache
		clean_dev
		compress_build
	elif [ "$CHOICE" == "c" ] || [ "$CHOICE" == "C" ]; then
		clear
		conf_menu
	else
		echo "Invalid choice. Exiting..."
		exit 1
	fi
}

menu
