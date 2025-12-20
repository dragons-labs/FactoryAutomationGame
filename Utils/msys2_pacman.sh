# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

if [ $# -lt 1 ]; then
	echo "USAGE: $0 instalation_dir [package [package ...]]"
	exit
fi

MSYS2_ROOT_DIR=$1
MSYS2_PACMAN_DIR=`realpath "$MSYS2_ROOT_DIR"`/.msys2_pacman

if [ ! -f $MSYS2_PACMAN_DIR/conf ]; then

mkdir -p $MSYS2_PACMAN_DIR/lib $MSYS2_PACMAN_DIR/pkg $MSYS2_PACMAN_DIR/gnupg

cat << EOF > $MSYS2_PACMAN_DIR/conf
[options]
RootDir     = $MSYS2_ROOT_DIR
DBPath      = $MSYS2_PACMAN_DIR/lib/
CacheDir    = $MSYS2_PACMAN_DIR/pkg/
LogFile     = $MSYS2_PACMAN_DIR/pacman.log
GPGDir      = $MSYS2_PACMAN_DIR/gnupg/
SigLevel    = Never

[mingw64]
Server      = https://repo.msys2.org/mingw/mingw64/
EOF

fakeroot pacman-key --config $MSYS2_PACMAN_DIR/conf --init
wget -O - https://repo.msys2.org/msys/x86_64/msys2-keyring-1~20251012-1-any.pkg.tar.zst | tar -x --zstd -f - -O usr/share/pacman/keyrings/msys2.gpg | fakeroot pacman-key --config $MSYS2_PACMAN_DIR/conf -a -
fakeroot pacman --config $MSYS2_PACMAN_DIR/conf -Sy

fi

install() {
	fakeroot pacman --config $MSYS2_PACMAN_DIR/conf --noconfirm -S $@
}

if [ $# -gt 1 ]; then
	shift
	install $@
fi
