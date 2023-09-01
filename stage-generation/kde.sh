#===================================================
# The KDE stage generation script.
#===================================================

OUTPUT=cambria-stage-kde
STAGE=KDE

build() {
    clean

    if [ -z $BASE_STAGE ]; then
        print_err "No base stage provided ! Exiting..."
        exit 1
    fi

    print_info "Extracting base stage..."
	extract_stage $BASE_STAGE
	print_success "Done !"

    print_info "Writing portage configuration..."
    USEFLAGS="kde -gnome egl X gles2 x264 x265 v4l grub zeroconf cups bluetooth vulkan pipewire wayland networkmanager pulseaudio" configure_portage
    print_success "Done !"

    print_info "Setting DNS info..."
	set_dns
	print_success "Done !"

    print_info "Building $STAGE stage..."
	setup_chroot
    cat <<EOF | chroot .
eix-sync

eix-update

EOF

    echo "x11-libs/libdrm video_cards_intel" >>etc/portage/package.use/libdrm
    echo "media-libs/libsndfile minimal" >>etc/portage/package.use/libsndfile
    echo "net-dns/avahi -gtk -qt5" >>etc/portage/package.use/avahi
	echo "net-wireless/wpa_supplicant -qt5" >>etc/portage/package.use/wpa_supplicant
	echo "app-text/mupdf -opengl -X" >>etc/portage/package.use/mupdf
    echo "kde-plasma/plasma-meta discover display-manager sddm wallpapers" >>etc/portage/package.use/kde
    echo "kde-plasma/discover flatpak" >>etc/portage/package.use/discover
    echo "kde-apps/kde-apps-meta accessibility -admin -education -games graphics multimedia -network -pim -sdk utils" >>etc/portage/package.use/kde-apps

    cat <<EOF | chroot .
emerge -quDN @world
EOF

    install_packages kde-plasma/plasma-meta kde-apps/kde-apps-meta www-client/firefox-bin mail-client/thunderbird-bin
    enable_services sddm NetworkManager bluetooth avahi-daemon cups

    cat <<EOF | chroot .
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
EOF
    unmount_chroot
}