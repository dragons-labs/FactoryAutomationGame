# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Camera2D

signal camera_updated()

@export_node_path("Node2D") var world : NodePath

@export var zoom_step_factor := 0.05 :
	set(value):
		zoom_step_factor = value
		_zoom_step = Vector2(zoom_step_factor, zoom_step_factor)
@export var center_camera_on_zoom := true :
	set(value):
		center_camera_on_zoom = value
		if _ui:
			_ui.set_center_on_zoom(center_camera_on_zoom)
@export var show_ui := true :
	set(value):
		show_ui = value
		if _ui:
			_ui.visible = show_ui

@export var ui_enabled := true


## Name of settings group for this object. This allowing override some properties and input maps.
## Set to empty string to disable using settings (hide in settings menu, disallow override properties and key mapping).
@export var settings_group_name := "CAMERA2D_SETTINGS_GROUP_NAME"

func reset_view() -> void:
	position = Vector2.ZERO
	zoom = Vector2.ONE
	camera_updated.emit()

func set_visibility(value : bool) -> void:
	visible = value
	$CanvasLayer.visible = value

var use_mouse_control := true
@onready var viewport = get_viewport()
var _zoom_step := Vector2(zoom_step_factor, zoom_step_factor)
var _world : Node2D
var _ui : Node

func _init() -> void:
	var default_settings = FAG_Settings.set_default_setting_from_object(self, "CAMERA2D_SETTINGS_", [
		"zoom_step_factor",
		"center_camera_on_zoom",
		"show_ui",
	])
	var default_controls = FAG_Settings.set_default_controls_and_create_actions("ACTION_", {
		"CAMERA_2D_ZOOM_IN": [{"button": MOUSE_BUTTON_WHEEL_UP}],
		"CAMERA_2D_ZOOM_OUT": [{"button": MOUSE_BUTTON_WHEEL_DOWN}],
		"CAMERA_2D_MOUSE_MOVE": [{"button": MOUSE_BUTTON_MIDDLE}],
		"CAMERA_2D_RESET":[{"button": MOUSE_BUTTON_MIDDLE, "double_click": true}],
	})
	
	if settings_group_name:
		FAG_Settings.register_settings(self, settings_group_name, default_settings, default_controls)

func _ready() -> void:
	if world:
		_world = get_node(world)
	else:
		_world = get_parent()
	
	if ui_enabled:
		_ui = load(get_script().resource_path.get_base_dir() + "/UI_Settings_Camera2D.tscn").instantiate()
		_ui.center_on_zoom_enabled.connect(func(val) : center_camera_on_zoom = val)
		_ui.reset_view.connect(reset_view)
		add_child(_ui)
	if _ui:
		_ui.visible = show_ui
		_ui.set_center_on_zoom(center_camera_on_zoom)

var _move_mode := false
func _unhandled_input(event: InputEvent) -> void:
	if not use_mouse_control:
		if _move_mode and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
			_move_mode = false
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return
	
	if _move_mode and event is InputEventMouseMotion:
		position -= event.relative / zoom
		camera_updated.emit()
	elif event is InputEventWithModifiers:
		if FAG_Utils.action_exact_match_pressed("CAMERA_2D_RESET", event):
			reset_view()
		elif FAG_Utils.action_exact_match_pressed("CAMERA_2D_ZOOM_IN", event, true):
			zoom += _zoom_step
			if center_camera_on_zoom:
				position = _world.get_local_mouse_position()
				viewport.warp_mouse(viewport.size/2)
			camera_updated.emit()
		elif FAG_Utils.action_exact_match_pressed("CAMERA_2D_ZOOM_OUT", event, true):
			if zoom > _zoom_step:
				zoom -= _zoom_step
				camera_updated.emit()
		elif FAG_Utils.action_exact_match_pressed("CAMERA_2D_MOUSE_MOVE", event, true):
			_move_mode = true
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		elif event.is_action_released("CAMERA_2D_MOUSE_MOVE", true):
			_move_mode = false
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
