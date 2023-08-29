#===================================================
# The gnome stage generation script.
#===================================================

STAGE="GNOME"
OUTPUT=cambria-gnome

build() {
	clean

	if [ -z $BASE_STAGE ]; then
		print_err "No stage3 provided, exiting..."
		exit 1
	fi

	print_info "Extracting base stage..."
	extract_stage $BASE_STAGE
	print_success "Done !"

	print_info "Writing portage configuration..."
	USEFLAGS="-kde gtk gles2 x264 x265 v4l grub zeroconf cups bluetooth vulkan pipewire wayland networkmanager pulseaudio" configure_portage
	print_success "Done !"

	print_info "Setting DNS info..."
	set_dns
	print_success "Done !"

	print_info "Building BASE stage..."
	setup_chroot
	cat <<EOF | chroot .
emerge-webrsync

emerge --sync --quiet
emerge -quDN @world
EOF

    echo "gui-apps/gnome-console ~amd64" >>etc/portage/package.accept_keywords/gnome-console
    echo "x11-libs/libdrm ~amd64" >>etc/portage/package.accept_keywords/libdrm
    echo "x11-libs/libdrm video_cards_intel" >>etc/portage/package.use/libdrm
    echo "media-libs/libsndfile minimal" >>etc/portage/package.use/libsndfile
	

	install_packages gnome-browser-connector gnome-tweaks gnome-extra/mousetweaks evince gnome-contacts totem gnome-keyring gedit gjs gnome-control-center gnome-core-libs gnome-session gnome-settings-daemon gnome-shell gvfs nautilus cantarell gnome-console adwaita-icon-theme gnome-backgrounds gnome-themes-standard mutter firefox-bin thunderbird-bin eog 
	enable_services gdm NetworkManager bluetooth avahi-daemon cups
    unmount_chroot
}
