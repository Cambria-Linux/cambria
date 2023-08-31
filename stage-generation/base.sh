#===================================================
# The base stage generation script.
#===================================================

OUTPUT=cambria-stage4-base

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
	install_packages linux-firmware gentoo-kernel-bin grub cpuid2cpuflags sys-apps/mlocate genlop eix eselect-repository bash-completion sys-fs/dosfstools dev-vcs/git net-misc/dhcpcd net-wireless/iwd
	cat <<EOF | chroot .
eselect repository remove gentoo
eselect repository add gentoo git https://github.com/gentoo-mirror/gentoo.git
rm -r /var/db/repos/gentoo
eix-sync -q
eix-update -q
EOF
	unmount_chroot
	wget https://raw.githubusercontent.com/Cambria-Linux/hyfetch/master/neofetch
	mv neofetch usr/bin/neofetch
	chmod +x usr/bin/neofetch
}
