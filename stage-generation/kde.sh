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
}