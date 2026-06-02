#!/bin/bash

# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

set -e

PLATFORM=${1:-Linux}
FAST=${2:-false} # if true do not export dependencies

TARGET=/tmp/FAG-export/
CEF_ARTIFACTS=addons/3rdparty/gdcef/cef_artifacts/
INCLUDE='Manual/generated-bbcode/*,*.json,*.circuit,imported/*,addons/limbo_console.cfg'
EXCLUDE='cef_artifacts/cache/*,cef_artifacts/*.json,tmp/*,mods-unpacked/*,reports/*,tests/*,screenshot.jpg,addons/gdUnit4/*,addons/repl/*,addons/script-ide/*,addons/script_ide-last_script_per_scene_tab/*'

# prepare target directory
mkdir -p $TARGET
:> $TARGET/.gdignore

TARGET=$TARGET/FAG_$PLATFORM
$FAST || \rm -fr $TARGET
mkdir -p $TARGET

# if export for Windows then build windows libs first
if [ "$PLATFORM" = "Windows" ]; then
	#QEMU_WIN_BIN=ComputerSimulator/OS/bin/mingw64/bin
	# NOTE: we DO NOT use mingw version of qemu due to lack of virtio-9p (virtfs) support (see https://gitlab.com/qemu-project/qemu/-/issues/2016)
	#       we need virtio-9p (or virtiofs) for shared data between host and multiple in-game computers
	#        - we can't use samba, etc due to default non-network in-game computers
	#        - we can't use `-drive file=fat:rw:/dir/path` due to lack of sync between in-game computers and lack of on-save sync
	QEMU_WIN_BIN=ComputerSimulator/OS/bin/qemu-win-p9fs
	if ! [ -e $QEMU_WIN_BIN/qemu-system-x86_64.exe ]; then
		#sh Utils/msys2_pacman.sh ComputerSimulator/OS/bin mingw-w64-x86_64-qemu
		echo "No qemu binaries found for Windows platform."
		echo "1. Download qemu with 9pfs support from https://github.com/arixmkii/qcw/releases"
		echo "2. Install (or extract) it into ComputerSimulator/OS/bin/qemu-win-p9fs/"
		exit
	fi
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

DBUS_SESSION_BUS_ADDRESS=disabled: godot --headless --export-debug $PLATFORM $TARGET/FactoryAutomation
\rm export_presets.cfg

$FAST && exit

# for binary dependencies we are using Debian licences files also for Windows export
# this is not ideal but I haven't found a way to easily extract this information from msys2
extract_licence_info() {
	dst=$1; shift
	mkdir -p $TARGET/LICENSES/$dst
	for p in $(for p in $@; do dpkg -S $p; done | cut -f1 -d: | sort | uniq); do
		cp /usr/share/doc/$p/copyright $TARGET/LICENSES/$dst/$p.copyright;
	done
	[ -d $TARGET/LICENSES/common-licenses ] || cp -r /usr/share/common-licenses/ $TARGET/LICENSES/
}

create_run_via_ld_script() {
	LD_PATH=${2:-..}
	mv "$TARGET/$1" "$TARGET/$1.elf"
	echo 'cd "$(dirname "$(realpath "$0")")"' > "$TARGET/$1"
	echo '[ -e '$LD_PATH'/ld-linux-x86-64.so.2 ] && echo "using local ld for '$1'" && exec '$LD_PATH'/ld-linux-x86-64.so.2 ./'$(basename $1)'.elf "$@"' >> "$TARGET/$1"
	echo 'exec ./'$(basename $1)'.elf "$@"' >> "$TARGET/$1"
	chmod +x "$TARGET/$1"
}


echo "Exporting docs and licences"

# add readme and licence info
cp -r README.md LICENSES $TARGET/

# add addons licence info
mkdir -p $TARGET/LICENSES/addons
(cd addons/3rdparty/; for d in *; do if [ -d "$d" ]; then cp "$d"/*LICENSE* "$TARGET/LICENSES/addons/$d.LICENSE"; fi; done)
(cd addons/; for d in *; do if [ -d "$d" ] && ! git ls-files --error-unmatch "$d" >/dev/null 2>&1; then cp "$d"/*LICENSE* "$TARGET/LICENSES/addons/$d.LICENSE"; fi; done)


echo "Exporting qemu images"

# export images for qemu (must be outside .pck file)
mkdir -p $TARGET/qemu_img
cp qemu_img/*.img qemu_img/*.bzImage $TARGET/qemu_img/

# add kernel and rootfs licence info
for d in qemu_img/*.img.copyright qemu_img/*.bzImage.copyright; do
	cp -r $d $TARGET/LICENSES/$(basename $d .copyright);
done


echo "Exporting gdcef"

# export gdcef assemblies (must be outside .pck file)
platform=$(echo $PLATFORM | tr '[:upper:]' '[:lower:]')
mkdir -p $TARGET/cef_artifacts/$platform
cp -fr $CEF_ARTIFACTS/$platform/* $TARGET/cef_artifacts/$platform/
\rm -f $TARGET/cef_artifacts/gdcef.gdextension $TARGET/libgdcef.* $TARGET/libcef.*

# add CEF licence info
mkdir -p $TARGET/LICENSES/cef
cp addons/3rdparty/gdcef/thirdparty/cef_binary/{CREDITS.html,LICENSE.txt} $TARGET/LICENSES/cef/

# add cef and gdcef libs dependencies
if [ "$PLATFORM" = "Linux" ]; then
	GDCEF_LIB="$TARGET/cef_artifacts/linux/libcef.so $TARGET/cef_artifacts/linux/libgdcef.so  $TARGET/cef_artifacts/linux/gdCefRenderProcess"
	GDCEF_LIB2="/usr/lib/x86_64-linux-gnu/libsoftokn3.so /usr/lib/x86_64-linux-gnu/libfreeblpriv3.so"
	GDCEF_LIB3=$(ldd $GDCEF_LIB $GDCEF_LIB2 | awk '{print $3}' | sort | uniq | grep -v libcef)
	mkdir $TARGET/cef_artifacts/linux/libs/
	for f in $GDCEF_LIB2 $GDCEF_LIB3; do
		patchelf --set-rpath '$ORIGIN' --output "$TARGET/cef_artifacts/linux/libs/$(basename $f)" "$(realpath $f)"
	done
	for f in $GDCEF_LIB; do
		patchelf --set-rpath '$ORIGIN:$ORIGIN/libs:$ORIGIN/../../libs' "$f"
	done
	create_run_via_ld_script cef_artifacts/linux/gdCefRenderProcess ../..
	extract_licence_info cef $(realpath $GDCEF_LIB2 $GDCEF_LIB3)
fi


echo "Exporting libngspice"

# add ngspice binaries

NGSPICE_LIB=$(realpath /usr/lib/x86_64-linux-gnu/libngspice.so)
NGSPICE_LIB2=$(ldd $NGSPICE_LIB | awk '{print $3}' | sort | uniq)
NGSPICE_DATA=$(realpath /usr/lib/x86_64-linux-gnu/ngspice/*)
NGSPICE_INIT=$(realpath /usr/share/ngspice/scripts/spinit)

mkdir -p $TARGET/ngspice

if [ "$PLATFORM" = "Linux" ]; then
	cp $NGSPICE_DATA $TARGET/ngspice
	patchelf --set-rpath '$ORIGIN' --output "$TARGET/ngspice/libngspice.so" "$NGSPICE_LIB"
	for f in $NGSPICE_LIB2; do
		patchelf --set-rpath '$ORIGIN:$ORIGIN/../libs' --output "$TARGET/ngspice/$(basename $f)" "$(realpath $f)"
	done
	sed -e 's#/usr/lib/x86_64-linux-gnu/##' $NGSPICE_INIT > $TARGET/ngspice/spinit
elif [ "$PLATFORM" = "Windows" ]; then
	cp -r ElectronicsSimulator/GdSpice/bin/mingw64/lib/ngspice $TARGET/
	cp ElectronicsSimulator/GdSpice/bin/mingw64/bin/{libngspice-0,libfftw3-3,libgcc_s_seh-1,libgomp-1,libwinpthread-1}.dll $TARGET/ngspice/
	sed -e 's#/mingw64/lib/##' ElectronicsSimulator/GdSpice/bin/mingw64/share/ngspice/scripts/spinit > $TARGET/ngspice/spinit
fi

extract_licence_info ngspice $(realpath $NGSPICE_LIB $NGSPICE_LIB2) $NGSPICE_DATA $NGSPICE_INIT


echo "Exporting qemu"

# add qemu binaries

QEMU_BIN="/usr/bin/qemu-system-x86_64"
QEMU_LIB=$(ldd "$QEMU_BIN" | awk '{print $3}' | sort | uniq)
QEMU_SHARE=$(realpath /usr/share/seabios/{bios-256k.bin,vgabios-stdvga.bin} /usr/share/qemu/{efi-e1000.rom,efi-virtio.rom,kvmvapic.bin,linuxboot_dma.bin})
QEMU_KEYMAPS=/usr/share/qemu/keymaps/en-us

mkdir -p $TARGET/qemu/share/keymaps/

cp $QEMU_SHARE $TARGET/qemu/share/
cp $QEMU_KEYMAPS $TARGET/qemu/share/keymaps/

if [ "$PLATFORM" = "Linux" ]; then
	for f in $QEMU_BIN $QEMU_LIB; do
		patchelf --set-rpath '$ORIGIN:$ORIGIN/../libs' --output "$TARGET/qemu/$(basename $f)" "$(realpath $f)"
	done
	create_run_via_ld_script qemu/qemu-system-x86_64
elif [ "$PLATFORM" = "Windows" ]; then
	mkdir -p $TARGET/qemu/bin $TARGET/qemu/share/keymaps
	cp $QEMU_WIN_BIN/qemu-system-x86_64.exe $TARGET/qemu/bin
	cp $QEMU_WIN_BIN/*.dll $TARGET/qemu/bin
fi

extract_licence_info qemu $(realpath $QEMU_BIN $QEMU_LIB) $QEMU_SHARE $QEMU_KEYMAPS


# add virtiofsd binaries

VIRTIOFSD_BIN="/usr/libexec/virtiofsd"
VIRTIOFSD_LIB=$(ldd $VIRTIOFSD_BIN | awk '{print $3}' | sort | uniq)
if [ "$PLATFORM" = "Linux" ]; then
	for f in $VIRTIOFSD_BIN $VIRTIOFSD_LIB; do
		patchelf --set-rpath '$ORIGIN:$ORIGIN/../libs' --output "$TARGET/qemu/$(basename $f)" "$(realpath $f)"
	done
	create_run_via_ld_script qemu/virtiofsd
fi

extract_licence_info virtiofsd $(realpath $VIRTIOFSD_BIN $VIRTIOFSD_LIB)


echo "Finalizing export"

# Platform specific (additional libs for Linux, .exe, libstdc++-6.dll for Windows, ...)

if [ "$PLATFORM" = "Linux" ]; then
	GODOT_BIN="$TARGET/FactoryAutomation $TARGET/libgodot-xterm.linux.template_debug.x86_64.so"
	GODOT_LIB=$(ldd $GODOT_BIN | awk '{print $3}' | sort | uniq)
	for f in $GODOT_BIN; do
		patchelf --set-rpath '$ORIGIN:$ORIGIN/libs' $f
	done
	mkdir "$TARGET/libs"
	for f in $GODOT_LIB; do
		patchelf --set-rpath '$ORIGIN' --output "$TARGET/libs/$(basename $f)" "$(realpath $f)"
	done
	(cd "$TARGET/libs" && for f in *; do rm -f ../cef_artifacts/linux/libs/$f ../qemu/$f ../ngspice/$f; done)
	
	LD_LIB="/lib64/ld-linux-x86-64.so.2"
	cp "$(realpath $LD_LIB)" "$TARGET/$(basename $LD_LIB)"
	GODOT_LIB="$GODOT_LIB $(realpath $LD_LIB)"
	(cd "$TARGET" && ln -s FactoryAutomation.pck ld-linux-x86-64.so.2.pck)
	
	sed -n '1,3p' -i "$TARGET/FactoryAutomation.sh"
	echo 'mkdir -p "$HOME/.local/share/godot/app_userdata/FactoryAutomation/"' >> "$TARGET/FactoryAutomation.sh"
	echo 'cd "$base_path"' >> "$TARGET/FactoryAutomation.sh"
	echo 'if [ -e ./ld-linux-x86-64.so.2 ]; then' >> "$TARGET/FactoryAutomation.sh"
	echo './ld-linux-x86-64.so.2 ./FactoryAutomation "$@" 2>&1 | tee "$HOME/.local/share/godot/app_userdata/FactoryAutomation/godot.stdout.log"' >> "$TARGET/FactoryAutomation.sh"
	echo 'else' >> "$TARGET/FactoryAutomation.sh"
	echo './FactoryAutomation "$@" 2>&1 | tee "$HOME/.local/share/godot/app_userdata/FactoryAutomation/godot.stdout.log"' >> "$TARGET/FactoryAutomation.sh"
	echo 'fi' >> "$TARGET/FactoryAutomation.sh"
	
	extract_licence_info libs $(realpath $GODOT_LIB)
elif [ "$PLATFORM" = "Windows" ]; then
	mv "$TARGET/FactoryAutomation" "$TARGET/FactoryAutomation.exe"
	cp /usr/lib/gcc/x86_64-w64-mingw32/*-posix/libstdc++-6.dll "$TARGET/"
	mkdir -p "$TARGET/LICENSES/libs"
fi

cp addons/3rdparty/_godot-cpp/LICENSE.md "$TARGET/LICENSES/libs/GODOT.md"

echo
echo "Project exported into $TARGET"
