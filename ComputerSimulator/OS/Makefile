# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

all: bin/linux-noinitrd.bzImage bin/rootfs.img

LINUX_VERSION=6.12.57

bin/linux-$(LINUX_VERSION):
	[ -f bin/linux-$(LINUX_VERSION).tar.gz ] || wget -O bin/linux-$(LINUX_VERSION).tar.gz https://www.kernel.org/pub/linux/kernel/v6.x/linux-$(LINUX_VERSION).tar.gz
	cd bin && tar -xzf linux-$(LINUX_VERSION).tar.gz

bin/linux-noinitrd.bzImage: build-kernel.sh build-kernel.config bin/linux-$(LINUX_VERSION)
	bash build-kernel.sh $(LINUX_VERSION)

bin/rootfs.img: build-rootfs.sh computer_system_controller.cpp factory_control.py
	bash build-rootfs.sh
