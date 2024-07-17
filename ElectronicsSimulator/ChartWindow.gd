# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Window

@onready var _editable_nodes = [
	%StartTime/Slider,
	%StartTime/Value,
	%EndTime/Slider,
	%EndTime/Value
]

@onready var _chart = %Chart
@onready var _apply_button = %ApplyButton
@onready var _start_time = %StartTime
@onready var _start_time_slider = %StartTime/Slider
@onready var _end_time = %EndTime
@onready var _end_time_slider = %EndTime/Slider

func _ready() -> void:
	_on_manual_time_enabled_button_toggled(false)
	FAG_WindowManager.init_window(self)

func _on_manual_time_enabled_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		var curr_time = _chart.x_domain.get("ub", 0)
		_start_time_slider.max_value = curr_time
		_start_time.set_value(0)
		_end_time_slider.max_value = curr_time
		_end_time.set_value(curr_time)
	elif _chart.functions:
		# fix function after override x, y vectors
		for i in range(0, len(_chart.functions)):
			_chart.functions[i].__x = []
			_chart.functions[i].__y = []
		_chart.x_domain = {}
		_chart.y_domain = {}
		_chart.load_functions(_chart.functions)
		# some tricks to fix after load_functions()
		await get_tree().create_timer(0.02, true, false, true).timeout
		_chart._canvas._legend.hide()
		_chart._canvas._legend.show()
	
	for node in _editable_nodes:
		node.editable = toggled_on
	
	_apply_button.disabled = not toggled_on

func _on_start_slider_value_changed(value: float) -> void:
	_end_time_slider.min_value = value

func _on_end_slider_value_changed(value: float) -> void:
	_start_time_slider.max_value = value

func _on_apply_button_pressed() -> void:
	_start_time.set_value_from_textbox()
	_end_time.set_value_from_textbox()
