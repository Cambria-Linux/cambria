#===================================================
# The KDE stage generation script. !!!!! WORK ONLY WITH SYSTEM-WIDE X32 !!!!!
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
    USEFLAGS="vaapi mtp amf kde cleartype corefonts nvenc matroska vdpau -gnome egl X gles2 x264 x265 v4l grub zeroconf cups bluetooth vulkan pipewire wayland networkmanager pulseaudio" configure_portage
    print_success "Done !"

    print_info "Setting DNS info..."
    set_dns
    print_success "Done !"

    print_info "Building $STAGE stage..."

rm -rf etc/portage/repos.conf/eselect-repo.conf
rm -rf etc/portage/package.accept_keywords/*
rm -rf etc/portage/package.use/*

    cat <<EOF >> etc/portage/repos.conf/eselect-repo.conf
[gentoo]
location = /var/db/repos/gentoo
sync-type = git
sync-uri = https://github.com/gentoo-mirror/gentoo.git

[steam-overlay]
location = /var/db/repos/steam-overlay
sync-type = git
sync-uri = https://github.com/gentoo-mirror/steam-overlay.git
EOF

    cat <<EOF >> etc/portage/package.use/lib32
x11-libs/libXcursor abi_x86_32
x11-libs/libXfixes abi_x86_32
x11-libs/libXi abi_x86_32
x11-libs/libXrandr abi_x86_32
x11-libs/libXrender abi_x86_32
x11-libs/libXxf86vm abi_x86_32
media-libs/libglvnd abi_x86_32
x11-libs/libXcomposite abi_x86_32
net-print/cups abi_x86_32
media-libs/fontconfig abi_x86_32
media-libs/libsdl2 abi_x86_32
net-libs/gnutls abi_x86_32
media-libs/freetype abi_x86_32
sys-apps/dbus abi_x86_32
media-libs/libv4l abi_x86_32
media-libs/vulkan-loader abi_x86_32
x11-libs/libX11 abi_x86_32
x11-libs/libXext abi_x86_32
media-libs/alsa-lib abi_x86_32
dev-libs/glib abi_x86_32
media-libs/gst-plugins-base abi_x86_32
media-libs/gstreamer abi_x86_32
media-libs/libpulse abi_x86_32
sys-libs/libunwind abi_x86_32
dev-libs/libusb abi_x86_32
media-plugins/gst-plugins-dvdread abi_x86_32
media-libs/gst-plugins-ugly abi_x86_32
dev-libs/wayland abi_x86_32
media-plugins/gst-plugins-meta abi_x86_32
media-libs/gst-plugins-good abi_x86_32
media-plugins/gst-plugins-a52dec abi_x86_32
media-plugins/gst-plugins-faad abi_x86_32
media-plugins/gst-plugins-dts abi_x86_32
media-plugins/gst-plugins-mpeg2dec abi_x86_32
media-plugins/gst-plugins-resindvd abi_x86_32
media-plugins/gst-plugins-flac abi_x86_32
media-plugins/gst-plugins-mpg123 abi_x86_32
media-plugins/gst-plugins-pulse abi_x86_32
media-plugins/gst-plugins-v4l2 abi_x86_32
media-plugins/gst-plugins-vaapi abi_x86_32
media-plugins/gst-plugins-x264 abi_x86_32
media-libs/gst-plugins-bad abi_x86_32
media-libs/x264 abi_x86_32
media-libs/libva abi_x86_32
x11-libs/libdrm abi_x86_32
media-libs/mesa abi_x86_32
sys-libs/zlib abi_x86_32
dev-libs/expat abi_x86_32
x11-libs/libxcb abi_x86_32
x11-libs/libvdpau abi_x86_32
x11-libs/libxshmfence abi_x86_32
app-arch/zstd abi_x86_32
sys-devel/llvm abi_x86_32
dev-libs/libffi abi_x86_32
sys-libs/ncurses abi_x86_32
dev-libs/libxml2 abi_x86_32
dev-libs/icu abi_x86_32
x11-libs/libXau abi_x86_32
x11-libs/libXdmcp abi_x86_32
x11-libs/libpciaccess abi_x86_32
app-arch/bzip2 abi_x86_32
dev-lang/orc abi_x86_32
dev-libs/libgudev abi_x86_32
media-sound/mpg123 abi_x86_32
media-libs/flac abi_x86_32
media-libs/libogg abi_x86_32
media-libs/libdvdnav abi_x86_32
media-libs/libdvdread abi_x86_32
media-libs/libdvdcss abi_x86_32
media-libs/libmpeg2 abi_x86_32
media-libs/libdca abi_x86_32
media-libs/faad2 abi_x86_32
media-libs/a52dec abi_x86_32
media-libs/libsndfile abi_x86_32
net-libs/libasyncns abi_x86_32
sys-libs/libcap abi_x86_32
sys-libs/pam abi_x86_32
x11-libs/pango abi_x86_32
media-libs/libvorbis abi_x86_32
x11-libs/libXv abi_x86_32
media-libs/graphene abi_x86_32
media-libs/libpng abi_x86_32
media-libs/libjpeg-turbo abi_x86_32
dev-libs/fribidi abi_x86_32
media-libs/harfbuzz abi_x86_32
x11-libs/cairo abi_x86_32
x11-libs/libXft abi_x86_32
dev-libs/lzo abi_x86_32
x11-libs/pixman abi_x86_32
media-gfx/graphite2 abi_x86_32
dev-libs/libpcre2 abi_x86_32
sys-apps/util-linux abi_x86_32
dev-libs/libtasn1 abi_x86_32
dev-libs/libunistring abi_x86_32
dev-libs/nettle abi_x86_32
dev-libs/gmp abi_x86_32
net-dns/libidn2 abi_x86_32
media-video/pipewire abi_x86_32
x11-libs/libxkbcommon abi_x86_32
net-dns/avahi abi_x86_32
dev-libs/libevent abi_x86_32
sys-libs/gdbm abi_x86_32
sys-libs/readline abi_x86_32
dev-libs/openssl abi_x86_32
virtual/libintl abi_x86_32
virtual/libudev abi_x86_32
sys-apps/systemd abi_x86_32
dev-libs/libgcrypt abi_x86_32
app-arch/lz4 abi_x86_32
dev-libs/libgpg-error abi_x86_32
virtual/libiconv abi_x86_32
virtual/opengl abi_x86_32
virtual/glu abi_x86_32
media-libs/glu abi_x86_32
virtual/jpeg abi_x86_32
virtual/libelf abi_x86_32
dev-libs/elfutils abi_x86_32
media-plugins/gst-plugins-cdparanoia abi_x86_32
media-sound/cdparanoia abi_x86_32
sys-libs/libudev-compat abi_x86_32
x11-drivers/nvidia-drivers abi_x86_32
EOF

    setup_chroot
    cat <<EOF | chroot .

eix-sync

EOF
    echo "net-im/discord ~amd64" >>etc/portage/package.accept_keywords/discord
    echo "app-emulation/wine-staging ~amd64" >> etc/portage/package.accept_keywords/wine
    echo "media-video/obs-studio ~amd64" >> etc/portage/package.accept_keywords/obs
    echo "media-video/v4l2loopback ~amd64" >> etc/portage/package.accept_keywords/v4l2loopback
    echo "app-emulation/wine-gecko ~amd64" >> etc/portage/package.accept_keywords/wine
    echo "app-emulation/wine-mono ~amd64" >> etc/portage/package.accept_keywords/wine
    echo "dev-python/pypresence ~amd64" >> etc/portage/package.accept_keywords/lutris
    echo "dev-python/moddb ~amd64" >> etc/portage/package.accept_keywords/lutris
    echo "dev-python/pyrate-limiter ~amd64" >> etc/portage/package.accept_keywords/lutris
    echo "games-util/lutris ~amd64" >> etc/portage/package.accept_keywords/lutris
    echo "games-util/steam-meta ~amd64" >> etc/portage/package.accept_keywords/steam
    echo "games-util/steam-launcher ~amd64" >> etc/portage/package.accept_keywords/steam
    echo "games-util/steam-client-meta ~amd64" >> etc/portage/package.accept_keywords/steam
    echo "sys-libs/libudev-compat ~amd64" >> etc/portage/package.accept_keywords/steam
    echo "games-util/game-device-udev-rules ~amd64" >> etc/portage/package.accept_keywords/steam


    echo "x11-libs/libdrm video_cards_intel video_cards_radeon" >>etc/portage/package.use/libdrm
    echo "media-libs/libsndfile minimal" >>etc/portage/package.use/libsndfile
    echo "net-dns/avahi -gtk -qt5 mdnsresponder-compat" >>etc/portage/package.use/avahi
    echo "net-wireless/wpa_supplicant -qt5" >>etc/portage/package.use/wpa_supplicant
    echo "app-text/mupdf -opengl -X" >>etc/portage/package.use/mupdf
    echo "kde-plasma/plasma-meta discover display-manager sddm wallpapers" >>etc/portage/package.use/kde
    echo "kde-plasma/discover flatpak" >>etc/portage/package.use/discover
    echo "sys-libs/ncurses -gpm" >>etc/portage/package.use/ncurses
    echo "dev-qt/qtwebengine widgets" >>etc/portage/package.use/qtwebengine
    echo "dev-qt/qtwebchannel qml" >>etc/portage/package.use/qtwebchannel
    echo "sys-libs/zlib minizip" >>etc/portage/package.use/zlib
    echo "kde-frameworks/kconfig qml" >>etc/portage/package.use/kconfig
    echo "kde-frameworks/kitemmodels qml" >>etc/portage/package.use/kitemmodels
    echo "dev-qt/qtcharts qml" >>etc/portage/package.use/qtcharts
    echo "dev-qt/qtpositioning geoclue" >>etc/portage/package.use/qtpositioning
    echo "kde-frameworks/sonnet qml" >>etc/portage/package.use/sonnet
    echo "dev-qt/qtmultimedia qml" >>etc/portage/package.use/qtmultimedia
    echo "media-libs/mlt ffmpeg frei0r" >>etc/portage/package.use/mlt
    echo "media-video/ffmpeg nvenc opus libass" >>etc/portage/package.use/ffmpeg
    echo "media-libs/opencv contrib contribdnn" >>etc/portage/package.use/opencv
    echo "app-text/poppler nss" >>etc/portage/package.use/poppler
    echo "kde-plasma/kwin lock" >>etc/portage/package.use/kwin
    echo "kde-frameworks/prison qml" >>etc/portage/package.use/prison
    echo "media-video/obs-studio browser nvenc decklink fdk jack lua python speex vlc websocket" >>etc/portage/package.use/obs
    echo "kde-apps/kdenlive designer share" >>etc/portage/package.use/kdenlive
    echo "x11-drivers/nvidia-drivers dist-kernel modules tools static-libs" >>etc/portage/package.use/nvidia
    echo "media-libs/libsdl2 haptic" >>etc/portage/package.use/libdsl2
    echo "media-video/pipewire sound-server" >>etc/portage/package.use/pipewire
	echo "media-sound/pulseaudio -daemon" >>etc/portage/package.use/pulseaudio
    cat <<EOF | chroot .
emerge -quDN @world
EOF

    install_packages kde-plasma/plasma-meta sys-block/partitionmanager media-video/obs-studio kde-apps/kdenlive kde-apps/kate net-im/discord kde-apps/konsole kde-apps/okular kde-apps/dolphin sys-libs/kpmcore kde-apps/gwenview kde-apps/ark kde-apps/kcalc kde-misc/kweather kde-apps/print-manager kde-apps/spectacle www-client/firefox-bin mail-client/thunderbird-bin app-emulation/wine-staging games-util/game-device-udev-rules sys-libs/libudev-compat games-util/steam-client-meta games-util/steam-launcher games-util/steam-meta games-util/lutris app-office/libreoffice-bin app-portage/gentoolkit dev-util/vulkan-tools sys-firmware/sof-firmware
    enable_services sddm NetworkManager bluetooth avahi-daemon cups 

    cat <<EOF | chroot .
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
EOF
    unmount_chroot
}
