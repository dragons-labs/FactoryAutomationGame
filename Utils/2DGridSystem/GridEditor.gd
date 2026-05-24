# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node2D

@export_group("Grid Elements")

@export var elements: Array[PackedScene] = []

@export_group("Basic Grid Settings")

@export var grid_size := Vector2(20, 20)
@export var grid_color := Color(0.9, 0.9, 0.9, 0.2)
@export var selection_color := Color(0.5, 2.0, 0, 0.6)
@export var partial_selection_color := Color.ORANGE
@export var normal_color := Color.WHITE

@export_group("Grid Editor Mics Settings")

@export var orthogonal_lines := true
@export var keep_line_connected := false :
	set(val):
		keep_line_connected = val
		if _keep_line_connected_button:
			_switch_keep_line_connected(false)
	get():
		return keep_line_connected
@export var use_interactive_import := true

## Name of settings group for this object. This allowing override some properties and input maps.
## Set to empty string to disable using settings (hide in settings menu, disallow override properties and key mapping).
@export var settings_group_name := "WORLD_EDITOR_UI_SETTINGS_GROUP_NAME"


signal on_element_click(element: Node2D, long: bool)


### Init

@onready var undo_redo := UndoRedo.new()
@onready var grid : Object = FAG_Utils.load(self, "World.gd").new(%Nodes, undo_redo, grid_size)
@onready var ui := %WorldEditorUI

func _init() -> void:
	var default_settings = FAG_Settings.set_default_setting_from_object(self, "WORLD_EDITOR_SETTINGS_", [
		"orthogonal_lines",
		"use_interactive_import",
		"keep_line_connected",
	])
	
	if settings_group_name:
		FAG_Settings.register_settings(self, settings_group_name, default_settings, {})

func _ready() -> void:
	%VisualGrid.grid_size = grid_size
	%VisualGrid.grid_color = grid_color
	grid.gLines.grid_size = grid_size
	grid.gLines.orthogonal_lines = orthogonal_lines
	
	ui.line_add_point.connect(grid.gLines.new_line__add_point)
	ui.line_finish.connect(grid.gLines.new_line__finish)
	ui.line_update_last_point.connect(grid.gLines.new_line__update_segment)
	ui.element_add__finish.connect(_on_add_element__finish)
	ui.element_add__update.connect(_on_add_element__update)
	
	ui.do_raycast = func (point):
		var element = grid.gElements.find_element_by_point(point)
		var line = grid.gLines.find_line_by_point(point)
		if element || line:
			return [element, line]
		return null
	
	ui.is_selected = _is_selected.bind()
	
	for element in elements:
		ui.add_element(element)
	
	var tools = ui.get_node("%Tools")
	_keep_line_connected_button = Button.new()
	_keep_line_connected_button.pressed.connect(_switch_keep_line_connected)
	_switch_keep_line_connected(false)
	tools.add_child(_keep_line_connected_button)

var _keep_line_connected_button : Button
func _switch_keep_line_connected(switch := true) -> void:
	if switch: keep_line_connected = not keep_line_connected
	if keep_line_connected:
		_keep_line_connected_button.icon = load("res://Utils/WorldEditorUI/ui_icons/keep_line_connected_on.svg")
		_keep_line_connected_button.tooltip_text = "EDITOR_KEEP_LINE_CONNECTED_ON_TOOLTIP"
	else:
		_keep_line_connected_button.icon = load("res://Utils/WorldEditorUI/ui_icons/keep_line_connected_off.svg")
		_keep_line_connected_button.tooltip_text = "EDITOR_KEEP_LINE_CONNECTED_OFF_TOOLTIP"
	ui.active_ui_tool = ui.SELECT
	_update_selection([], [])

func set_visibility(value : bool) -> void:
	visible = value
	%WorldEditorUI.call_deferred("set_visibility", value)
	%Camera2D.call_deferred("set_visibility", value)

func set_editor_enabled(value : bool) -> void:
	_update_selection([], [])
	for element in grid.gElements.main_node.get_children():
		element.set_ui_enabled(value)
	ui.set_editor_enabled(value)

### Elements and line (segments) selection

var _selected_elements = []
var _selected_lines = []

func _is_selected(raycast_result : Variant) -> bool:
	if raycast_result[0] in _selected_elements or raycast_result[1] in _selected_lines or \
		("line" in raycast_result[1] and raycast_result[1].line in _selected_lines):
			return true
	return false

func _update_selection(new_selected_elements : Array, new_selected_lines : Array, call_merge := true) -> void:
	for element in _selected_elements:
		_mark_element(element, normal_color)
	for line in _selected_lines:
		_mark_line(line, normal_color)
	
	if call_merge:
		grid.gLines.merge_lines()
	
	_selected_elements = new_selected_elements
	_selected_lines = new_selected_lines if keep_line_connected else grid.gLines.split_lines(new_selected_lines)
	
	for element in _selected_elements:
		_mark_element(element, selection_color)
	for line in _selected_lines:
		_mark_line(line, partial_selection_color if keep_line_connected else selection_color)

func _add_to_selection(new_element : Variant, new_line : Variant) -> void:
	if new_element is not Array:
		new_element = [new_element] if new_element else []
	if new_line is not Array:
		new_line = [new_line] if new_line else []
	
	if new_line and not new_element and len(_selected_lines) == 0 and len(_selected_elements) == 0:
		# do not split single line segment for move operation
		_selected_lines.append(new_line[0])
		_mark_line(new_line[0], partial_selection_color)
		return
	elif len(_selected_lines) == 1:
		# split and mark single line segment when switch to selected multiple object
		_mark_line(_selected_lines[0], normal_color)
		new_line.append(_selected_lines[0])
		_selected_lines.clear()
	
	for element in new_element:
		_mark_element(element, selection_color)
		_selected_elements.append(element)
	for line in new_line if keep_line_connected else grid.gLines.split_lines(new_line):
		_mark_line(line, partial_selection_color if keep_line_connected else selection_color)
		_selected_lines.append(line)

func _rem_from_selection(new_element : Variant, new_line : Variant) -> void:
	if new_element is not Array:
		new_element = [new_element] if new_element else []
	if new_line is not Array:
		new_line = [new_line] if new_line else []
	
	for element in new_element:
		_mark_element(element, normal_color)
		_selected_elements.erase(element)
	for line in new_line:
		_mark_line(line, normal_color)
		_selected_lines.erase(line)

func _mark_element(element : Node2D, color : Color) -> void:
	element.get_node("Image").modulate = color
	for connection in element.get_node("Connections").get_children():
		connection.modulate = color

func _mark_line(line : Variant, color : Color) -> void:
	line = grid.gLines.get_line(line)
	if is_instance_valid(line) and line.get_point_count() > 1:
		line.modulate = color


### UI callbacks

var _prev_mode = null
func _on_active_ui_tool_changed(mode : int, element : PackedScene) -> void:
	if not ui:
		return
	
	if mode == ui.LINE or mode == ui.ELEMENT:
		_update_selection([], [], _prev_mode != ui.DUPLICATE)
	
	if mode != ui.LINE:
		grid.gLines.new_line__finish()
	
	if mode != ui.ELEMENT and (_prev_mode != ui.MOVE):
		grid.gElements.add_element__cancel()
		grid.gLines.move_duplicate_cancel()
	elif element:
		grid.gElements.add_element__init(element, get_local_mouse_position())
	
	_prev_mode = mode

func _on_do_on_raycast_result(mode : int, point : Vector2, raycast_result : Variant, multi_select : bool) -> void:
	if raycast_result:
		# NOTE: this function is not called for raycast_result for which _is_selected(raycast_result) == true
		if mode == ui.SELECT and multi_select:
			# add to selection
			_add_to_selection(raycast_result[0], raycast_result[1])
		elif not _is_selected(raycast_result):
			# replace selection
			_update_selection([], [])
			_add_to_selection(raycast_result[0], raycast_result[1])
	elif not multi_select:
		# clear selection
		_update_selection([], [])
	
	_on_do_on_selection(mode, point, null, false)

func _on_do_on_selection(mode: int, point: Vector2, raycast_result : Variant, multi_select : bool) -> void:
	if mode == ui.SELECT and multi_select and raycast_result:
		# remove from selection
		_rem_from_selection(raycast_result[0], raycast_result[1])
	
	var action_is_init = 0
	match mode:
		ui.SELECT, ui.MOVE:
			grid.gLines.move_duplicate_init(_selected_lines, point, false)
			grid.gElements.move_element__init(_selected_elements, point)
		ui.DELETE:
			action_is_init += grid.gLines.delete_lines(_selected_lines, action_is_init == 0, false)
			action_is_init += grid.gElements.delete_elements(_selected_elements, action_is_init == 0, false)
		ui.ROTATE:
			action_is_init += grid.gLines.rotate_lines(_selected_lines, -PI/2, point, action_is_init == 0, false)
			action_is_init += grid.gElements.rotate_elements(_selected_elements, -PI/2, point, action_is_init == 0, false)
		ui.MIRROR:
			action_is_init += grid.gLines.mirror_lines(_selected_lines, point, action_is_init == 0, false)
			action_is_init += grid.gElements.mirror_elements(_selected_elements, point, action_is_init == 0, false)
		ui.DUPLICATE:
			for element in _selected_elements:
				_mark_element(element, normal_color)
			for line in _selected_lines:
				_mark_line(line, normal_color)
			grid.gElements.add_elements__init(_selected_elements, point)
			grid.gLines.move_duplicate_init(_selected_lines, point, true)
			_update_selection([], [], false)
			ui.active_ui_tool = ui.ELEMENT
	if action_is_init > 0:
		undo_redo.commit_action()

func _on_add_element__update(point : Vector2) -> void:
	grid.gLines.move_duplicate_update(point)
	grid.gElements.add_element__update(point)

func _on_add_element__finish(point : Vector2) -> void:
	var action_is_init = 0
	action_is_init += grid.gLines.move_duplicate_finish(true, action_is_init == 0, false)
	action_is_init += grid.gElements.add_element__finish(point, action_is_init == 0, false)
	if action_is_init > 0:
		undo_redo.commit_action()

func _on_do_move_step(point):
	grid.gLines.move_duplicate_update(point)
	grid.gElements.move_element__step(point)

func _on_do_move_finish() -> void:
	var action_is_init = 0
	action_is_init += grid.gLines.move_duplicate_finish(false, action_is_init == 0, false)
	action_is_init += grid.gElements.move_element__finish(action_is_init == 0, false)
	if action_is_init:
		undo_redo.commit_action()
	elif len(_selected_elements) == 1:
		# long click
		on_element_click.emit(_selected_elements[0], true)

func _on_do_on_raycast_selection_finish(raycast_result : Variant, multi_select_add : bool, multi_select_rem : bool, selection_box : Variant) -> void:
	if raycast_result and raycast_result[0]:
		on_element_click.emit(raycast_result[0], false)
	
	if selection_box.is_valid():
		var area = ui._selection_box.get_area()
		var elements_to_select = grid.gElements.find_elements_on_area(area)
		var lines_to_select = grid.gLines.find_lines_on_area(area)
		if multi_select_add:
			_add_to_selection(elements_to_select, lines_to_select)
		elif multi_select_rem:
			_rem_from_selection(elements_to_select, lines_to_select)
		else:
			_update_selection(elements_to_select, lines_to_select)
	
	grid.gLines.move_duplicate_cancel()
	grid.gElements.move_element__cancel()


### Input handle

# used to blocked unwanted input when Grid Editor is hidden / not active
func set_input_allowed(value : bool) -> void:
	ui.input_allowed = value
	%Camera2D.use_mouse_control = ui.input_allowed and not ui.mouse_in_gui_area()

func _on_mouse_enter_exit_gui_area(_value : bool) -> void:
	%Camera2D.use_mouse_control = ui.input_allowed and not ui.mouse_in_gui_area()

func _input(event: InputEvent) -> void:
	if not ui.input_allowed or ui.mouse_in_gui_area():
		return
	# override UI buttons shortcuts in some situations
	var mode = ui.active_ui_tool
	if FAG_Utils.action_exact_match_pressed("EDIT_ROTATE", event):
		if mode == ui.ELEMENT:
			var point = ui.get_local_mouse_position()
			grid.gElements.rotate_elements(grid.gElements._new_elements.keys(), -PI/2, point, true, true, true)
			grid.gElements.update_new_elements_positions(point)
			grid.gLines.duplicate_rotate(-PI/2, point)
			get_viewport().set_input_as_handled()
		elif mode == ui.SELECT and (len(_selected_lines) + len(_selected_elements)) > 0:
			_on_do_on_selection(ui.ROTATE, ui.get_local_mouse_position(), null, false)
			get_viewport().set_input_as_handled()
	elif FAG_Utils.action_exact_match_pressed("EDIT_MIRROR", event):
		if mode == ui.ELEMENT:
			var point = ui.get_local_mouse_position()
			grid.gElements.mirror_elements(grid.gElements._new_elements.keys(), point, true, true, true)
			grid.gElements.update_new_elements_positions(point)
			grid.gLines.duplicate_mirror(point)
			get_viewport().set_input_as_handled()
		elif mode == ui.SELECT and (len(_selected_lines) + len(_selected_elements)) > 0:
			_on_do_on_selection(ui.MIRROR, ui.get_local_mouse_position(), null, false)
			get_viewport().set_input_as_handled()
	elif FAG_Utils.action_exact_match_pressed("EDIT_DELETE", event):
		if mode == ui.SELECT and (len(_selected_lines) + len(_selected_elements)) > 0:
			_on_do_on_selection(ui.DELETE, ui.get_local_mouse_position(), null, false)
			get_viewport().set_input_as_handled()


### Undo-Redo system support

func next_action_name() -> String:
	if not undo_redo.has_redo():
		return ""
	return undo_redo.get_action_name(undo_redo.get_current_action()+1)

func undo() -> void:
	if not undo_redo.has_undo():
		return
	_update_selection([], [])
	
	var action_name = undo_redo.get_current_action_name()
	print("[Grid Editor] Undo: ", action_name)
	undo_redo.undo()
	
	while undo_redo.has_undo() \
		and (
			(ui.active_ui_tool != ui.LINE and grid.gLines.need_execute_next_undo(undo_redo.get_current_action_name())) or
			action_name == "Merge Lines" or undo_redo.get_current_action_name() == "Split Lines"
		):
			action_name = undo_redo.get_current_action_name()
			print("[Grid Editor] Undo (auto): ", action_name)
			undo_redo.undo()

func redo() -> void:
	if not undo_redo.has_redo():
		return
	_update_selection([], [])
	
	var action_name = next_action_name()
	print("[Grid Editor] Redo: ", action_name)
	undo_redo.redo()
	
	while undo_redo.has_redo() \
		and (
			(ui.active_ui_tool != ui.LINE and grid.gLines.need_execute_next_redo(next_action_name())) or
			action_name == "Split Lines" or next_action_name() == "Merge Lines"
		):
			action_name = next_action_name()
			print("[Grid Editor] Redo (auto): ", action_name)
			undo_redo.redo()


### Export-Import system support

func _on_do_save(path: String) -> void:
	FAG_Utils.write_to_json_file(path, grid.serialise())

func _on_do_import(path: String) -> void:
	var world_position : Vector2
	if use_interactive_import:
		# mouse on world
		world_position = ui.get_local_mouse_position()
	else:
		# screen center on world
		world_position = \
			(grid.gParent.get_global_transform() * grid.gParent.get_canvas_transform()).affine_inverse() \
			* Vector2(get_viewport().size/2)
	world_position = world_position.snapped(grid_size)
	
	var data = FAG_Utils.load_from_json_file(path)
	grid.restore(data, ui._elements_dict, world_position, use_interactive_import)
	
	if use_interactive_import:
		ui.active_ui_tool = ui.ELEMENT
