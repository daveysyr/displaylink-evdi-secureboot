# displaylink-evdi-secureboot
Getting a Targus 190 working on Linux and making a script that can be run to automate that.



# DisplayLink + EVDI Installation with Secure Boot on Ubuntu

This repository provides a scripted method for installing the DisplayLink driver and EVDI kernel module on Ubuntu with Secure Boot enabled. It supports persistence across kernel updates using DKMS.

## Features

- Supports Secure Boot via MOK key signing
- DKMS setup for automatic rebuild on kernel upgrade
- Compatible with modern Ubuntu kernels
- Fully scripted installation

## Requirements

- Ubuntu with Secure Boot enabled
- Kernel headers installed for your current kernel:
  ```bash
  sudo apt install linux-headers-$(uname -r)


GCC and build tools:

sudo apt install build-essential

mokutil and dkms:

    sudo apt install mokutil dkms

Installation Steps
1. Clone this repository

git clone https://github.com/youruser/displaylink-evdi-secureboot.git
cd displaylink-evdi-secureboot

2. Run the installer

chmod +x install.sh
./install.sh

This script:

    Extracts the DisplayLink .run file

    Builds and signs EVDI using your MOK

    Installs the module via DKMS

    Prompts for MOK enrolment if necessary

3. Reboot and enrol the MOK

On next boot, your system will prompt you to enrol the MOK key. Follow the on-screen instructions.
Secure Boot Key Generation

If you don’t provide mok/MOK.priv and mok/MOK.der, the script will generate them for you and import the public key.

To generate your own:

mkdir -p mok
openssl req -new -x509 -newkey rsa:2048 -keyout mok/MOK.priv -out mok/MOK.crt -nodes -days 36500 -subj "/CN=Module Signer/"
openssl x509 -in mok/MOK.crt -outform DER -out mok/MOK.der

Notes

    Tested on kernel 6.11.0-24-generic

    This assumes evdi source is embedded in DisplayLink .run file

    You must re-run the script after kernel header updates if DKMS fails

    If pyevdi fails, it will be skipped (optional component)

Troubleshooting

If modprobe evdi fails after a kernel upgrade:

sudo dkms autoinstall

If your second monitor doesn’t appear:

sudo systemctl restart displaylink-driver.service

Use at your own risk. This repo is provided for convenience but involves low-level kernel and bootloader changes.
