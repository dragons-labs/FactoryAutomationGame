// SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
// SPDX-License-Identifier: CC0-1.0

shader_type spatial;
render_mode blend_mix;

uniform vec4 color : source_color = vec4(1,0,0,1);

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
