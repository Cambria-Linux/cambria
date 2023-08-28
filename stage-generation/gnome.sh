#===================================================
# The gnome stage generation script.
#===================================================

OUTPUT=cambria-gnome

build() {
	clean

	if [ -n $BASE_STAGE ]; then
		print_err "No stage3 provided, exiting..."
		exit 1
	fi

	print_info "Extracting base stage..."
	extract_stage $BASE_STAGE
	print_success "Done !"

	print_info "Writing portage configuration..."
	USEFLAGS="gles2 x264 x265 v4l grub zeroconf cups bluetooth vulkan pipewire wayland networkmanager pulseaudio" configure_portage
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
	install_packages gjs gnome-control-center gnome-core-libs gnome-session gnome-settings-daemon gnome-shell gvfs nautilus cantarell gnome-console adwaita-icon-theme gnome-backgrounds gnome-themes-standard mutter firefox-bin thunderbird-bin eog 
	enable_services gdm NetworkManager bluetooth avahi cups
    unmount_chroot
}
