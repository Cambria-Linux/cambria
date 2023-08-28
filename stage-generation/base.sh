#===================================================
# The base stage generation script.
#===================================================

# Extract stage 3

STAGE="BASE"
OUTPUT=cambria-stage4-base.tar.xz

build() {
    clean

    if [ "$STAGE3" == "" ]; then
        print_err "No stage3 provided, exiting..."
        exit 1
    fi

    print_info "Extracting stage 3..."
    extract_stage $STAGE3
    print_success "Done !"

    print_info "Writing portage configuration..."
    USEFLAGS="x264 x265 v4l grub zeroconf cups bluetooth vulkan pipewire wayland networkmanager pulseaudio" configure_portage
    print_success "Done !"

    print_info "Setting DNS info..."
    set_dns
    print_success "Done !"

    print_info "Building BASE stage..."
    setup_chroot
    cat << EOF | chroot .
emerge-webrsync

emerge --sync --quiet
emerge -quDN @world
EOF
    install_packages linux-firmware gentoo-kernel-bin grub cpuid2cpuflags sys-apps/mlocate genlop eix eselect-repository neofetch bash-completion chrony sys-fs/dosfstools net-misc/dhcpcd net-wireless/iwd
    unmount_chroot
}
