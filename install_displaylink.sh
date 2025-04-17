#!/bin/bash

set -e

VERSION="1.14.1"
KERNEL_VER="$(uname -r)"
DL_RUN="displaylink-driver-6.0.0-24.run"
DL_DIR="DisplayLinkExtracted"

echo "== Installing dependencies =="
sudo apt update
sudo apt install -y dkms make gcc linux-headers-"$KERNEL_VER" openssl mokutil

echo "== Extracting DisplayLink package =="
cd ~/Downloads
chmod +x "$DL_RUN"
./"$DL_RUN" --noexec --target "$DL_DIR"

echo "== Copying EVDI source =="
cd "$DL_DIR"
tar -xf evdi.tar.gz
sudo cp -r evdi /usr/src/evdi-"$VERSION"

echo "== Writing dkms.conf =="
sudo tee /usr/src/evdi-"$VERSION"/dkms.conf > /dev/null <<EOF
PACKAGE_NAME="evdi"
PACKAGE_VERSION="$VERSION"
BUILT_MODULE_NAME[0]="evdi"
BUILT_MODULE_LOCATION[0]="module"
DEST_MODULE_LOCATION[0]="/kernel/drivers/gpu/drm/evdi"
MAKE[0]="make -C module KVER=\${kernelver} DKMS_BUILD=1"
CLEAN="make -C module clean"
AUTOINSTALL="yes"
EOF

echo "== Writing Makefile =="
sudo tee /usr/src/evdi-"$VERSION"/module/Makefile > /dev/null <<'EOF'
obj-m := evdi.o
evdi-objs := evdi_platform_drv.o evdi_platform_dev.o evdi_sysfs.o evdi_modeset.o \
             evdi_connector.o evdi_encoder.o evdi_drm_drv.o evdi_fb.o evdi_gem.o \
             evdi_painter.o evdi_params.o evdi_cursor.o evdi_debug.o evdi_i2c.o \
             evdi_ioc32.o

all:
	$(MAKE) -C /lib/modules/$(KERNELRELEASE)/build M=$(PWD) modules

clean:
	$(MAKE) -C /lib/modules/$(KERNELRELEASE)/build M=$(PWD) clean
EOF

echo "== Creating MOK signing keys =="
mkdir -p ~/kernel-signing
cd ~/kernel-signing
openssl req -new -x509 -newkey rsa:2048 -keyout MOK.key -out MOK.crt -nodes -days 36500 -subj "/CN=Module Signer/"
openssl x509 -outform DER -in MOK.crt -out MOK.der
sudo mokutil --import MOK.der

echo "== REBOOT REQUIRED: Enrol the MOK key in the boot menu! =="
read -p "Press [ENTER] when you have rebooted and enrolled the MOK..."

echo "== Adding module to DKMS =="
sudo dkms add -m evdi -v "$VERSION"
sudo dkms build -m evdi -v "$VERSION"
sudo dkms install -m evdi -v "$VERSION"

echo "== Verifying installation =="
modinfo evdi | grep signer
lsmod | grep evdi || sudo modprobe evdi

echo "== Enabling DisplayLink driver =="
sudo systemctl enable displaylink-driver.service
sudo systemctl start displaylink-driver.service

echo "== Done. Run xrandr to confirm display is attached. =="
