# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node2D

@export_group("Grid Elements")

@export var elements: Array[PackedScene] = []

@export_group("Basic Grid Settings")

@export var grid_size := Vector2(20, 20)
@export var grid_color := Color(0.9, 0.9, 0.9, 0.2)
@export var selection_color := Color(0.5, 2.0, 0, 0.4)
@export var normal_color := Color.WHITE

@export_group("Grid Editor Mics Settings")

@export var orthogonal_lines := true
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
		var line_segment = grid.gLines.find_line_by_point(point)
		if element || line_segment:
			return [element, line_segment]
		return null
	
	ui.is_selected = _is_selected.bind()
	
	for element in elements:
		ui.add_element(element)

func set_visibility(value : bool) -> void:
	visible = value
	%WorldEditorUI.call_deferred("set_visibility", value)
	%Camera2D.call_deferred("set_visibility", value)

func set_editor_enabled(value : bool) -> void:
	_update_selection([], [])
	for element in grid.gElements.main_node.get_children():
		element.set_ui_enabled(value)
	ui.set_editor_enabled(value)

### Elements and line segments selection

var _selected_elements = []
var _selected_segmetnts = []

func _is_selected(raycast_result : Variant) -> bool:
	if raycast_result[0] in _selected_elements or raycast_result[1] in _selected_segmetnts:
		return true
	return false

func _update_selection(new_selected_elements, new_selected_segmetnts) -> void:
	for element in _selected_elements:
		_mark_element(element, normal_color)
	for segment in _selected_segmetnts:
		_mark_segment(segment, normal_color)
	
	_selected_elements = new_selected_elements
	_selected_segmetnts = new_selected_segmetnts
	
	for element in _selected_elements:
		_mark_element(element, selection_color)
	for segment in _selected_segmetnts:
		_mark_segment(segment, selection_color)

func _add_to_selection(new_element : Variant, new_segment : Dictionary) -> void:
	if new_element:
		_mark_element(new_element, selection_color)
		_selected_elements.append(new_element)
	if new_segment:
		_mark_segment(new_segment, selection_color)
		_selected_segmetnts.append(new_segment)

func _rem_from_selection(new_element : Node2D, new_segment : Dictionary) -> void:
	if new_element:
		_mark_element(new_element, normal_color)
		_selected_elements.erase(new_element)
	if new_segment:
		_mark_segment(new_segment, normal_color)
		_selected_segmetnts.erase(new_segment)

func _mark_element(element : Node2D, color : Color) -> void:
	element.get_node("Image").modulate = color
	for connection in element.get_node("Connections").get_children():
		connection.modulate = color

func _mark_segment(segment : Dictionary, color : Color) -> void:
	segment.line.modulate = color
	# TODO: we should colored only segments but this would require splitting/duplicating lines


### UI callbacks

func _on_active_ui_tool_changed(mode : int, _button_name : String, element : PackedScene) -> void:
	if not ui:
		return
	
	if mode == ui.LINE or mode == ui.ELEMENT:
		_update_selection([], [])
	
	if mode != ui.LINE:
		grid.gLines.new_line__finish()
	
	if mode != ui.ELEMENT:
		grid.gElements.add_element__cancel()
		grid.gLines.duplicate_cancel()
	else:
		grid.gElements.add_element__init(element, get_local_mouse_position())

func _on_do_on_raycast_result(mode : int, point : Vector2, raycast_result : Variant, multi_select : bool) -> void:
	if raycast_result:
		# NOTE: this function is not called for raycast_result for which _is_selected(raycast_result) == true
		if mode == ui.SELECT and multi_select:
			# add to selection
			_add_to_selection(raycast_result[0], raycast_result[1])
		else:
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
			grid.gLines.update_segment__init(_selected_segmetnts, point)
			grid.gElements.move_element__init(_selected_elements, point)
		ui.DELETE:
			action_is_init += grid.gLines.remove_segment(_selected_segmetnts, action_is_init == 0, false)
			action_is_init += grid.gElements.delete_elements(_selected_elements, action_is_init == 0, false)
		ui.ROTATE:
			action_is_init += grid.gLines.rotate_segments(_selected_segmetnts, -PI/2, point, action_is_init == 0, false)
			action_is_init += grid.gElements.rotate_elements(_selected_elements, -PI/2, point, action_is_init == 0, false)
		ui.MIRROR:
			action_is_init += grid.gLines.mirror_segments(_selected_segmetnts, point, action_is_init == 0, false)
			action_is_init += grid.gElements.mirror_elements(_selected_elements, point, action_is_init == 0, false)
		ui.DUPLICATE:
			for element in _selected_elements:
				_mark_element(element, normal_color)
			for segment in _selected_segmetnts:
				_mark_segment(segment, normal_color)
			grid.gElements.add_elements__init(_selected_elements, point)
			grid.gLines.init_duplicate(_selected_segmetnts, point)
			_update_selection([], [])
			ui._active_ui_tool = ui.ELEMENT
	if action_is_init > 0:
		undo_redo.commit_action()

func _on_add_element__update(point : Vector2) -> void:
	grid.gLines.duplicate_update(point)
	grid.gElements.add_element__update(point)

func _on_add_element__finish(point : Vector2) -> void:
	var action_is_init = 0
	action_is_init += grid.gLines.duplicate_finish(point, action_is_init == 0, false)
	action_is_init += grid.gElements.add_element__finish(point, action_is_init == 0, false)
	if action_is_init > 0:
		undo_redo.commit_action()

func _on_do_move_step(point):
	grid.gLines.update_segment__step(point)
	grid.gElements.move_element__step(point)

func _on_do_move_finish() -> void:
	var action_is_init = false
	action_is_init = grid.gLines.update_segment__finish(not action_is_init, false)
	action_is_init = grid.gElements.move_element__finish(not action_is_init, false) or action_is_init
	if action_is_init:
		undo_redo.commit_action()
	elif len(_selected_elements) == 1:
		# long click
		on_element_click.emit(_selected_elements[0], true)

func _on_do_on_raycast_selection_finish(raycast_result : Variant, multi_select : bool, selection_box : Variant) -> void:
	if raycast_result and raycast_result[0]:
		on_element_click.emit(raycast_result[0], false)
	
	if selection_box.is_valid():
		var area = ui._selection_box.get_area()
		_update_selection(grid.gElements.find_elements_on_area(area), grid.gLines.find_segments_on_area(area))
	
	grid.gLines.move_segment__cancel()
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
	var mode = ui.get_active_ui_tool_mode()
	if FAG_Utils.action_exact_match_pressed("EDIT_ROTATE", event):
		if mode == ui.ELEMENT:
			var point = ui.get_local_mouse_position()
			grid.gElements.rotate_elements(grid.gElements._new_elements.keys(), -PI/2, point, true, true, true)
			grid.gElements.update_new_elements_positions(point)
			grid.gLines.duplicate_rotate(-PI/2, point)
			get_viewport().set_input_as_handled()
		elif mode == ui.SELECT and (len(_selected_segmetnts) + len(_selected_elements)) > 0:
			_on_do_on_selection(ui.ROTATE, ui.get_local_mouse_position(), null, false)
			get_viewport().set_input_as_handled()
	elif FAG_Utils.action_exact_match_pressed("EDIT_MIRROR", event):
		if mode == ui.ELEMENT:
			var point = ui.get_local_mouse_position()
			grid.gElements.mirror_elements(grid.gElements._new_elements.keys(), point, true, true, true)
			grid.gElements.update_new_elements_positions(point)
			grid.gLines.duplicate_mirror(point)
			get_viewport().set_input_as_handled()
		elif mode == ui.SELECT and (len(_selected_segmetnts) + len(_selected_elements)) > 0:
			_on_do_on_selection(ui.MIRROR, ui.get_local_mouse_position(), null, false)
			get_viewport().set_input_as_handled()
	elif FAG_Utils.action_exact_match_pressed("EDIT_DELETE", event):
		if mode == ui.SELECT and (len(_selected_segmetnts) + len(_selected_elements)) > 0:
			_on_do_on_selection(ui.DELETE, ui.get_local_mouse_position(), null, false)
			get_viewport().set_input_as_handled()


### Undo-Redo system support

func undo() -> void:
	_update_selection([], [])
	
	# print_verbose("[Grid Editor] Undo: ", undo_redo.get_current_action_name())
	undo_redo.undo()
	
	if ui.get_active_ui_tool_mode() != ui.LINE:
		while grid.gLines.need_execute_next_undo_in_object_mode():
			# print_verbose("[Grid Editor] Undo (auto): ", undo_redo.get_current_action_name())
			undo_redo.undo()

func redo() -> void:
	_update_selection([], [])
	
	if not undo_redo.redo():
		return
	# print_verbose("[Grid Editor] Redo: ", undo_redo.get_current_action_name())
	
	if ui.get_active_ui_tool_mode() != ui.LINE:
		while grid.gLines.need_execute_next_redo_in_object_mode():
			if not undo_redo.redo():
				return
			# print_verbose("[Grid Editor] Redo (auto): ", undo_redo.get_current_action_name())


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
		ui._active_ui_tool = ui.ELEMENT
