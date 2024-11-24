# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Window

@onready var _editable_nodes = [
	%StartTime/Slider,
	%StartTime/Value,
	%EndTime/Slider,
	%EndTime/Value
]

@onready var chart = %Chart
@onready var _apply_button = %ApplyButton
@onready var _start_time = %StartTime
@onready var _start_time_slider = %StartTime/Slider
@onready var _end_time = %EndTime
@onready var _end_time_slider = %EndTime/Slider

var skip = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_on_manual_time_enabled_button_toggled(false)
	FAG_WindowManager.init_window(self)

func _on_manual_time_enabled_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		var curr_time = chart.x_domain.get("ub", 0) - 0.001
		_start_time_slider.max_value = curr_time
		_start_time.set_value(0)
		_end_time_slider.max_value = curr_time
		_end_time.set_value(curr_time)
	elif chart.functions:
		# fix function after override x, y vectors
		for i in range(0, len(chart.functions)):
			chart.functions[i].__x = []
			chart.functions[i].__y = []
		chart.x_domain = {'lb':0}
		chart.y_domain = {}
		chart.load_functions(chart.functions)
		# skip one update_measurements() call to avoid use chart when not ready 
		skip = true
		# some tricks to fix after load_functions()
		await get_tree().process_frame
		chart._canvas._legend.hide()
		chart._canvas._legend.show()
	
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
