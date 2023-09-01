#!/bin/bash

#===================================================
# All-in-one script to generate stages.
#===================================================

source stage-generation/functions.sh

if [ "$UID" != "0" ]; then
	print_err "This script must be run as root !"
	exit 1
fi

if [ ! -f /usr/bin/gum ]; then
	wget https://github.com/charmbracelet/gum/releases/download/v0.11.0/gum_0.11.0_Linux_x86_64.tar.gz
	tar -xf gum_*.tar.gz gum
	cp gum /usr/bin/gum
	rm gum*
	clear
fi

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
	gum_menu "BASE" "GNOME"

	if [[ "$CHOICE" == "[1]"* ]]; then
		source stage-generation/base.sh
	elif [[ "$CHOICE" == "[2]"* ]]; then
		source stage-generation/gnome.sh
	else
		INVALID_ANSWER=1
		menu
	fi
	
	clear
	tool_menu
}

tool_menu() {
	echo "====================================================================="
	echo "                   CAMBRIA GENERATION TOOL                           "
	echo "====================================================================="
	echo ""
	gum_menu "Stage Generation" "ISO Generation"

	if [[ "$CHOICE" == "[1]"* ]]; then
		clear
		stage_menu
	elif [[ "$CHOICE" == "[2]"* ]]; then
		clear
		gen_iso
	fi
}

stage_menu() {
	echo "====================================================================="
	echo "                   CAMBRIA STAGE GENERATION TOOL                     "
	echo "====================================================================="
	echo ""
	gum_menu "Launch build" "Configuration"

	if [[ "$CHOICE" == "[1]"* ]]; then
		clear
		build
		clean_cache
		clean_dev
		compress_build
	elif [[ "$CHOICE" == "[2]"* ]]; then
		clear
		conf_menu
	fi
}

menu
