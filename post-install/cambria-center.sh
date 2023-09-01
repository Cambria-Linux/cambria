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
	gum_menu "Language configuration" "GDM AZERTY" "Clean system (takes some while)" "System optimizer (takes some while)" "Reboot (needed to apply changes)" "Exit"

	# Locale menu
	if [[ "$CHOICE" == "[1]"* ]]; then
		LOCALE=$(grep "UTF-8" /usr/share/i18n/SUPPORTED | awk '{print $1}' | sed 's/^#//;s/\.UTF-8//' | gum filter --limit 1 --header "Choose your locale:")
		clear
		print_info "Configuring locale..."
		configure_locale
		print_success "Done !"
	fi

	if [[ "$CHOICE" == "[2]"* ]]; then
		clear
		print_info "Configuring GDM..."
		localectl set-x11-keymap fr
		print_success "Done !"
		sleep 2
	fi
	
	if [[ "$CHOICE" == "[6]"* ]]; then
		exit
	fi

	clear
	menu
}

menu