print_info() {
    echo -e "\e[1;36m$1\e[0m"
}

print_err() {
    echo -e "\e[1;31m$1\e[0m"
}

print_success() {
    echo -e "\e[1;32m$1\e[0m"
}

extract_stage() {
    tar xpf $1 --xattrs-include='*.*' --numeric-owner
}

configure_portage() {
    if [ "$PARALLEL_BUILD" == "1" ]; then
        echo "EMERGE_DEFAULT_OPTS=\"--jobs $PARALLEL_JOBS\"" >> etc/portage/make.conf
    fi
    echo "INPUT_DEVICES=\"libinput keyboard mouse\"" >>etc/portage/make.conf
    echo "VIDEO_CARDS=\"amdgpu i915 i965 nouveau nvidia osmesa r100 r200 radeonsi radeon swrast virgl\"" >> etc/portage/make.conf
    echo "FEATURES=\"parallel-fetch noinfo nodoc parallel-install candy unmerge-orphans\"" >> etc/portage/make.conf
    echo "USE=\"$USEFLAGS\"" >> etc/portage/make.conf
    echo "MAKEOPTS=\"$MAKEOPTS\"" >> etc/portage/make.conf
    echo "ACCEPT_LICENSE=\"*\"" >> etc/portage/make.conf
}

set_dns() {
    cp --dereference /etc/resolv.conf etc/
}

install_packages() {
    cat << EOF | chroot .
emerge -q  --selective=y $@ --autounmask-write
EOF
}

clean() {
    rm -rf build
    mkdir build
    cd build
}

compress_build() {
    tar -c -I 'xz -9 -T0' -f ../$OUTPUT.tar.xz .
}

setup_chroot() {
    mount --types proc /proc proc
    mount --rbind /sys sys
    mount --make-rslave sys
    mount --rbind /dev dev
    mount --make-rslave dev
    mount --bind /run run
    mount --make-slave run
}

unmount_chroot() {
    umount -R *
}

clean_cache() {
    rm -rf var/cache/distfiles/*
}

clean_dev() {
    rm -rf dev/*
}
