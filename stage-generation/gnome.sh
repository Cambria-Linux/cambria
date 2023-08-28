#===================================================
# The gnome stage generation script.
#===================================================

<<<<<<< HEAD
STAGE="GNOME"
=======
>>>>>>> 029b1b8 (feat : add gnome stage script and user dirs)
OUTPUT=cambria-gnome

build() {
	clean

<<<<<<< HEAD
	if [ -z $BASE_STAGE ]; then
=======
	if [ -n $BASE_STAGE ]; then
>>>>>>> 029b1b8 (feat : add gnome stage script and user dirs)
		print_err "No stage3 provided, exiting..."
		exit 1
	fi

	print_info "Extracting base stage..."
	extract_stage $BASE_STAGE
	print_success "Done !"

	print_info "Writing portage configuration..."
<<<<<<< HEAD
	USEFLAGS="-kde gtk egl X gles2 x264 x265 v4l grub zeroconf cups bluetooth vulkan pipewire wayland networkmanager pulseaudio" configure_portage
=======
	USEFLAGS="gles2 x264 x265 v4l grub zeroconf cups bluetooth vulkan pipewire wayland networkmanager pulseaudio" configure_portage
>>>>>>> 029b1b8 (feat : add gnome stage script and user dirs)
	print_success "Done !"

	print_info "Setting DNS info..."
	set_dns
	print_success "Done !"

	print_info "Building BASE stage..."
	setup_chroot
	cat <<EOF | chroot .
emerge-webrsync

emerge --sync --quiet
<<<<<<< HEAD

EOF

	echo "gnome-extra/evolution-data-server ~amd64" >>etc/portage/package.accept_keywords/evolution-data-server
	echo "media-gfx/gnome-photos ~amd64" >>etc/portage/package.accept_keywords/gnome-photos
    echo "gui-apps/gnome-console ~amd64" >>etc/portage/package.accept_keywords/gnome-console
    echo "x11-libs/libdrm ~amd64" >>etc/portage/package.accept_keywords/libdrm
	echo "gnome-extra/gnome-software ~amd64" >>etc/portage/package.accept_keywords/gnome-software
	echo "net-im/discord ~amd64" >>etc/portage/package.accept_keywords/discord
	
    echo "x11-libs/libdrm video_cards_intel" >>etc/portage/package.use/libdrm
    echo "media-libs/libsndfile minimal" >>etc/portage/package.use/libsndfile
	echo "media-libs/libmediaart -gtk" >>etc/portage/package.use/libmediaart
	echo "dev-libs/folks eds" >>etc/portage/package.use/folks
	echo "gnome-extra/evolution-data-server vala" >>etc/portage/package.use/evolution-data-server
	echo "dev-libs/libical vala" >>etc/portage/package.use/libical
	echo "media-libs/gegl raw" >>etc/portage/package.use/gegl
	echo "media-libs/gst-plugins-base theora" >>etc/portage/package.use/gst-plugins-base
	echo "media-plugins/grilo-plugins tracker" >>etc/portage/package.use/grilo-plugins
	echo "gnome-extra/gnome-software flatpak" >>etc/portage/package.use/gnome-software
	echo "net-dns/avahi -gtk -qt5" >>etc/portage/package.use/avahi

	cat <<EOF | chroot .
emerge -quDN @world
EOF

	install_packages discord media-fonts/noto-emoji gnome-software sys-apps/flatpak gnome-browser-connector gnome-tweaks gnome-extra/mousetweaks evince gnome-contacts totem gnome-keyring gnome-text-editor gnome-calendar gnome-maps gnome-weather gnome-music cheese baobab gnome-disk-utility gnome-photos gjs gnome-control-center gnome-core-libs gnome-session gnome-settings-daemon gnome-shell gvfs nautilus cantarell gnome-console adwaita-icon-theme gnome-backgrounds gnome-themes-standard mutter firefox-bin thunderbird-bin eog 
	enable_services gdm NetworkManager bluetooth avahi-daemon cups

	cat <<EOF | chroot .
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
EOF

=======
emerge -quDN @world
EOF
	install_packages gjs gnome-control-center gnome-core-libs gnome-session gnome-settings-daemon gnome-shell gvfs nautilus cantarell gnome-console adwaita-icon-theme gnome-backgrounds gnome-themes-standard mutter firefox-bin thunderbird-bin eog 
	enable_services gdm NetworkManager bluetooth avahi cups
>>>>>>> 029b1b8 (feat : add gnome stage script and user dirs)
    unmount_chroot
}
