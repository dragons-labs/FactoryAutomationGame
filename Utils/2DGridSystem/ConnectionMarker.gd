# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

@tool
extends Node2D

var _color : Color
var _radius : float

func _init(color := Color.WHITE, radius := 5):
	_color = color
	_radius = radius

func _draw() -> void:
	draw_circle(Vector2.ZERO, _radius, _color)
