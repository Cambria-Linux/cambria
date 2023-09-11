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
    USEFLAGS="vaapi amf kde cleartype corefonts nvenc matroska vdpau -gnome egl X gles2 x264 x265 v4l grub zeroconf cups bluetooth vulkan pipewire wayland networkmanager pulseaudio" configure_portage
    print_success "Done !"

    print_info "Setting DNS info..."
    set_dns
    print_success "Done !"

    print_info "Building $STAGE stage..."

rm -rf etc/portage/repos.conf/eselect-repo.conf

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
    setup_chroot
    cat <<EOF | chroot .

eix-sync

rm -rf /etc/portage/package.accept_keywords/*
rm -rf /etc/portage/package.use/*

EOF
    echo "net-im/discord ~amd64" >>etc/portage/package.accept_keywords/discord
    echo "media-libs/mesa ~amd64" >>etc/portage/package.accept_keywords/mesa
    echo "sys-kernel/linux-firmware ~amd64" >> etc/portage/package.accept_keywords/linux-firmware
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
    cat <<EOF | chroot .
emerge -quDN @world
EOF

    install_packages kde-plasma/plasma-meta sys-block/partitionmanager media-video/obs-studio kde-apps/kdenlive kde-apps/kate net-im/discord kde-apps/konsole kde-apps/okular kde-apps/dolphin sys-libs/kpmcore kde-apps/gwenview kde-apps/ark kde-apps/kcalc kde-misc/kweather kde-apps/print-manager kde-apps/spectacle www-client/firefox-bin mail-client/thunderbird-bin app-emulation/wine-staging games-util/game-device-udev-rules sys-libs/libudev-compat games-util/steam-client-meta games-util/steam-launcher games-util/steam-meta games-util/lutris app-office/libreoffice-bin
    enable_services sddm NetworkManager bluetooth avahi-daemon cups

    cat <<EOF | chroot .
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
EOF
    unmount_chroot
}
