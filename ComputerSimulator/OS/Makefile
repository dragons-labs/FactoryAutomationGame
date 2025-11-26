# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

all: bin/linux-noinitrd.bzImage bin/rootfs.img

bin/linux-noinitrd.bzImage: build-kernel.sh build-kernel.config
	./build-kernel.sh

bin/rootfs.img: build-rootfs.sh computer_system_controller.cpp factory_control.py
	./build-rootfs.sh
