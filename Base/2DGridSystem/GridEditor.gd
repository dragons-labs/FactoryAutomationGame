# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node2D

@export_group("Grid Elements")

@export var elements: Array[PackedScene] = []

@export_group("Basic Grid Settings")

@export var grid_size := Vector2(20, 20)
@export var grid_color := Color(0.9, 0.9, 0.9, 0.2)

@export_group("Grid Editor Mics Settings")

@export var orthogonal_lines := true

signal on_element_click(element: Node2D, long: bool)


### Init

@onready var undo_redo := UndoRedo.new()
@onready var grid := Grid2D_World.new(%Nodes, undo_redo, grid_size)
@onready var ui := %WorldEditorUI

func _ready() -> void:
	%VisualGrid.grid_size = grid_size
	%VisualGrid.grid_color = grid_color
	grid.gLines.grid_size = grid_size
	grid.gLines.orthogonal_lines = orthogonal_lines
	
	ui.line_add_point.connect(grid.gLines.new_line__add_point)
	ui.line_finish.connect(grid.gLines.new_line__finish)
	ui.line_update_last_point.connect(grid.gLines.new_line__update_segment)
	ui.element_add.connect(grid.gElements.add_element)
	ui.element_update_added.connect(grid.gElements.update_element)
	
	ui.do_raycast = func (point):
		var element = grid.gElements.find_element_by_point(point)
		var line_segment = grid.gLines.find_line_by_point(point)
		if element || line_segment:
			return [element, line_segment]
		return null
	
	for element in elements:
		ui.add_element(element)

func set_visibility(value : bool) -> void:
	visible = value
	%WorldEditorUI.call_deferred("set_visibility", value)
	%Camera2D.call_deferred("set_visibility", value)


### UI callbacks

func _on_active_ui_tool_changed(mode : int, _button_name : String, element : PackedScene) -> void:
	if not ui:
		return
	
	if mode == ui.LINE or mode == ui.ELEMENT:
		ui.clear_selection()
	
	if mode != ui.LINE:
		grid.gLines.new_line__finish()
	
	if mode != ui.ELEMENT:
		grid.gElements.cancel_element()
	else:
		grid.gElements.init_element(element, get_local_mouse_position())

var _current_element : Node2D = null
var _current_segment = {}

func _on_do_on_raycast_result(_mode : int, point : Vector2, raycast_result : Variant) -> void:
	_current_element = raycast_result[0]
	_current_segment = raycast_result[1]
	match ui.get_active_ui_tool_mode():
		ui.SELECT:
			if _current_segment:
				grid.gLines.update_segment__init([_current_segment], point)
			elif _current_element:
				grid.gElements.move_element__init([_current_element], point)
		ui.DELETE:
			if _current_segment:
				grid.gLines.remove_segment([_current_segment])
			elif _current_element:
				grid.gElements.delete_elements([_current_element])
		ui.ROTATE:
			if _current_element:
				grid.gElements.rotate_elements([_current_element], -PI/2)
		ui.MIRROR:
			if _current_element:
				grid.gElements.mirror_elements([_current_element])

var _selected_elements_and_segments_valid = false
var _selected_elements = []
var _selected_segmetnts = []
var _selection_move_init_area : Rect2
var _selection_move_init_point : Vector2

func _on_do_on_selection(mode: int, point: Vector2, selection_box: Variant) -> void:
	if not _selected_elements_and_segments_valid:
		var area = selection_box.get_area()
		_selected_elements = grid.gElements.find_elements_on_area(area)
		_selected_segmetnts = grid.gLines.find_segments_on_area(area)
		_selected_elements_and_segments_valid = true
	
	var action_is_init = false
	
	if mode == ui.MOVE:
		_selection_move_init_point = point
		_selection_move_init_area = selection_box.get_area()
		grid.gLines.update_segment__init(_selected_segmetnts, point)
		grid.gElements.move_element__init(_selected_elements, point)
	elif mode == ui.DELETE:
		action_is_init = grid.gLines.remove_segment(_selected_segmetnts, not action_is_init, false)
		action_is_init = grid.gElements.delete_elements(_selected_elements, not action_is_init, false)
		ui.clear_selection()
	elif mode == ui.ROTATE:
		selection_box.set_first(FAG_Utils.rotate_around_pivot(selection_box.get_first(), point, -PI/2))
		selection_box.set_second(FAG_Utils.rotate_around_pivot(selection_box.get_second(), point, -PI/2))
		action_is_init = grid.gLines.rotate_segments(_selected_segmetnts, -PI/2, point, not action_is_init, false)
		action_is_init = grid.gElements.rotate_elements(_selected_elements, -PI/2, point, not action_is_init, false)
	elif mode == ui.MIRROR:
		selection_box.set_first(FAG_Utils.mirror_y(selection_box.get_first(), point))
		selection_box.set_second(FAG_Utils.mirror_y(selection_box.get_second(), point))
		action_is_init = grid.gLines.mirror_segments(_selected_segmetnts, point, not action_is_init, false)
		action_is_init = grid.gElements.mirror_elements(_selected_elements, point, not action_is_init, false)
	
	if action_is_init:
		undo_redo.commit_action()

func _on_do_move_step(point):
	var new_point = _selection_move_init_area.position + (point - _selection_move_init_point)
	
	grid.gLines.update_segment__step(point)
	grid.gElements.move_element__step(point)
	
	ui._selection_box.set_first(new_point)
	ui._selection_box.set_second(new_point + _selection_move_init_area.size)

func _on_do_move_finish() -> void:
	var action_is_init = false
	action_is_init = grid.gLines.update_segment__finish(not action_is_init, false)
	action_is_init = grid.gElements.move_element__finish(not action_is_init, false) or action_is_init
	if action_is_init:
		undo_redo.commit_action()
	elif _current_element:
		# long click
		on_element_click.emit(_current_element, true)

func _on_do_move_cancel(raycast_result : Variant) -> void:
	if raycast_result and raycast_result[0]:
		on_element_click.emit(raycast_result[0], false)
	grid.gLines.move_segment__cancel()
	grid.gElements.move_element__cancel()

func _on_selection_box_has_been_hidden() -> void:
	_selected_elements_and_segments_valid = false


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
	if FAG_Utils.action_exact_match_pressed("EDIT_ROTATE", event) and ui.get_active_ui_tool_mode() == ui.ELEMENT:
		grid.gElements.new_element.rotate(-PI/2)
		get_viewport().set_input_as_handled()
	elif FAG_Utils.action_exact_match_pressed("EDIT_MIRROR", event) and ui.get_active_ui_tool_mode() == ui.ELEMENT:
		grid.gElements.new_element.scale *= -1
		get_viewport().set_input_as_handled()


### Undo-Redo system support

func undo() -> void:
	ui.clear_selection()
	
	# print_verbose("[Grid Editor] Undo: ", undo_redo.get_current_action_name())
	undo_redo.undo()
	
	if ui.get_active_ui_tool_mode() != ui.LINE:
		while grid.gLines.need_execute_next_undo_in_object_mode():
			# print_verbose("[Grid Editor] Undo (auto): ", undo_redo.get_current_action_name())
			undo_redo.undo()

func redo() -> void:
	ui.clear_selection()
	
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
	var screen_center_on_world = \
		(grid.gParent.get_global_transform() * grid.gParent.get_canvas_transform()).affine_inverse() \
		* Vector2(get_viewport().size/2)
	var data = FAG_Utils.load_from_json_file(path)
	grid.restore(data, ui._elements_dict, screen_center_on_world)
