# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node2D

@export_group("Editor Cursor settings")

@export var select_cursor : FAG_CursorInfo
@export var duplicate_cursor : FAG_CursorInfo
@export var move_cursor : FAG_CursorInfo
@export var rotate_cursor : FAG_CursorInfo
@export var mirror_cursor : FAG_CursorInfo
@export var scale_cursor : FAG_CursorInfo
@export var rename_cursor : FAG_CursorInfo
@export var delete_cursor : FAG_CursorInfo
@export var draw_cursor : FAG_CursorInfo
@export var add_element_cursor : FAG_CursorInfo

@export_group("Selection Box Settings")
@export var selection_box_enabled := true
@export var selection_box_stroke_color := Color(0, 1.0, 0, 1.0)
@export var selection_box_stroke_width := 5
@export var selection_box_fill_color := Color(0.5, 1.0, 0, 0.4)

@export_group("Import Export Settings")
@export var import_export_enabled := true
@export var import_export_path := ""
@export var import_export_root_subfolder := ""

@export_group("Editor Mics Settings")

@export var scale_tool_enabled := false
@export var duplicate_tool_enabled := false
@export var line_tool_enabled := false
@export var rename_tool_enabled := false
@export var elements : Array[PackedScene] = []

## function used for getting editable elements on [param _point],
## should be provided by class using WorldEditorUI
@export var do_raycast : Callable = func(_point : Vector2): return null

## Name of settings group for this object. This allowing override some properties and input maps.
## Set to empty string to disable using settings (hide in settings menu, disallow override properties and key mapping).
@export var settings_group_name := "WORLD_EDITOR_UI_SETTINGS_GROUP_NAME"

enum {NONE, SELECT, SELECT_LONG, DUPLICATE, MOVE, SCALE, SCALE_IN_PROGRESS, ROTATE, MIRROR, RENAME, DELETE, LINE, ELEMENT}
var _active_ui_tool := NONE
func get_active_ui_tool_mode(): return _active_ui_tool

# used to blocked input to edited world while operating on Editor GUI
var _mouse_in_gui_area := false
func mouse_in_gui_area(): return _mouse_in_gui_area

var input_allowed := true


### Signals

## emitted on undo action
signal undo()

## emitted on redo action
signal redo()

## emitted on save action
signal do_save(path: String)

## emitted on redo action
signal do_import(path: String)

## emitted when mouse enter / exit from UI area
signal mouse_enter_exit_gui_area(enter: bool)

## emitted when input mode (e.g. used tool) was changed
signal active_ui_tool_changed(mode : int, button_name : String, element : PackedScene)

## emitted when mouse button pressed on not null results of do_raycast.call(point)
signal do_on_raycast_result(mode : int, point : Vector2, raycast_result : Variant)

## emitted when mouse button pressed on selection box
signal do_on_selection(mode : int, point : Vector2, selection_box : Variant)

## emitted (in MOVE mode) when mouse move
signal do_move_step(point : Vector2)

## emitted (in MOVE mode) when the left mouse button is released
signal do_move_finish()

## emitted (in SELECT mode) when the left mouse button is released
signal do_on_raycast_selection_finish(raycast_result : Variant)

## emitted (in SCALE mode) when mouse move
signal do_scale_step(point : Vector2)

## emitted (in SCALE mode) when the left mouse button is released
signal do_scale_finish()

## emitted when selection box has been hidden
signal selection_box_has_been_hidden()

## emitted (in LINE mode) when new line is started (with first line point)
signal line_add_point(point : Vector2)

## emitted (in LINE mode) when mouse move
signal line_update_last_point(point : Vector2)

## emitted (in LINE mode) when the left mouse button is released
signal line_finish()

## emitted (in ELEMENT mode) when the left mouse button is pressed
signal element_add__finish(point : Vector2)

## emitted (in ELEMENT mode) when mouse move
signal element_add__update(point : Vector2)

## emitted on lost focus
signal focus_lost()


### Init

@onready var _editor_enabled := true
@onready var _ui_add_elements_container := %AddElements
@onready var _ui_tool_button_group : ButtonGroup = %Tools.get_child(0).button_group
@onready var _selection_box := %SelectionBox
@onready var _file_dialog := %FileDialog
@onready var _elements_dict := {}

func _init() -> void:
	var default_controls = FAG_Settings.set_default_controls_and_create_actions("ACTION_", {
		"EDIT_UNDO": [{"key": KEY_Z, "ctrl": true}],
		"EDIT_REDO": [{"key": KEY_Z, "ctrl": true, "shift": true}],
		"EDIT_SELECT_MOVE": [{"key": KEY_G}],
		"EDIT_DUPLICATE": [{"key": KEY_D, "ctrl": true}],
		"EDIT_SCALE": [{"key": KEY_B}],
		"EDIT_ROTATE": [{"key": KEY_R}],
		"EDIT_MIRROR": [{"key": KEY_M}],
		"EDIT_DELETE": [{"key": KEY_X}],
		"EDIT_LINE_TOOL": [{"key": KEY_L}],
		"EDIT_RENAME": [{"key": KEY_N}],
	})
	
	if settings_group_name:
		FAG_Settings.register_settings(self, settings_group_name, {}, default_controls)
		FAG_Settings.keymap_update.connect(_on_keymap_update)

func _ready() -> void:
	_selection_box.stroke_color = selection_box_stroke_color
	_selection_box.stroke_width = selection_box_stroke_width
	_selection_box.fill_color = selection_box_fill_color
	
	if not import_export_enabled:
		%Actions/Import.visible = false
		%Actions/Save.visible = false
	if not duplicate_tool_enabled:
		%Tools/Duplicate.visible = false
	if not scale_tool_enabled:
		%Tools/Scale.visible = false
	if not line_tool_enabled:
		%AddElements/Line.visible = false
	if not rename_tool_enabled:
		%Tools/Rename.visible = false
	
	_on_keymap_update()
	
	_set_no_input_transparent_ui(%FixedButtons)
	_set_no_input_transparent_ui(%ScrollableButtons)
	
	for element in elements:
		add_element(element)
	
	FAG_WindowManager.embeded_window_focus_changed.connect(
		func (_win, _val):
			var tree = get_tree()
			if not tree:
				return
			if not tree.process_frame.is_connected(_check_if_focus_changed):
				tree.process_frame.connect(_check_if_focus_changed, CONNECT_ONE_SHOT)
	)
	
	reset_editor()

func _on_keymap_update() -> void:
	%Actions/Undo.shortcut = FAG_Utils.create_shorcut("EDIT_UNDO")
	%Actions/Redo.shortcut = FAG_Utils.create_shorcut("EDIT_REDO")
	%Tools/SelectMove.shortcut = FAG_Utils.create_shorcut("EDIT_SELECT_MOVE")
	%Tools/Duplicate.shortcut = FAG_Utils.create_shorcut("EDIT_DUPLICATE")
	%Tools/Rotate.shortcut = FAG_Utils.create_shorcut("EDIT_ROTATE")
	%Tools/Mirror.shortcut = FAG_Utils.create_shorcut("EDIT_MIRROR")
	%Tools/Delete.shortcut = FAG_Utils.create_shorcut("EDIT_DELETE")
	%Tools/Rename.shortcut = FAG_Utils.create_shorcut("EDIT_RENAME")
	%Tools/Scale.shortcut = FAG_Utils.create_shorcut("EDIT_SCALE")
	%AddElements/Line.shortcut = FAG_Utils.create_shorcut("EDIT_LINE_TOOL")


func reset_editor() -> void:
	_raycast_result = null
	%Tools/SelectMove.button_pressed = true
	_on_ui_tool_selected(true)

func set_editor_enabled(value : bool) -> void:
	_editor_enabled = value
	clear_selection()
	if not _editor_enabled:
		reset_editor()
	%UI.visible = _editor_enabled

func set_visibility(value : bool) -> void:
	visible = value
	%UI.visible = value

func add_element(element : PackedScene) -> void:
	var state = element.get_state()
	var button := _ui_add_elements_container.get_child(0).duplicate()
	button.name = state.get_node_name(0)
	button.visible = true
	button.shortcut = null
	print("Add element to editor UI: ", button.name)
	# iterate over properties of first child of root node
	# (node index == 0 => first (root) node in packed scene)
	for i in range(state.get_node_property_count(0)):
		if state.get_node_property_name(0, i) == "ui_name":
			button.tooltip_text = state.get_node_property_value(0, i)
		if state.get_node_property_name(0, i) == "ui_icon":
			button.icon = state.get_node_property_value(0, i)
	_ui_add_elements_container.add_child(button)
	_set_no_input_transparent_ui(button)
	_elements_dict[button.name] = [element, button]

func _set_no_input_transparent_ui(node: Control) -> void:
	node.connect("mouse_entered", _mouse_in_gui_area_set.bind(true))
	node.connect("mouse_exited",  _mouse_in_gui_area_set.bind(false))
	for child in node.get_children():
		_set_no_input_transparent_ui(child)

func _mouse_in_gui_area_set(value: bool) -> void:
	_mouse_in_gui_area = value
	mouse_enter_exit_gui_area.emit(value)


### Buttons callbacks functions

func _on_import_pressed() -> void:
	_show_file_dialog(FileDialog.FILE_MODE_OPEN_FILE)

func _on_save_pressed() -> void:
	_show_file_dialog(FileDialog.FILE_MODE_SAVE_FILE)

func _show_file_dialog(mode) -> void:
	if input_allowed:
		_file_dialog.file_mode = mode
		_file_dialog.root_subfolder = import_export_root_subfolder
		if import_export_path:
			_file_dialog.current_dir = ProjectSettings.globalize_path(import_export_path)
		_file_dialog.invalidate()
		_file_dialog.show()


func _on_file_dialog_file_selected(path: String) -> void:
	if _file_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		print("World editor IMPORT request for: ", path)
		do_import.emit(path)
	elif _file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		print("World editor SAVE request for: ", path)
		do_save.emit(path)

func _on_undo_pressed() -> void:
	if input_allowed:
		undo.emit()

func _on_redo_pressed() -> void:
	if input_allowed:
		redo.emit()

func _on_ui_tool_selected(force := false) -> void:
	if input_allowed == false and force == false:
		return
	
	var button_name = _ui_tool_button_group.get_pressed_button().name
	match button_name:
		"SelectMove":
			_active_ui_tool = SELECT
			_ui_set_cursor(select_cursor)
		"Duplicate":
			_active_ui_tool = DUPLICATE
			_ui_set_cursor(duplicate_cursor)
		"Scale":
			_active_ui_tool = SCALE
			_ui_set_cursor(scale_cursor)
		"Rotate":
			_active_ui_tool = ROTATE
			_ui_set_cursor(rotate_cursor)
		"Mirror":
			_active_ui_tool = MIRROR
			_ui_set_cursor(mirror_cursor)
		"Rename":
			_active_ui_tool = RENAME
			_ui_set_cursor(rename_cursor)
		"Delete":
			_active_ui_tool = DELETE
			_ui_set_cursor(delete_cursor)
		"Line":
			_active_ui_tool = LINE
			_ui_set_cursor(draw_cursor)
		_:
			_active_ui_tool = ELEMENT
			_ui_set_cursor(add_element_cursor)
	
	if _active_ui_tool == LINE or _active_ui_tool == ELEMENT:
		clear_selection()
	
	var element = _elements_dict.get(button_name, null)
	active_ui_tool_changed.emit(_active_ui_tool, button_name, element[0] if element else null)


### Input processing

var _raycast_result = null

func _unhandled_input(event: InputEvent) -> void:
	if _mouse_in_gui_area or not input_allowed:
		return
	
	var point := get_local_mouse_position()
	
	if _active_ui_tool == LINE:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				line_add_point.emit(point)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				line_finish.emit()
		elif event is InputEventMouseMotion:
			line_update_last_point.emit(point)
	
	elif _active_ui_tool == ELEMENT:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			element_add__finish.emit(point)
		elif event is InputEventMouseMotion:
			element_add__update.emit(point)
	
	else:
		# selected / edit existed element mode and mouse button
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _selection_box.hit_in_selection_box(point):
					if _active_ui_tool == SELECT:
						_active_ui_tool = MOVE
						_ui_set_cursor(move_cursor)
					do_on_selection.emit(_active_ui_tool, point, _selection_box)
				else:
					clear_selection()
					_raycast_result = do_raycast.call(point)
					if _editor_enabled:
						if _raycast_result:
							if _active_ui_tool == SELECT:
								_set_move_mode()
							elif _active_ui_tool == SCALE:
								_active_ui_tool = SCALE_IN_PROGRESS
							do_on_raycast_result.emit(_active_ui_tool, point, _raycast_result)
						elif selection_box_enabled:
							_selection_box.init(point)
			else: # mouse button released
				if _active_ui_tool == MOVE or _active_ui_tool == SELECT_LONG:
					do_move_finish.emit()
					_active_ui_tool = SELECT
					_ui_set_cursor(select_cursor)
				elif _active_ui_tool == SCALE_IN_PROGRESS:
					do_scale_finish.emit()
					_active_ui_tool = SCALE
				elif _active_ui_tool == SELECT or _active_ui_tool == DUPLICATE:
					if _selection_box.visible:
						_selection_box.is_done = true
					if _selection_box.is_approx_zero_size():
						clear_selection()
					do_on_raycast_selection_finish.emit(_raycast_result)
				_raycast_result = null
		
		# selected / edit existed element mode and mouse move
		elif event is InputEventMouseMotion:
			_set_move_mode(true)
			if _active_ui_tool == MOVE:
				do_move_step.emit(get_local_mouse_position())
			elif _active_ui_tool == SCALE_IN_PROGRESS:
				do_scale_step.emit(get_local_mouse_position())
			elif _active_ui_tool == SELECT and not _selection_box.is_done:
				_selection_box.set_second(get_local_mouse_position())

func _set_move_mode(immediately := false):
	if not immediately:
		await FAG_Utils.real_time_wait(0.13)
	# 1. timers are "processed after all of the nodes in the current frame"
	# 2. _unhandled_input is processed before at begin of nodes processing
	# so it should not be a race condition between this code and "mouse button released"
	# in _unhandled_input where we set _active_ui_tool to SELECT and _current_element/segment to null
	if _active_ui_tool == SELECT and _raycast_result:
		if _editor_enabled:
			_active_ui_tool = MOVE
			_ui_set_cursor(move_cursor)
		else:
			# used to possibility of emit long click action (via do_move_finish action) while editor is disabled
			_active_ui_tool = SELECT_LONG

func clear_selection():
	_selection_box.is_done = false
	_selection_box.visible = false
	selection_box_has_been_hidden.emit()


### Helper functions for UI

var _last_focus := false
func _check_if_focus_changed() -> void:
	var new_focus
	if get_viewport() == get_tree().root:
		new_focus = not FAG_WindowManager.focus_is_on_embeded_window()
	else:
		new_focus = get_viewport().has_focus()
	if _last_focus != new_focus:
		_last_focus = new_focus
		update_cursor(_last_focus)
		if not _last_focus:
			_raycast_result = null
			focus_lost.emit()

var _ui_cursor = []
func _ui_set_cursor(cursor : FAG_CursorInfo) -> void:
	_ui_cursor = cursor
	update_cursor()

func update_cursor(focus = true, force = false):
	# print_verbose("update_cursor ", self, " child of ", get_parent(), " focus=", focus)
	if focus:
		FAG_WindowManager.cursor_owner = get_viewport()
		Input.set_custom_mouse_cursor(_ui_cursor.image, Input.CURSOR_ARROW, _ui_cursor.hotspot)
	elif FAG_WindowManager.cursor_owner == get_viewport() or force:
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
		FAG_WindowManager.cursor_owner = null


### Fix ScrollBar space reservation in ScrollContainer

# we need below trick due to wrong placement scroll bar space reservation
# while scroll is moved to left side of ScrollContainer

@onready var _magin_container := %ScrollableButtons
@onready var _elements_v_scroll := _init_fix_scrool_bar()

func _init_fix_scrool_bar() -> VScrollBar:
	_elements_v_scroll = %ScrollContainer.get_v_scroll_bar()
	_elements_v_scroll.connect("visibility_changed", _on_scroll_bar_visibility_changed)
	%FixedButtons.add_theme_constant_override("margin_left", 4 + _elements_v_scroll.size.x)
	return _elements_v_scroll

func _on_scroll_bar_visibility_changed() -> void:
	if _elements_v_scroll.visible:
		_magin_container.add_theme_constant_override("margin_left", 4)
	else:
		_magin_container.add_theme_constant_override("margin_left", 4 + _elements_v_scroll.size.x)
