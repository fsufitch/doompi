APT_DEPENDENCIES = curl unzip qemu-system-arm virtinstall
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

#		-drive 'filename=$(os_img),driver=file,index=0' \
	# sudo -n virt-install \
	# 	--name $(VM_NAME)  \
  	# 	--arch armv6l \
	# 	--cpu arm1176 \
  	# 	--machine versatilepb \
  	# 	--vcpus 1 \
	# 	--memory 512 \
  	# 	--import  \
  	# 	--disk $(os_img),format=raw,bus=virtio \
  	# 	--network bridge,source=virbr0,model=virtio  \
  	# 	--video vga  \
  	# 	--graphics spice \
  	# 	--boot 'dtb=$(QEMU_RPI_DTB),kernel=$(QEMU_RPI_KERNEL),kernel_args=root=/dev/vda2 panic=1' \
  	# 	--events on_reboot=destroy

.PHONY: vm

### SYSTEM DEPENDENCIES

dependencies:
	sudo -n apt-get install -qq $(APT_DEPENDENCIES)
.PHONY: dependencies

### Default

all:
	echo nothing