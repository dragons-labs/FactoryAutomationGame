# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

@tool
extends Node2D

@export var grid_size := Vector2(20, 20)
@export var grid_color := Color(0.9, 0.9, 0.9, 0.2)

# NOTE: call queue_redraw() on Grid node after camera update to redraw grid

func _draw() -> void:
	var to_world = (get_global_transform() * get_canvas_transform()).affine_inverse()
	
	var world_size = Rect2()
	world_size.position = to_world * Vector2(0,0)
	world_size.end = to_world * Vector2(get_viewport().size)
	
	var x = floorf(world_size.position.x / grid_size.x) * grid_size.x
	while x < world_size.end.x:
		draw_line(Vector2(x, world_size.position.y), Vector2(x, world_size.end.y), grid_color)
		x += grid_size.x
	
	var y = floorf(world_size.position.y / grid_size.y) * grid_size.y
	while y < world_size.end.y:
		draw_line(Vector2(world_size.position.x, y), Vector2(world_size.end.x, y), grid_color)
		y += grid_size.y

