#!/bin/bash

# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

set -e

PLATFORM=${1:-Linux}
FAST=${2:-false} # if true do not export dependencies

TARGET=$PWD/export/
CEF_ARTIFACTS=addons/3rdparty/gdcef/build/$PLATFORM
INCLUDE='Manual/generated-bbcode/*,*.json,*.circuit,imported/*,addons/limbo_console.cfg'
EXCLUDE='cef_artifacts/cache/*,cef_artifacts/*.json,tmp/*,mods-unpacked/*,reports/*,tests/*,screenshot.jpg,addons/gdUnit4/*,addons/repl/*,addons/script-ide/*,addons/script_ide-last_script_per_scene_tab/*'

# prepare target directory
mkdir -p $TARGET
:> $TARGET/.gdignore

TARGET=$TARGET/FAG_$PLATFORM
$FAST || \rm -fr $TARGET
mkdir -p $TARGET

# fake Windows dll for gdcef ... real file will be added later
[ -f cef_artifacts/libgdcef.dll ] || :> cef_artifacts/libgdcef.dll

# if export for Windows then build windows libs first
if [ "$PLATFORM" = "Windows" ]; then
	if ! [ -f ElectronicsSimulator/GdSpice/bin/libgdspice.windows.template_debug.x86_64.dll ]; then
		just build-windows-libs
	fi
fi

# standard export based on settings from export_presets.cfg
cat << EOF > export_presets.cfg
[preset.0]

name="Linux"
platform="Linux"
runnable=true
advanced_options=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="$INCLUDE"
exclude_filter="$EXCLUDE"
export_path="$TARGET/FactoryAutomation"
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=1
binary_format/embed_pck=false
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
binary_format/architecture="x86_64"
ssh_remote_deploy/enabled=false

[preset.1]

name="Windows"
platform="Windows Desktop"
runnable=true
advanced_options=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="$INCLUDE"
exclude_filter="$EXCLUDE"
export_path="$TARGET/FactoryAutomation"
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.1.options]

custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=1
binary_format/embed_pck=false
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
binary_format/architecture="x86_64"
codesign/enable=false
application/modify_resources=true
application/icon=""
application/console_wrapper_icon=""
application/icon_interpolation=4
application/file_version=""
application/product_version=""
application/company_name=""
application/product_name=""
application/file_description=""
application/copyright=""
application/trademarks=""
application/export_angle=0
application/export_d3d12=0
application/d3d12_agility_sdk_multiarch=true
ssh_remote_deploy/enabled=false
EOF

godot --export-debug $PLATFORM $TARGET/FactoryAutomation
\rm export_presets.cfg

$FAST && exit

# add readme and licence info
cp -r README.md LICENSES $TARGET/

# export images for qemu (must be outside .pck file)
mkdir -p $TARGET/qemu_img
cp qemu_img/*.img qemu_img/*.bzImage $TARGET/qemu_img/

# add kernel and rootfs licence info
for d in qemu_img/*.img.copyright qemu_img/*.bzImage.copyright; do
	cp -r $d $TARGET/LICENSES/$(basename $d .copyright);
done

# export gdcef assemblies (must be outside .pck file)
mkdir -p $TARGET/cef_artifacts/
cp -fr $CEF_ARTIFACTS/* $TARGET/cef_artifacts/
\rm -rf $TARGET/cef_artifacts/cache $TARGET/cef_artifacts/debug.log $TARGET/cef_artifacts/gdcef.gdextension
\rm -f $TARGET/libgdcef.so $TARGET/libgdcef.dll

# add CEF licence info
mkdir -p $TARGET/LICENSES/cef
cp addons/3rdparty/gdcef/addons/gdcef/thirdparty/cef_binary/{CREDITS.html,LICENSE.txt} $TARGET/LICENSES/cef/



# for binary dependencies we are using Debian licences files also for Windows export
# this is not ideal but I haven't found a way to easily extract this information from msys2
extract_licence_info() {
	dst=$1; shift
	mkdir $TARGET/LICENSES/$dst
	for p in $(for p in $@; do dpkg -S $p; done | cut -f1 -d: | sort | uniq); do
		cp /usr/share/doc/$p/copyright $TARGET/LICENSES/$dst/$p.copyright;
	done
	[ -d $TARGET/LICENSES/common-licenses ] || cp -r /usr/share/common-licenses/ $TARGET/LICENSES/
}


# add ngspice binaries

NGSPICE_LIB=$(realpath /usr/lib/x86_64-linux-gnu/libngspice.so)
NGSPICE_DATA=$(realpath /usr/lib/x86_64-linux-gnu/ngspice/*)
NGSPICE_INIT=$(realpath /usr/share/ngspice/scripts/spinit)

mkdir -p $TARGET/ngspice

if [ "$PLATFORM" = "Linux" ]; then
	cp $NGSPICE_DATA $TARGET/ngspice
	cp $NGSPICE_LIB $TARGET/ngspice/libngspice.so
	sed -e 's#/usr/lib/x86_64-linux-gnu/##' $NGSPICE_INIT > $TARGET/ngspice/spinit
elif [ "$PLATFORM" = "Windows" ]; then
	cp -r ElectronicsSimulator/GdSpice/bin/mingw64/lib/ngspice $TARGET/
	cp ElectronicsSimulator/GdSpice/bin/mingw64/bin/{libngspice-0,libfftw3-3,libgcc_s_seh-1,libgomp-1,libwinpthread-1}.dll $TARGET/ngspice/
	sed -e 's#/mingw64/lib/##' ElectronicsSimulator/GdSpice/bin/mingw64/share/ngspice/scripts/spinit > $TARGET/ngspice/spinit
fi

extract_licence_info ngspice $NGSPICE_LIB $NGSPICE_DATA $NGSPICE_INIT


# add qemu binaries

QEMU_BIN="$(realpath /usr/bin/qemu-system-x86_64 $(ldd /usr/bin/qemu-system-x86_64 | awk '{print $3}'))"
QEMU_SHARE=$(realpath /usr/share/seabios/{bios-256k.bin,vgabios-stdvga.bin} /usr/share/qemu/{efi-e1000.rom,efi-virtio.rom,kvmvapic.bin,linuxboot_dma.bin})
QEMU_KEYMAPS=/usr/share/qemu/keymaps/en-us

mkdir -p $TARGET/qemu/share/keymaps/

cp $QEMU_SHARE $TARGET/qemu/share/
cp $QEMU_KEYMAPS $TARGET/qemu/share/keymaps/

if [ "$PLATFORM" = "Linux" ]; then
	cp $QEMU_BIN $TARGET/qemu/
elif [ "$PLATFORM" = "Windows" ]; then
	mkdir -p $TARGET/qemu/bin $TARGET/qemu/share/keymaps
	cp ComputerSimulator/OS/bin/mingw64/bin/qemu-system-x86_64.exe $TARGET/qemu/bin
	cp ComputerSimulator/OS/bin/mingw64/bin/*.dll $TARGET/qemu/bin
fi

extract_licence_info qemu $QEMU_BIN $QEMU_SHARE $QEMU_KEYMAPS


# Windows specific (.exe, add libstdc++-6.dll)

if [ "$PLATFORM" = "Windows" ]; then
	mv $TARGET/FactoryAutomation $TARGET/FactoryAutomation.exe
	cp /usr/lib/gcc/x86_64-w64-mingw32/*-posix/libstdc++-6.dll $TARGET/
fi
