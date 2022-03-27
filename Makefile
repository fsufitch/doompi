APT_DEPENDENCIES = curl unzip qemu-system-arm virtinstall libguestfs-tools
RASPI_OS_URL = https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-01-28/2022-01-28-raspios-bullseye-armhf-lite.zip
VM_NAME = doompi-os

# Sourced from https://github.com/dhruvvyas90/qemu-rpi-kernel
QEMU_RPI_KERNEL = kernel/kernel-qemu-5.10.63-bullseye
QEMU_RPI_DTB = kernel/versatile-pb-bullseye-5.10.63.dtb

### RASPI ISO DOWNLOAD
zip_download = downloads/raspios.zip
$(zip_download):
	mkdir -p $$(dirname $(zip_download))
	curl $(RASPI_OS_URL) -o $(zip_download)

### BASE OS IMAGE
os_img = os/raspios.img
$(os_img): $(zip_download)
	mkdir -p $$(dirname $(os_img))
	sh -c ' \
		IMGFILE=$$(unzip -l $(zip_download) | grep -oe "[^ ]*.img" | head -n 1) \
		unzip -p $(zip_download) $$IMGFILE > $(os_img) \
	'
	qemu-img resize $(os_img) 8G

init_image: $(os_img)
clean_image:
	rm -f $(os_img)

.PHONY: init_image clean_image

### BUILD HOST AND GUEST BUILDER BINARIES

builder_host_bin = os/doompi-builder-host.bin
builder_host_bin_fullpath = $(shell echo $$(pwd)/$(builder_host_bin))
$(builder_host_bin): $(shell find builder-host/)
	cd builder-host && go build -o $(builder_host_bin_fullpath)

builder_guest_bin = os/doompi-builder-guest.bin
builder_guest_bin_fullpath = $(shell echo $$(pwd)/$(builder_guest_bin))
$(builder_guest_bin):
	cd builder-guest && GOARCH=arm GOOS=linux go build -o '$(builder_guest_bin_fullpath)'

builder_host: $(builder_host_bin)
builder_guest: $(builder_guest_bin)
builders: builder_host builder_guest
clean_builders: $(shell find builder-guest/)
	rm -f $(builder_host_bin) $(builder_guest_bin)
.PHONY: builder_host builder_guest builders clean_builders

### RUN HOST BUILDER

buildenv = VM_NAME=$(VM_NAME) IMAGE=$(os_img) KERNEL=$(QEMU_RPI_KERNEL) DTB=$(QEMU_RPI_DTB) GUEST_BUILDER_BIN=$(builder_guest_bin)
build: $(os_img) $(builder_host_bin) $(builder_guest_bin)
	$(buildenv) $(builder_host_bin)
.PHONY: build

### INSTALL THE VM

run-vm: init_image
	qemu-system-arm \
		-name $(VM_NAME) \
		-machine versatilepb \
		-cpu arm1176 \
		-m 256 \
		-drive "file=$(os_img),format=raw" \
		-append "root=/dev/sda2 console=ttyAMA0,115200 rootfstype=ext4 rw" \
		-kernel '$(QEMU_RPI_KERNEL)' \
		-dtb '$(QEMU_RPI_DTB)' \
		-nographic -serial stdio -monitor none \
		-no-reboot

.PHONY: vm

### SYSTEM DEPENDENCIES

ensure-golang:
	@go version || (echo "Could not run 'go', please install it to PATH." && exit 1)

dependencies: ensure-golang
	sudo -n apt-get install -qq $(APT_DEPENDENCIES)
.PHONY: dependencies ensure-golang

### Default

all:
	echo nothing