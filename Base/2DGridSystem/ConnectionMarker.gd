# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

@tool
extends Node2D
class_name FAG_2DGrid_ConnectionMarker

@export var color := Color.WHITE
@export var radius := 5

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
