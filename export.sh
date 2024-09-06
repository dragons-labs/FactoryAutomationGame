#!/bin/sh

# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

set -e

PLATFORM=${1:-Linux}
TARGET=$PWD/tmp/export/
CEF_ARTIFACTS=addons/3rdparty/gdcef/build/$PLATFORM

# prepare target directory
mkdir -p $TARGET/FAG_$PLATFORM
:> $TARGET/.gdignore

# fake Windows dll for gdcef ... real file will be added later
[ -f cef_artifacts/libgdcef.dll ] || :> cef_artifacts/libgdcef.dll

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
include_filter="Manual/generated-bbcode/*,*.json,*.circuit"
exclude_filter="tmp/*"
export_path="$TARGET/FAG_Linux/FactoryAutomation"
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
include_filter="Manual/generated-bbcode/*,*.json,*.circuit"
exclude_filter="tmp/*"
export_path="$TARGET/FAG_Windows/FactoryAutomation"
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
TARGET=$TARGET/FAG_$PLATFORM
godot --export-debug $PLATFORM $TARGET/FactoryAutomation
\rm export_presets.cfg

# export images for qemu (must be outside .pck file)
mkdir -p $TARGET/qemu_img
cp qemu_img/*.img qemu_img/*.bzImage $TARGET/qemu_img/

# export gdcef assemblies (must be outside .pck file and available via two path)
mkdir -p $TARGET/cef_artifacts/
cp -rf $CEF_ARTIFACTS/* $TARGET/cef_artifacts/
\rm -f $TARGET/cef_artifacts/debug.log $TARGET/cef_artifacts/gdcef.gdextension
\rm -f $TARGET/libgdcef.so $TARGET/libgdcef.dll

# Windows specific (.exe, add libstdc++-6.dll, add ngspice dlls, add qemu)
if [ "$PLATFORM" = "Windows" ]; then
	mv $TARGET/FactoryAutomation $TARGET/FactoryAutomation.exe
	cp ElectronicsSimulator/GdSpice/bin/win64/dll-mingw/* $TARGET/
	cp /usr/lib/gcc/x86_64-w64-mingw32/12-posix/libstdc++-6.dll $TARGET/
	cp -r ComputerSimulator/OS/bin/qemu $TARGET/
	cp $TARGET/cef_artifacts/* $TARGET/ # TODO this is not elegant solution
fi
