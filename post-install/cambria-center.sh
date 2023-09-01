#!/bin/bash

#===================================================
# All-in-one script to manage post-install operations.
#===================================================

gum_menu() {
	i=1
	CHOICES=()
	for choice in "$@"; do
		CHOICES+=("[$i] $choice")
		i=$((i + 1))
	done
	CHOICE=$(printf '%s\n' "${CHOICES[@]}" | gum choose)
}

gum_menu "Language configuration" "GDM AZERTY" "Clean system (takes some while)" "System optimizer (takes some while)"