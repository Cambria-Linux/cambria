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
		echo "EMERGE_DEFAULT_OPTS=\"--jobs $PARALLEL_JOBS\"" >>etc/portage/make.conf
	fi
	echo "INPUT_DEVICES=\"libinput keyboard mouse\"" >>etc/portage/make.conf
	echo "VIDEO_CARDS=\"amdgpu i915 i965 nouveau nvidia osmesa r100 r200 radeonsi radeon swrast virgl\"" >>etc/portage/make.conf
	echo "FEATURES=\"parallel-fetch noinfo nodoc parallel-install candy unmerge-orphans\"" >>etc/portage/make.conf
	echo "USE=\"$USEFLAGS\"" >>etc/portage/make.conf
	echo "MAKEOPTS=\"$MAKEOPTS\"" >>etc/portage/make.conf
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
		rm -f squashfs-root/root/.bashrc
		cat <<EOF >squashfs-root/root/.bashrc
#!/bin/bash
./install.sh
EOF
		cp install.sh squashfs-root/root/install.sh
		chmod +x squashfs-root/root/install.sh
		chmod +x squashfs-root/root/.bashrc
		mksquashfs squashfs-root image.squashfs -b 1024k -comp xz -Xbcj x86 -e boot

		#===== Now we will build the new ISO ======================================
		print_info "New ISO is building..."
		#===== Generate GRUB image ================================================
		BOOT_IMG_DATA=$(mktemp -d)
		BOOT_IMG=$(mktemp -d)/efi.img

		mkdir -p $(dirname $BOOT_IMG)

		truncate -s 8M $BOOT_IMG
		mkfs.vfat $BOOT_IMG
		mount $BOOT_IMG $BOOT_IMG_DATA
		mkdir -p $BOOT_IMG_DATA/efi/boot

		grub-mkimage \
			-C xz \
			-O x86_64-efi \
			-p /boot/grub \
			-o $BOOT_IMG_DATA/efi/boot/bootx64.efi \
			boot linux search normal configfile \
			part_gpt btrfs ext2 fat iso9660 loopback \
			test keystatus gfxmenu regexp probe \
			efi_gop efi_uga all_video gfxterm font \
			echo read ls cat png jpeg halt reboot

		umount $BOOT_IMG_DATA
		rm -rf $BOOT_IMG_DATA
		mkdir newiso
		mkdir -p newiso/boot/grub
		cp iso/boot/gentoo* newiso/boot/
		mkdir -p newiso/efi
		cp $BOOT_IMG newiso/efi/esp.img
		cat <<EOF >newiso/boot/grub/grub.cfg
set default=0
set gfxpayload=keep
set timeout=10
insmod all_video

menuentry 'Boot LiveCD' --class gnu-linux --class os {
        linux /boot/gentoo dokeymap cdroot_marker=image.squashfs subdir=/ looptype=squashfs loop=/image.squashfs cdroot
        initrd /boot/gentoo.igz
}

menuentry 'Boot LiveCD (cached)' --class gnu-linux --class os {
        linux /boot/gentoo dokeymap cdroot_marker=image.squashfs subdir=/ looptype=squashfs loop=/image.squashfs cdroot
        initrd /boot/gentoo.igz
}
EOF
		cp $OUTPUT newiso/
		cp image.squashfs newiso/
		mkisofs -o cambria-$STAGE.iso -R -J -v -d -N -x cambria-$STAGE.iso -hide-rr-moved -no-emul-boot -eltorito-platform efi -eltorito-boot efi/esp.img -V "CAMBRIA$STAGE" -A "Cambria $STAGE" newiso/

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
		cp $OUTPUT newiso/
		mkisofs -o cambria-$STAGE.iso -R -J -v -d -N -x cambria-$STAGE.iso -hide-rr-moved -no-emul-boot -eltorito-platform efi -eltorito-boot efi/esp.img -V "CAMBRIA$STAGE" -A "Cambria $STAGE" newiso/
		print_success "Done !"
		print_info "Cleaning up..."
		umount iso
		rm -rf iso
		rm -rf newiso
	fi
}
