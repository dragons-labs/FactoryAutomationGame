# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node2D

@export var stroke_color := Color(0, 1.0, 0, 1.0)
@export var stroke_width := 3
@export var fill_color := Color(0.5, 1.0, 0, 0.2)

@onready var _line := Line2D.new()
@onready var _poly := Polygon2D.new()
@onready var _squared_zero_size := stroke_width * stroke_width
var _points := [Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(0,1)]

func _ready() -> void:
	_line.default_color = stroke_color
	_line.width = stroke_width
	_line.closed = true
	_line.points = _points
	add_child(_line)
	
	_poly.color = fill_color
	_poly.polygon = _points
	add_child(_poly)
	
	visible = false
	is_done = false

var is_done := false

func init(point : Vector2) -> void:
	set_first(point)
	set_second(point)
	visible = true
	is_done = false

func set_first(point : Vector2) -> void:
	_points[0] = point
	_points[1].y = point.y
	_points[3].x = point.x
	_line.points = _points
	_poly.polygon = _points

func set_second(point : Vector2) -> void:
	_points[1].x = point.x
	_points[2] = point
	_points[3].y = point.y
	_line.points = _points
	_poly.polygon = _points

func get_first() -> Vector2:
	return _points[0]

func get_second() -> Vector2:
	return _points[2]

func hit_in_selection_box(point : Vector2) -> bool:
	return \
		is_done and \
		((_points[0].x < point.x and point.x < _points[2].x) or (_points[2].x < point.x and point.x < _points[0].x)) and \
		((_points[0].y < point.y and point.y < _points[2].y) or (_points[2].y < point.y and point.y < _points[0].y))

func is_approx_zero_size() -> bool:
	return _points[0].distance_squared_to(_points[2]) < _squared_zero_size

func get_area() -> Rect2:
	var _begin = Vector2(min(_points[0].x, _points[2].x), min(_points[0].y, _points[2].y))
	var _end = Vector2(max(_points[0].x, _points[2].x), max(_points[0].y, _points[2].y))
	return Rect2(_begin, _end-_begin)
