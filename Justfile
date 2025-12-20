# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

run: build
	godot project.godot

build: init-submodules build-gdspice build-qemu-images build-addons-godot-xterm build-manual build-addons-gdcef
	mkdir -p imported

build-windows-libs:
	@ WINDOWS=true just build-gdspice build-addons-godot-xterm build-addons-gdcef

init-submodules:
	#!/bin/sh -e
	echo '{{BOLD + YELLOW}} Init git submodules {{NORMAL}}'
	git submodule update --init

build-godot-cpp: init-submodules
	#!/bin/sh -e
	echo '{{BOLD + YELLOW}} Build godot-cpp {{NORMAL}}'
	cd addons/3rdparty/_godot-cpp/
	git submodule update --init .
	if [ "$WINDOWS" = "true" ]; then
		[ -f bin/libgodot-cpp.windows.template_debug.x86_64.a ] || scons platform=windows arch=x86_64
		[ -f bin/libgodot-cpp.windows.template_release.x86_64.a ] || ln -sr bin/libgodot-cpp.windows.template_debug.x86_64.a bin/libgodot-cpp.windows.template_release.x86_64.a
	else
		[ -f bin/libgodot-cpp.linux.template_debug.x86_64.a ] || scons
		[ -f bin/libgodot-cpp.linux.template_release.x86_64.a ] || ln -sr bin/libgodot-cpp.linux.template_debug.x86_64.a bin/libgodot-cpp.linux.template_release.x86_64.a
	fi

build-gdspice: build-godot-cpp
	#!/bin/sh -e
	echo '{{BOLD + YELLOW}} Build gdSpice {{NORMAL}}'
	cd ElectronicsSimulator/GdSpice/
	if [ "$WINDOWS" = "true" ]; then
		scons platform=windows arch=x86_64
	else
		scons
	fi

build-qemu-images:
	#!/bin/sh -e
	echo '{{BOLD + YELLOW}} Build qemu images {{NORMAL}}'
	cd ComputerSimulator/OS/
	make

build-addons-godot-xterm: build-godot-cpp
	#!/bin/sh -e
	echo '{{BOLD + YELLOW}} Build GodotXterm {{NORMAL}}'
	cd addons/3rdparty/godot-xterm/
	if [ "$WINDOWS" = "true" ]; then
		cd addons/godot_xterm/native/
		scons platform=windows arch=x86_64 build_library=False no_pty=True
	else
		SCONSFLAGS="build_library=False" just
	fi

build-manual:
	#!/bin/sh -e
	echo '{{BOLD + YELLOW}} Build manual pages {{NORMAL}}'
	cd Manual/
	scons

build-addons-gdcef: build-godot-cpp
	#!/bin/sh -e
	echo '{{BOLD + YELLOW}} Build gdCef {{NORMAL}}'
	cd addons/3rdparty/gdcef/
	
	if [ "$WINDOWS" = "true" ]; then
		(
			cd build/
			if [ -f Windows/GDCEF_VERSION.txt ]; then
				exit
			fi
			wget https://github.com/Lecrapouille/gdcef/releases/download/v0.17.0-godot4/gdCEF-0.17.0_Godot-4.3_Windows_X64.tar.gz
			tar -xzf gdCEF-0.17.0_Godot-4.3_Windows_X64.tar.gz
			rm -fr build/Windows
			mv cef_artifacts/ Windows
			rm gdCEF-0.17.0_Godot-4.3_Windows_X64.tar.gz
		)
	else
		(
			cd addons/gdcef/
			
			if [ ! -d thirdparty/godot-4.3/cpp/ ]; then
				mkdir -p thirdparty/godot-4.3/
				ln -s {{justfile_directory()}}/addons/3rdparty/_godot-cpp/ thirdparty/godot-4.3/cpp
			fi
			
			while read p i; do
				pip3 show $p > /dev/null
			done < requirements.txt
			
			/usr/bin/env python3 build.py
		)
		
		mkdir -p build/
		rm -fr build/Linux
		mv cef_artifacts/ build/Linux
		
		(
			cd  build/
			ln -sf Linux _current_platform_
		)
	fi
