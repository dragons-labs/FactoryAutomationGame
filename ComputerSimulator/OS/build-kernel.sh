# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

set -e

SRC_DIR="$PWD/bin/linux-$1/"
BIN_DIR="$PWD/bin/linux-noinitrd"
CONFIG_FILE="$PWD/build-kernel.config"

cd "$SRC_DIR"

make O="$BIN_DIR" allnoconfig

./scripts/kconfig/merge_config.sh -n -O "$BIN_DIR" "$CONFIG_FILE"

make O="$BIN_DIR" -j bzImage

cp "$BIN_DIR/arch/x86/boot/bzImage" "$BIN_DIR.bzImage"

mkdir -p "$BIN_DIR.bzImage.copyright"
cp -r "$SRC_DIR"/LICENSES/* "$SRC_DIR"/{COPYING,CREDITS} "$BIN_DIR.bzImage.copyright"
