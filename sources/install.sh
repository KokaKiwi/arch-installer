#!/bin/bash

ROOT_DIR=$(readlink -e $(dirname $0))

for lib in $ROOT_DIR/libs/*; do
    . $lib
done

# ===== BASE CONFIG =====

INSTALL_DIR=$(readlink -e $(dirname $0))
ARCHI=$(uname -m)

# ===== UTIL FUNCTIONS =====

print_config() {
    echo "=========== LOCAL CONFIGURATION ==========="
    echo "Install directory         : $INSTALL_DIR"
    echo "Arch minimal directory    : $ARCH_MINI"
    echo "Arch system directory     : $ARCH_SYS"
    echo "Architecture type         : $ARCHI"
    if [[ "$use_device" == "yes" ]]; then
    echo "Install device            : $install_device"
    fi
    echo "==========================================="
}

mount_init() {
    sudo mount -B /proc "$1/proc"
    sudo mount -B /dev "$1/dev"
    sudo mount -B /sys "$1/sys"
}

umount_init() {
    sudo umount $1/{proc,dev,sys}
}

# ===== USER INPUT =====

INSTALL_DIR=$(prompt_dir "Install directory" "$INSTALL_DIR")
while [[ -z "$INSTALL_DIR" ]]; do
    INSTALL_DIR=$(prompt_dir "Install directory" "$INSTALL_DIR")
done
ARCH_MINI="$INSTALL_DIR/tmp_arch"
ARCH_SYS="$ARCH_MINI/mnt"

use_device=$(ask "Use install device?")

if [[ "$use_device" == "yes" ]]; then
    while [[ -z "$install_device" ]]; do
        install_device=$(prompt_dir "Install device (ex: /dev/sdaX)")
        if [[ ! -b "$install_device" ]]; then
            install_device=""
        fi
    done
fi

print_config

if [[ "$(ask "Continue?")" == "no" ]]; then
    exit 0
fi

echo ""

sudo -v

# ===== INSTALL =====

echo "Creating directories..."
rm -rf "$ARCH_MINI"
mkdir "$ARCH_MINI"
cd "$ARCH_MINI"

echo "Downloading minimal system file..."
download "http://mir.archlinux.fr/~tuxce/chroot/archlinux.chroot.$ARCHI.tgz"
checkcmd
tar -zxf "archlinux.chroot.$ARCHI.tgz"
checkcmd
rm -rf archlinux.chroot.$ARCHI.tgz
cd "$INSTALL_DIR"

echo "Installing minimal system..."
sudo cp /etc/resolv.conf "$ARCH_MINI/etc/resolv.conf"
checkcmd
mount_init "$ARCH_MINI"
checkcmd

if [[ "$use_device" == "yes" ]]; then
    echo "Mounting install device..."
    sudo mount "$install_device" "$ARCH_SYS"
fi

sudo mkdir -p "$ARCH_SYS"/var/{cache/pacman/pkg,lib/pacman} "$ARCH_SYS"/{dev,proc,sys,run,tmp,etc,boot,root}
mount_init "$ARCH_SYS"
checkcmd

template "$ROOT_DIR/minimal.d" > $ROOT_DIR/archmini_install.sh
sudo cp $ROOT_DIR/archmini_install.sh $ARCH_MINI/root/archmini_install.sh

sudo chroot "$ARCH_MINI" /bin/bash /root/archmini_install.sh
rm $ARCH_MINI/root/archmini_install.sh
umount_init "$ARCH_MINI"
checkcmd

template "$ROOT_DIR/system.d" > $ROOT_DIR/archsys_install.sh
sudo cp $ROOT_DIR/archsys_install.sh $ARCH_MINI/root/archsys_install.sh

sudo chroot "$ARCH_SYS" /bin/bash /root/archsys_install.sh
rm $ARCH_SYS/root/archsys_install.sh
umount_init "$ARCH_SYS"
checkcmd

