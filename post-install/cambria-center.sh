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

processes=($(pgrep cambria-center))
if [ "$XDG_CURRENT_DESKTOP" == "KDE" ] && [ "${#processes[@]}" == "1" ]; then
	konsole -e "cambria-center"
	exit
fi

if [ "$UID" != "0" ]; then
	print_info "You're not running cambria-center as root... Please type root password here."
	su -c "cambria-center"
	exit
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
	eselect locale set $LOCALE.UTF-8
}

configure_aliases() {
	echo "alias cambria-install=\"emerge -aq\"" >>/etc/bash/bashrc
	cat <<EOF > /usr/bin/cambria-delete
#!/bin/bash
emerge --deselect $@ && emerge --depclean
EOF
	cat <<EOF > /usr/bin/cambria-update
#!/bin/bash
eix-sync && emerge -avuDN @world
EOF

	cat <<EOF > /usr/bin/cambria-update-sleep
#!/bin/bash
eix-sync && emerge -avuDN @world && shutdown -h now
EOF

	cat <<EOF > /usr/bin/cambria-kernel-testing
#!/bin/bash
echo "******Activation du noyau testing******"
echo sys-kernel/gentoo-kernel-bin ~amd64 >> /etc/portage/package.accept_keywords/kernel
echo virtual/dist-kernel ~amd64 >> /etc/portage/package.accept_keywords/kernel
cambria-update
EOF

	chmod +x /usr/bin/cambria-delete
	chmod +x /usr/bin/cambria-update
	chmod +x /usr/bin/cambria-update-sleep
	chmod +x /usr/bin/cambria-kernel-testing
}

menu() {
	gum_menu "Build jobs (VERY IMPORTANT)" "CPU optimizer (takes a while)" "Clean VIDEO_CARDS (takes a while)" "Exit"

	if [[ "$CHOICE" == "[1]"* ]]; then
		clear
		BUILD_JOBS=$(eval "gum choose --header \"Select a number of MAKE jobs\" {1..$(nproc)}")
		sed -i "/MAKEOPTS/d" /etc/portage/make.conf
		echo "MAKEOPTS=\"-j$BUILD_JOBS\"" >>/etc/portage/make.conf
		EMERGE_JOBS=$(eval "gum choose --header \"Select a number of EMERGE jobs\" {1..$(lscpu --all --parse=CORE,SOCKET | grep -Ev "^#" | sort -u | wc -l)}")
		sed -i "/EMERGE_DEFAULT_OPTS/d" /etc/portage/make.conf
		echo "EMERGE_DEFAULT_OPTS=\"--jobs $EMERGE_JOBS\"" >>/etc/portage/make.conf
	fi

	if [[ "$CHOICE" == "[2]"* ]]; then
		clear
		emerge -q --selective=y app-portage/cpuid2cpuflags
		echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags
		emerge -quDN @world
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
		rm -f /etc/xdg/autostart/cambria-center.desktop
		exit
	fi

	clear
	menu
}

if [ "$XDG_CURRENT_DESKTOP" == "GNOME" ]; then
	su $(logname) -c "gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' && gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'"
	su $(logname) -c "flatpak install -y --noninteractive org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark"
fi

chmod u+s /sbin/unix_chkpwd
su $(logname) -c "systemctl --user disable --now pulseaudio.socket pulseaudio.service"
su $(logname) -c "systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service"
configure_aliases
clear
menu