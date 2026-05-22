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
	# only init and checkout on empty submodule directory, DO NOT checkout on already checkouted submodule
	git submodule status | while read a b c; do [ -z "$( ls -A "$b" )" ] && git submodule update --init $b; done || true

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
	
	if ! LANG=C patch --dry-run -t -p1 < ../gdcef-no-dbus.patch | grep 'Reversed (or previously applied) patch detected' > /dev/null; then
		patch -t -p1 < ../gdcef-no-dbus.patch
	fi
	
	if [ "$WINDOWS" = "true" ]; then
		(
			mkdir -p cef_artifacts
			cd cef_artifacts/
			if [ -f windows/libgdcef.dll ]; then
				exit
			fi
			tempdir=`mktemp -d`
			(
				cd "$tempdir"
				wget https://github.com/Lecrapouille/gdcef/releases/download/v0.19.2-godot4/gdcef-0.19.2_godot-4.5.zip
				unzip gdcef-0.19.2_godot-4.5.zip
			)
			mv "$tempdir/gdcef/cef_artifacts/windows" .
			rm -fr "$tempdir"
			# use `locales` dir from 0.18.1 - BUG https://github.com/Lecrapouille/gdcef/issues/92
			tempdir=`mktemp -d`
			(
				cd "$tempdir"
				wget https://github.com/Lecrapouille/gdcef/releases/download/v0.18.1-godot4/gdCEF-0.18.1_Godot-4.5_Windows_X64.tar.gz
				tar -xzf gdCEF-0.18.1_Godot-4.5_Windows_X64.tar.gz
			)
			mv "$tempdir/cef_artifacts/locales" locales-win
			rm -fr "$tempdir"
		)
	else
		(
			while read p i; do
				pip3 show $p > /dev/null
			done < requirements.txt
			
			/usr/bin/env python3 build.py
			
			echo '/sbin/ldconfig -p | grep libGL.so.1 > /dev/null; exit $?' > cef_artifacts/linux/check_libGL.sh
			chmod +x cef_artifacts/linux/check_libGL.sh
		)
	fi
