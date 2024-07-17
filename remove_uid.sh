#!/bin/sh

# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

#files_list=`find \( -name '*.tscn' -o -name '*.tres' \) ! -exec git check-ignore -q \{\} \; -print`
files_list=`(git ls-tree -r HEAD --name-only; git ls-files --others --exclude-standard) | egrep '\.(tscn|tres)$'`

replace_if_need() {
	ret=1
	while read f; do
		if [ "$f" != "" ] && grep -q ' *uid="uid://[a-z0-9]*"' "$f"; then
			echo "$f"
			sed -i "$f" -e 's@ *uid="uid://[a-z0-9]*"@@g'
			ret=0
		fi
	done
	return $ret
}

echo "$files_list" | replace_if_need

exit $?
