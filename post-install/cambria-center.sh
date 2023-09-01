#!/bin/bash

#===================================================
# All-in-one script to manage post-install operations.
#===================================================

print_info() {
	echo -e "\e[1;36m$1\e[0m"
}

print_err() {
	echo -e "\e[1;31m$1\e[0m"
}

print_success() {
	echo -e "\e[1;32m$1\e[0m"
}

if [ "$UID" != "0" ]; then
	print_err "This script must be run as root !"
	exit 1
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

configure_locale() {
	echo "$LOCALE.UTF-8 UTF-8" >> /etc/locale.gen
	locale-gen
	cat <<EOF > /etc/locale.conf
LANG="$LOCALE.UTF-8"
LC_COLLATE="C.UTF-8"
EOF
}

menu() {
	gum_menu "Language configuration" "GDM AZERTY" "Clean VIDEO_CARDS (takes some while)" "CPU optimizer (takes some while)" "Build jobs (VERY IMPORTANT)" "Reboot (needed to apply changes)" "Exit"

	# Locale menu
	if [[ "$CHOICE" == "[1]"* ]]; then
		LOCALE=$(grep "UTF-8" /usr/share/i18n/SUPPORTED | awk '{print $1}' | sed 's/^#//;s/\.UTF-8//' | gum filter --limit 1 --header "Choose your locale:")
		clear
		print_info "Configuring locale..."
		configure_locale
		print_success "Done !"
		rm -rf /home/*/.config
	fi

	if [[ "$CHOICE" == "[2]"* ]]; then
		clear
		print_info "Configuring GDM..."
		localectl set-x11-keymap fr
		print_success "Done !"
		sleep 2
	fi

	if [[ "$CHOICE" == "[3]"* ]]; then
		clear
		GPUS=$(gum choose --header "What GPU(s) do you have ?" "None" "Intel" "AMD" "NVIDIA" "NVIDIA (nouveau)" --no-limit)
		VIDEO_CARDS="fbdev vesa "
		for gpu in $GPUS; do
			if [ "$gpu" == "Intel" ]; then
				VIDEO_CARDS+="intel i915 i965 "
			elif [ "$gpu" == "AMD" ]; then
				VIDEO_CARDS+="radeonsi amdgpu "
			elif [ "$gpu" == "NVIDIA" ]; then
				VIDEO_CARDS+="nvidia "
			elif [ "$gpu" == "NVIDIA (nouveau)" ]; then
				VIDEO_CARDS+="nouveau "
			fi
		done
		sed -i "/VIDEO_CARDS/d" /etc/portage/make.conf
		echo "VIDEO_CARDS=\"$VIDEO_CARDS\"" >> /etc/portage/make.conf
		emerge -quDN @world
		emerge --depclean
	fi

	if [[ "$CHOICE" == "[4]"* ]]; then
		clear
		emerge -q --selective=y app-portage/cpuid2cpuflags
		echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags
		emerge -quDN @world
	fi

	if [[ "$CHOICE" == "[5]"* ]]; then
		clear
		BUILD_JOBS=$(eval "gum choose --header \"Select a number of MAKE jobs\" {1..$(nproc)}")
		sed -i "/MAKEOPTS/d" /etc/portage/make.conf
		echo "MAKEOPTS=\"-j$BUILD_JOBS\"" >>/etc/portage/make.conf
		EMERGE_JOBS=$(eval "gum choose --header \"Select a number of EMERGE jobs\" {1..$(lscpu --all --parse=CORE,SOCKET | grep -Ev "^#" | sort -u | wc -l)}")
		sed -i "/EMERGE_DEFAULT_OPTS/d" /etc/portage/make.conf
		echo "EMERGE_DEFAULT_OPTS=\"--jobs $EMERGE_JOBS\"" >>/etc/portage/make.conf
	fi

	if [[ "$CHOICE" == "[6]"* ]]; then
		clear
		reboot
	fi

	if [[ "$CHOICE" == "[7]"* ]]; then
		exit
	fi

	clear
	menu
}

menu