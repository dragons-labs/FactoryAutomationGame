# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

"""singleton (autoload) utils class for management in game windows"""

extends Node

signal embeded_window_focus_changed(win : Window, focus : bool)

func init_window(win : Window, catch_global_escape := false, catch_global_break := false) -> void:
	if not _border_unfocused:
		_border_unfocused = win.get_theme_stylebox("embedded_unfocused_border")
	win.focus_exited.connect(_on_focus_exited.bind(win))
	win.focus_entered.connect(_on_focus_entered.bind(win))
	win.window_input.connect(_on_window_input.bind(win, catch_global_escape, catch_global_break))
	if win.has_focus():
		win.focus_entered.emit()
	else:
		win.focus_exited.emit()

func focus_is_on_embeded_window() -> bool:
	if not _focus_on_embeded_window_valid:
		# we can't update _focus_on_embeded_window in _on_focus_exited/_on_focus_entered
		# due to order of call those signals/functions
		_focus_on_embeded_window = false
		for win in get_tree().current_scene.find_children("*", "Window", true, false):
			if win.has_focus():
				_focus_on_embeded_window = true
				break
		_focus_on_embeded_window_valid = true
	return _focus_on_embeded_window

var cursor_owner = null

var _focus_on_embeded_window_valid := false
var _focus_on_embeded_window := false
var _border_unfocused
var _hideen_by_escape = []

func _on_focus_exited(win : Window) -> void:
	# print_verbose("_on_focus_exited ", win)
	_focus_on_embeded_window_valid = false
	win.add_theme_stylebox_override("embedded_border", _border_unfocused)
	embeded_window_focus_changed.emit(win, false)

func _on_focus_entered(win : Window) -> void:
	# print_verbose("_on_focus_entered ", win)
	_focus_on_embeded_window_valid = false
	win.remove_theme_stylebox_override("embedded_border")
	embeded_window_focus_changed.emit(win, true)

func _on_window_input(event: InputEvent, win : Window, catch_global_escape : bool, catch_global_break : bool) -> void:
	if (not catch_global_escape and event.is_action_pressed("GLOBAL_ESCAPE", false, true)) or \
	   (not catch_global_break and event.is_action_pressed("GLOBAL_BREAK", false, true)):
		_hideen_by_escape.append(win)
		set_windows_visibility_recursive(win, false)
		Input.parse_input_event(event.duplicate())
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT and event.pressed:
			if event.position.x < 0 or event.position.y < 0 or event.position.x > win.size.x or event.position.y > win.size.y:
				# set original input as handled ...
				win.set_input_as_handled()
				# this doesn't seem to work ... but the change button to NONE (on original event) make the job
				
				# create and send left click event to rid of focus
				var new_event = event.duplicate()
				new_event.button_index = MOUSE_BUTTON_LEFT
				new_event.position = new_event.global_position
				Input.parse_input_event(new_event)
				
				# send button-up event also
				new_event = new_event.duplicate()
				new_event.pressed = false
				Input.parse_input_event(new_event)
				
				# after rid of focus resend original event with position == global_position
				new_event = event.duplicate()
				new_event.position = new_event.global_position
				Input.parse_input_event(new_event)
				
				# invalidate original event by changing button to NONE
				event.button_index = MOUSE_BUTTON_NONE

func set_windows_visibility_recursive(win : Window, value : bool) -> void:
	win.visible = value
	for subwin in win.find_children("*", "Window", true, false):
		if not (subwin is AcceptDialog or subwin is Popup):
			subwin.visible = value
	if win.visible:
		win.grab_focus()

func hide_by_escape_all_windows(node : Node = null):
	if not node:
		node = get_tree().current_scene
	for win in node.find_children("*", "Window", true, false):
		if win.visible:
			_hideen_by_escape.append(win)
			set_windows_visibility_recursive(win, false)

func restore_hideen_by_escape():
	for i in range(len(_hideen_by_escape)-1, -1, -1):
		if _hideen_by_escape[i]: # in case of freed object after called hide_by_escape_all_windows()
			set_windows_visibility_recursive(_hideen_by_escape[i], true)
	_hideen_by_escape.clear()

func cancel_hideen_by_escape():
	_hideen_by_escape.clear()
