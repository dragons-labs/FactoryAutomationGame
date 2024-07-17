# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

set -e

SRC_DIR="$PWD/bin/linux-6.6.28/"
BIN_DIR="$PWD/bin/linux-noinitrd"
CONFIG_FILE="$PWD/build-kernel.config"

cd "$SRC_DIR"

make O="$BIN_DIR" allnoconfig

./scripts/kconfig/merge_config.sh -n -O "$BIN_DIR" "$CONFIG_FILE"

make O="$BIN_DIR" -j 5 bzImage

cp "$BIN_DIR/arch/x86/boot/bzImage" "$BIN_DIR.bzImage"
