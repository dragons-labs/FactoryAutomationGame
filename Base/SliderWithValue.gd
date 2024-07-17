# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends HBoxContainer

@export var format_string := "%.2f"
@export_node_path("Slider") var slider_path : NodePath = "Slider"
@export_node_path("Control") var value_editbox_path : NodePath = "Value"

@onready var slider : Slider = get_node(slider_path)
@onready var value_editbox := get_node(value_editbox_path)

signal value_changed(value : float)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	slider.value_changed.connect(_on_set_slider_value)
	if value_editbox is LineEdit:
		value_editbox.text_submitted.connect(_on_set_text_value)
	if _on_init_value != null:
		slider.value = _on_init_value

func _on_set_text_value(text : String) -> void:
	var value = float(text)
	if (slider.allow_lesser || value <= slider.max_value) and (slider.allow_greater || value >= slider.min_value):
		set_value(value)
	else:
		value_editbox.text = format_string % slider.value

func _on_set_slider_value(value : float) -> void:
	value_editbox.text = format_string % value
	value_changed.emit(value)

func set_value(value : float) -> void:
	if slider:
		slider.value = value
		value_changed.emit(value)
	else:
		_on_init_value = value

func get_value() -> float:
	return slider.value

func set_value_from_textbox() -> void:
	_on_set_text_value(value_editbox.text)

var _on_init_value = null
