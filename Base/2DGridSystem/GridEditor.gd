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
@export var use_interactive_import := true

## Name of settings group for this object. This allowing override some properties and input maps.
## Set to empty string to disable using settings (hide in settings menu, disallow override properties and key mapping).
@export var settings_group_name := "WORLD_EDITOR_UI_SETTINGS_GROUP_NAME"


signal on_element_click(element: Node2D, long: bool)


### Init

@onready var undo_redo := UndoRedo.new()
@onready var grid := FAG_2DGrid_World.new(%Nodes, undo_redo, grid_size)
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
		grid.gElements.add_element__cancel()
		grid.gLines.duplicate_cancel()
	else:
		grid.gElements.add_element__init(element, get_local_mouse_position())

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
		ui.DUPLICATE:
			if _current_element:
				grid.gElements.add_elements__init([_current_element], point)
				ui._active_ui_tool = ui.ELEMENT
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
	elif mode == ui.DUPLICATE:
		ui.clear_selection()
		grid.gElements.add_elements__init(_selected_elements, point)
		grid.gLines.init_duplicate(_selected_segmetnts, point)
		ui._active_ui_tool = ui.ELEMENT
	
	if action_is_init:
		undo_redo.commit_action()

func _on_add_element__update(point : Vector2) -> void:
	grid.gLines.duplicate_update(point)
	grid.gElements.add_element__update(point)

func _on_add_element__finish(point : Vector2) -> void:
	grid.gLines.duplicate_finish(point)
	grid.gElements.add_element__finish(point)

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

func _on_do_on_raycast_selection_finish(raycast_result : Variant) -> void:
	if raycast_result and raycast_result[0]:
		on_element_click.emit(raycast_result[0], false)
	
	if ui._selection_box.is_done and not _selected_elements_and_segments_valid:
		var area = ui._selection_box.get_area()
		_selected_elements = grid.gElements.find_elements_on_area(area)
		_selected_segmetnts = grid.gLines.find_segments_on_area(area)
		_selected_elements_and_segments_valid = true
		
		for element in _selected_elements:
			var base_element = FAG_2DGrid_BaseElement.get_from_element(element)
			base_element.get_node("Image").modulate = ui._selection_box.fill_color
			for connection in base_element.get_node("Connections").get_children():
				connection.modulate = ui._selection_box.fill_color
		for segment in _selected_segmetnts:
			segment.line.modulate = ui._selection_box.fill_color
			# TODO: we should colored only segments but this would require splitting/duplicating lines
		
		# ui._selection_box.visible = false
		# NOTE: we don't hide selection box because selection box area not selected element for future operation on selection
		#       also only segments of line inside selection box (not whole colored line) are operation target
	
	grid.gLines.move_segment__cancel()
	grid.gElements.move_element__cancel()

func _on_selection_box_has_been_hidden() -> void:
	for element in _selected_elements:
		var base_element = FAG_2DGrid_BaseElement.get_from_element(element)
		base_element.get_node("Image").modulate = Color.WHITE
		for connection in base_element.get_node("Connections").get_children():
			connection.modulate = Color.WHITE
	for segment in _selected_segmetnts:
		segment.line.modulate = Color.WHITE
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
		if len(grid.gElements._new_elements) == 1:
			for new_element in grid.gElements._new_elements:
				new_element.rotate(-PI/2)
		get_viewport().set_input_as_handled()
	elif FAG_Utils.action_exact_match_pressed("EDIT_MIRROR", event) and ui.get_active_ui_tool_mode() == ui.ELEMENT:
		if len(grid.gElements._new_elements) == 1:
			for new_element in grid.gElements._new_elements:
				new_element.scale *= -1
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
