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
		sed -i "/EMERGE_DEFAULT_OPTS/d" etc/portage/make.conf
		echo "EMERGE_DEFAULT_OPTS=\"--jobs $PARALLEL_JOBS\"" >>etc/portage/make.conf
	fi
	sed -i "/INPUT_DEVICES/d" etc/portage/make.conf
	echo "INPUT_DEVICES=\"libinput keyboard mouse\"" >>etc/portage/make.conf
	sed -i "/VIDEO_CARDS/d" etc/portage/make.conf
	echo "VIDEO_CARDS=\"amdgpu i915 i965 nouveau nvidia osmesa r100 r200 radeonsi radeon swrast virgl\"" >>etc/portage/make.conf
	sed -i "/FEATURES/d" etc/portage/make.conf
	echo "FEATURES=\"parallel-fetch noinfo nodoc parallel-install candy unmerge-orphans\"" >>etc/portage/make.conf
	sed -i "/USE/d" etc/portage/make.conf
	echo "USE=\"$USEFLAGS\"" >>etc/portage/make.conf
	sed -i "/MAKEOPTS/d" etc/portage/make.conf
	echo "MAKEOPTS=\"-j$MAKEJOBS\"" >>etc/portage/make.conf
	sed -i "/ACCEPT_LICENSE/d" etc/portage/make.conf
	echo "ACCEPT_LICENSE=\"*\"" >>etc/portage/make.conf
}

enable_services() {
	cat <<EOF | chroot .
systemctl enable $@
EOF
}

set_dns() {
	cp --dereference /etc/resolv.conf etc/
}

install_packages() {
	cat <<EOF | chroot .
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

gen_iso() {
	if [ ! -f cambria-*.iso ]; then
		if [ ! -f install-*.iso ]; then
			print_info "Fetching datas about the latest live CD release."
			wget "https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/latest-install-amd64-minimal.txt"
			LAST_MINIMAL=$(sed -n '/^[0-9]/p' "latest-install-amd64-minimal.txt")
			SIZE=${LAST_MINIMAL##*' '}
			SIZE=$(((${SIZE} + 1048576 / 2) / 1048576))
			LASTPART_URL=${LAST_MINIMAL%%' '*}
			FILE_NAME=${LASTPART_URL##*/}
			print_info "Downloading Gentoo live CD \"$FILE_NAME\", ${SIZE} MiB."
			wget "https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/${LASTPART_URL}"
		fi
		mkdir -p iso
		mount -t iso9660 -o loop install-*.iso iso/
		unsquashfs iso/image.squashfs
		#===== Here we can edit the gentoo file system in squashfs-root/ ==========
		# replace with our own root's .bashrc
		print_info "Editing ISO..."
		ln -s /mnt/gentoo/usr/bin/gum squashfs-root/usr/bin/gum
		rm -f squashfs-root/root/.bashrc
		cat <<EOF >squashfs-root/root/.bashrc
#!/bin/bash
./install.sh
EOF
		mkdir -p squashfs-root/etc/xdg/autostart
		cp post-install/cambria-center.desktop squashfs-root/etc/xdg/autostart/
		cp post-install/cambria-center.sh squashfs-root/usr/bin/cambria-center
		chmod +x squashfs-root/usr/bin/cambria-center
		chmod +x squashfs-root/etc/xdg/autostart/cambria-center.desktop
		cp install.sh squashfs-root/root/install.sh
		chmod +x squashfs-root/root/install.sh
		chmod +x squashfs-root/root/.bashrc
		mksquashfs squashfs-root image.squashfs -b 1024k -comp xz -Xbcj x86 -e boot

		#===== Now we will build the new ISO ======================================
		print_info "New ISO is building..."

		mkdir newiso
		cp -r iso/* newiso/
		rm -rf newiso/efi/boot/*
		rm -f newiso/efi.img
		cp image.squashfs newiso/
		cp $OUTPUT.tar.xz newiso/
		grub-mkrescue -joliet -iso-level 3 -o cambria-${STAGE}.iso newiso

		#===== Let's clean up =====================================================
		rm -f "latest-install-amd64-minimal.txt"
		umount -R iso/
		rm -rf iso/
		rm -rf squashfs-root/
		rm -f image.squashfs
		rm -rf newiso/
	else
		print_info "Generating new ISO from existing ISO."
		mkdir iso
		mount -t iso9660 -o loop cambria-*.iso iso
		mkdir newiso
		cp -r iso/* newiso/
		rm -rf newiso/*.tar.xz
		rm -rf newiso/efi/boot/*
		rm -f newiso/efi.img
		cp $OUTPUT.tar.xz newiso/
		grub-mkrescue -joliet -iso-level 3 -o cambria-${STAGE}.iso newiso
		print_success "Done !"
		print_info "Cleaning up..."
		umount -R iso/
		umount -R final_iso
		rm -rf iso/
		rm -rf newiso/
	fi
}
