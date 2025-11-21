#!/bin/bash

# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: CC0-1.0

cd "$(dirname "$0")"
godot --path . --load-save Levels/demo/data1
