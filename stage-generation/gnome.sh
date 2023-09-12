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
	USEFLAGS="vaapi vdpau -kde gtk egl X gles2 x264 x265 v4l grub zeroconf cups bluetooth vulkan pipewire wayland networkmanager pulseaudio" configure_portage
	print_success "Done !"

	print_info "Setting DNS info..."
	set_dns
	print_success "Done !"

	print_info "Building BASE stage..."
	setup_chroot
	cat <<EOF | chroot .
eix-sync

rm -rf /etc/portage/package.accept_keywords/*
rm -rf /etc/portage/package.use/*

EOF

	echo "gnome-extra/evolution-data-server ~amd64" >>etc/portage/package.accept_keywords/evolution-data-server
	echo "media-gfx/gnome-photos ~amd64" >>etc/portage/package.accept_keywords/gnome-photos
	echo "gui-apps/gnome-console ~amd64" >>etc/portage/package.accept_keywords/gnome-console
	echo "x11-libs/libdrm ~amd64" >>etc/portage/package.accept_keywords/libdrm
	echo "gnome-extra/gnome-software ~amd64" >>etc/portage/package.accept_keywords/gnome-software

	echo "x11-libs/libdrm video_cards_intel video_cards_radeon" >>etc/portage/package.use/libdrm
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
	echo "net-wireless/wpa_supplicant -qt5" >>etc/portage/package.use/wpa_supplicant
	echo "app-text/mupdf -opengl -X" >>etc/portage/package.use/mupdf
	echo "media-video/pipewire sound-server" >>etc/portage/package.use/pipewire
	echo "media-sound/pulseaudio -daemon" >>etc/portage/package.use/pulseaudio

	cat <<EOF | chroot .
emerge -quDN @world
EOF

	install_packages gnome-menus media-fonts/fonts-meta media-fonts/noto-emoji gnome-software sys-apps/flatpak gnome-browser-connector gnome-tweaks gnome-extra/mousetweaks evince gnome-contacts totem gnome-keyring gnome-text-editor gnome-calendar gnome-maps gnome-weather gnome-music cheese baobab gnome-disk-utility gnome-photos gjs gnome-control-center gnome-core-libs gnome-session gnome-settings-daemon gnome-shell gvfs nautilus cantarell gnome-console adwaita-icon-theme gnome-backgrounds gnome-themes-standard mutter firefox-bin thunderbird-bin eog sys-firmware/sof-firmware
	enable_services nvidia-hibernate nvidia-resume nvidia-suspend gdm NetworkManager bluetooth avahi-daemon cups

	cat <<EOF | chroot .
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
EOF

	cat <<EOF > etc/modprobe.d/nvidia-wayland-gnome.conf
options nvidia-drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF

	wget https://github.com/lassekongo83/adw-gtk3/releases/download/v4.9/adw-gtk3v4-9.tar.xz
	BASE_DIR=$PWD
	cd usr/share/themes
	tar -xf $BASE_DIR/adw-gtk3*.tar.xz
	cd $BASE_DIR
	rm adw-gtk3*.tar.xz
    unmount_chroot
}
