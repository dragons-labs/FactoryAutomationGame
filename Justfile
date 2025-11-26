# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

run: build
	godot project.godot

build: init-submodules build-gdspice build-qemu-images build-addons-godot-xterm build-manual build-addons-gdcef

build-windows-libs:
	@ WINDOWS=true just build

init-submodules:
	#!/bin/sh -e
	echo '{{BOLD + YELLOW}} Init git submodules {{NORMAL}}'
	git submodule update --init

build-gdspice: build-addons-godot-xterm 
	#!/bin/sh -e
	echo '{{BOLD + YELLOW}} Build gdSpice {{NORMAL}}'
	cd ElectronicsSimulator/GdSpice/
	scons
	if [ "$WINDOWS" = "true" ]; then
		scons platform=windows arch=x86_64
	fi

build-qemu-images:
	#!/bin/sh -e
	echo '{{BOLD + YELLOW}} Build qemu images {{NORMAL}}'
	cd ComputerSimulator/OS/
	make

build-addons-godot-xterm: init-submodules
	#!/bin/sh -e
	echo '{{BOLD + YELLOW}} Build GodotXterm {{NORMAL}}'
	cd addons/3rdparty/godot-xterm/
	just
	if [ "$WINDOWS" = "true" ]; then
		cd addons/godot_xterm/native/
		scons platform=windows arch=x86_64
	fi

build-manual:
	#!/bin/sh -e
	echo '{{BOLD + YELLOW}} Build manual pages {{NORMAL}}'
	cd Manual/
	scons

build-addons-gdcef: init-submodules
	#!/bin/sh -e
	echo '{{BOLD + YELLOW}} Build gdCef {{NORMAL}}'
	cd addons/3rdparty/gdcef/
	
	(
		cd addons/gdcef/
		while read p i; do
			pip3 show $p > /dev/null
		done < requirements.txt
		
		/usr/bin/env python3 build.py
	)
	
	mkdir -p build/
	rm -fr build/Linux
	mv cef_artifacts/ build/Linux
	
	(cd  build/; ln -sf Linux _current_platform_)
	
	if [ "$WINDOWS" = "true" ]; then (
		cd build/
		wget https://github.com/Lecrapouille/gdcef/releases/download/v0.17.0-godot4/gdCEF-0.17.0_Godot-4.3_Windows_X64.tar.gz
		tar -xzf gdCEF-0.17.0_Godot-4.3_Windows_X64.tar.gz
		rm -fr build/Windows
		mv cef_artifacts/ Windows
		rm gdCEF-0.17.0_Godot-4.3_Windows_X64.tar.gz
	); fi
