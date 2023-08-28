#===================================================
# The base stage generation script.
#===================================================

OUTPUT=cambria-stage4-base.tar.xz

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
	USEFLAGS="x264 x265 v4l grub zeroconf cups bluetooth vulkan pipewire wayland networkmanager pulseaudio" configure_portage
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
	install_packages linux-firmware gentoo-kernel-bin grub cpuid2cpuflags sys-apps/mlocate genlop eix eselect-repository neofetch bash-completion sys-fs/dosfstools net-misc/dhcpcd net-wireless/iwd
	unmount_chroot
}
