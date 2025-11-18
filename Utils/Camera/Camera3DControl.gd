# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node3D

## move step for keyboard actions (CAMERA_MOVE_FRONT, CAMERA_MOVE_BACK, CAMERA_MOVE_LEFT, CAMERA_MOVE_RIGHT, CAMERA_MOVE_UP, CAMERA_MOVE_DOWN keys)
@export var keyboard_move_step := 1.7
## multiplier for [member keyboard_move_step] used on _FAST variant of action
@export var keyboard_move_step_multiplier  := 5.0
## move step into camera direction while using keybord (CAMERA_SMOOTH_ZOOM_IN / CAMERA_SMOOTH_ZOOM_OUT)
@export var keyboard_zoom_step := 4.0
## move step into camera direction while using keybord (CAMERA_SMOOTH_ZOOM_IN_FAST / CAMERA_SMOOTH_ZOOM_OUT_FAST)
@export var keyboard_zoom_step_fast := 17.0
## zoom (change [member Camera3D.fov]) step for keyboard actions (CAMERA_FOV_ZOOM_IN and CAMERA_FOV_ZOOM_OUT keys, use both for reset FOV to default)
@export var keyboard_zoom_fov_step := 60
## rotation step for keyboard actions (CAMERA_ROTATE_LEFT, CAMERA_ROTATE_RIGHT, CAMERA_ROTATE_DOWN and CAMERA_ROTATE_UP keys)
@export var keyboard_rotation_step := 1.7

## move step into camera direction while using mouse scroll (or keyboard shortcut) (CAMERA_STEP_ZOOM_IN / CAMERA_STEP_ZOOM_OUT)
@export var button_move_step_z  := 0.4
## multiplier for [member button_move_step_z] used on _FAST variant of action
@export var button_move_step_z_multiplier  := 5.0

## move step in camera view plane for mouse moving (CAMERA_MOUSE_MOVE)
@export var mouse_move_step  := 0.01
## rotation step for mouse moving (CAMERA_MOUSE_ROTATE)
@export var mouse_rotation_step := 0.01
## move step in camera view plane for mouse moving (CAMERA_MOUSE_ZOOM)
@export var mouse_zooming_step := 0.01

## when [code]false[/code] camera keyboard input will be captured in [code]_input()[/code] and may block receive camera related input event by Control nodes
@export var process_camera_input_after_gui := true

## path to camera node (by default this node / node with attached script)
@export_node_path("Camera3D") var camera_node : NodePath
## path to camera target (by default this node / node with attached script),
## if different than [member camera_node] then conrols will be works in two node camera  mode
@export_node_path("Node3D") var target_node : NodePath
## initial distance between [member camera_node] and [member target_node] (apply only when [code]camera_node != target_node[/code])
@export var target_camera_initial_distance := 4.0

## Name of settings group for this object. This allowing override some properties and input maps.
## Set to empty string to disable using settings (hide in settings menu, disallow override properties and key mapping).
@export var settings_group_name := "CAMERA3D_SETTINGS_GROUP_NAME"

## when [code]true[/code] camera can be controlled by mouse too
var use_mouse_control := true

func disable_input() -> void:
	_input_disabled = true
	_move = Vector3.ZERO
	_move_valid = false
	_rotation = Vector2.ZERO
	_fov = 0.0

func enable_input() -> void:
	_input_disabled = false

@onready var _last_input_time := Time.get_ticks_usec()

var _camera : Node3D
var _target : Node3D
var _default_fov : float
var _input_disabled := false

func _init() -> void:
	var default_settings = FAG_Settings.set_default_setting_from_object(self, "CAMERA3D_SETTINGS_", [
		"keyboard_move_step",
		"keyboard_move_step_multiplier",
		"keyboard_zoom_fov_step",
		"keyboard_rotation_step",
		
		"button_move_step_z",
		"button_move_step_z_multiplier",
		
		"mouse_move_step",
		"mouse_rotation_step",
		"mouse_zooming_step",
	])
	
	var default_controls = FAG_Settings.set_default_controls_and_create_actions("ACTION_", {
		"CAMERA_MOVE_FRONT": [{"key": KEY_KP_8}, {"key": KEY_W}],
		"CAMERA_MOVE_FRONT_FAST": [{"key": KEY_KP_8, "shift": true}, {"key": KEY_W, "shift": true}],
		"CAMERA_MOVE_BACK": [{"key": KEY_KP_2}, {"key": KEY_S}],
		"CAMERA_MOVE_BACK_FAST": [{"key": KEY_KP_2, "shift": true}, {"key": KEY_S, "shift": true}],
		"CAMERA_MOVE_LEFT": [{"key": KEY_KP_4}, {"key": KEY_A}],
		"CAMERA_MOVE_LEFT_FAST": [{"key": KEY_KP_4, "shift": true}, {"key": KEY_A, "shift": true}],
		"CAMERA_MOVE_RIGHT": [{"key": KEY_KP_6}, {"key": KEY_D}],
		"CAMERA_MOVE_RIGHT_FAST": [{"key": KEY_KP_6, "shift": true}, {"key": KEY_D, "shift": true}],
		"CAMERA_MOVE_UP": [{"key": KEY_KP_9}, {"key": KEY_C}],
		"CAMERA_MOVE_UP_FAST": [{"key": KEY_KP_9, "shift": true}, {"key": KEY_C, "shift": true}],
		"CAMERA_MOVE_DOWN": [{"key": KEY_KP_3}, {"key": KEY_Z}],
		"CAMERA_MOVE_DOWN_FAST": [{"key": KEY_KP_3, "shift": true}, {"key": KEY_Z, "shift": true}],
		
		"CAMERA_ROTATE_LEFT": [{"key": KEY_KP_0}],
		"CAMERA_ROTATE_RIGHT": [{"key": KEY_KP_PERIOD}],
		"CAMERA_ROTATE_DOWN": [{"key": KEY_KP_7}],
		"CAMERA_ROTATE_UP": [{"key": KEY_KP_1}],
		"CAMERA_FOV_ZOOM_IN": [{"key": KEY_KP_MULTIPLY}],
		"CAMERA_FOV_ZOOM_OUT": [{"key": KEY_KP_DIVIDE}],
		"CAMERA_SMOOTH_ZOOM_IN": [{"key": KEY_KP_ADD}],
		"CAMERA_SMOOTH_ZOOM_IN_FAST": [{"key": KEY_KP_ADD, "shift": true}],
		"CAMERA_SMOOTH_ZOOM_OUT": [{"key": KEY_KP_SUBTRACT}],
		"CAMERA_SMOOTH_ZOOM_OUT_FAST": [{"key": KEY_KP_SUBTRACT, "shift": true}],
		
		"CAMERA_STEP_ZOOM_IN": [{"button": MOUSE_BUTTON_WHEEL_UP}],
		"CAMERA_STEP_ZOOM_IN_FAST": [{"button": MOUSE_BUTTON_WHEEL_UP, "shift": true}],
		"CAMERA_STEP_ZOOM_OUT": [{"button": MOUSE_BUTTON_WHEEL_DOWN}],
		"CAMERA_STEP_ZOOM_OUT_FAST": [{"button": MOUSE_BUTTON_WHEEL_DOWN, "shift": true}],
		
		"CAMERA_MOUSE_ROTATE": [{"button": MOUSE_BUTTON_MIDDLE}],
		"CAMERA_MOUSE_MOVE": [{"button": MOUSE_BUTTON_MIDDLE, "shift": true}],
		"CAMERA_MOUSE_ZOOM": [{"button": MOUSE_BUTTON_MIDDLE, "ctrl": true}],
	})
	
	if settings_group_name:
		FAG_Settings.register_settings(self, settings_group_name, default_settings, default_controls)

func _ready() -> void:
	if camera_node:
		_camera = get_node(camera_node)
	else:
		_camera = self
	if target_node:
		_target = get_node(target_node)
	else:
		_target = self
		
	if _camera != _target:
		_camera.position = Vector3(0, 0, target_camera_initial_distance)
		_camera.look_at(_target.position)
	
	_default_fov = _camera.fov


var _move := Vector3.ZERO
var _move_valid := false
var _rotation := Vector2.ZERO
var _zoom_z := 0.0
var _fov := 0.0

func _camera_keyboard_input(event: InputEvent) -> void:
	var camera_input_event = false
	for action in [
		"CAMERA_MOVE_FRONT", "CAMERA_MOVE_FRONT_FAST", "CAMERA_MOVE_BACK", "CAMERA_MOVE_BACK_FAST",
		"CAMERA_MOVE_LEFT", "CAMERA_MOVE_LEFT_FAST", "CAMERA_MOVE_RIGHT", "CAMERA_MOVE_RIGHT_FAST",
		"CAMERA_MOVE_UP", "CAMERA_MOVE_UP_FAST", "CAMERA_MOVE_DOWN", "CAMERA_MOVE_DOWN_FAST",
		"CAMERA_SMOOTH_ZOOM_IN", "CAMERA_SMOOTH_ZOOM_OUT",
		"CAMERA_FOV_ZOOM_IN", "CAMERA_SMOOTH_ZOOM_IN_FAST", "CAMERA_FOV_ZOOM_OUT", "CAMERA_SMOOTH_ZOOM_OUT_FAST",
		"CAMERA_ROTATE_LEFT", "CAMERA_ROTATE_RIGHT", "CAMERA_ROTATE_DOWN", "CAMERA_ROTATE_UP"
	]:
		if FAG_Utils.action_exact_match(action, event):
			camera_input_event = true
			break
	if camera_input_event:
		get_viewport().set_input_as_handled()
	else:
		return
	
	var move := Vector3.ZERO
	var fast_mode = false
	if FAG_Utils.action_exact_match_pressed("CAMERA_MOVE_FRONT"):
		move.z = -1
	elif FAG_Utils.action_exact_match_pressed("CAMERA_MOVE_FRONT_FAST"):
		move.z = -keyboard_move_step_multiplier
		fast_mode = true
	elif FAG_Utils.action_exact_match_pressed("CAMERA_MOVE_BACK"):
		move.z = 1
	elif FAG_Utils.action_exact_match_pressed("CAMERA_MOVE_BACK_FAST"):
		move.z = keyboard_move_step_multiplier
		fast_mode = true
	
	if FAG_Utils.action_exact_match_pressed("CAMERA_MOVE_LEFT"):
		move.x = -1
	elif FAG_Utils.action_exact_match_pressed("CAMERA_MOVE_LEFT_FAST"):
		move.x = -keyboard_move_step_multiplier
		fast_mode = true
	elif FAG_Utils.action_exact_match_pressed("CAMERA_MOVE_RIGHT"):
		move.x = 1
	elif FAG_Utils.action_exact_match_pressed("CAMERA_MOVE_RIGHT_FAST"):
		move.x = keyboard_move_step_multiplier
		fast_mode = true
	
	if FAG_Utils.action_exact_match_pressed("CAMERA_MOVE_UP"):
		move.y = 1
	elif FAG_Utils.action_exact_match_pressed("CAMERA_MOVE_UP_FAST"):
		move.y = keyboard_move_step_multiplier
		fast_mode = true
	elif FAG_Utils.action_exact_match_pressed("CAMERA_MOVE_DOWN"):
		move.y = -1
	elif FAG_Utils.action_exact_match_pressed("CAMERA_MOVE_DOWN_FAST"):
		move.y = -keyboard_move_step_multiplier
		fast_mode = true
	
	if move.x != 0 or move.y != 0 or move.z != 0:
		# project (X, Z) move from camera local to global X, Z plane
		# but use raw Y value as global Y
		var ori := Vector3(0,0,1)
		ori *= _target.quaternion
		if abs(_target.rotation.x) > PI/4:
			ori.z = -ori.y
		ori.y = 0
		ori = ori.normalized()
		
		_move = Vector3(
			ori.z * move.x - ori.x * move.z,
			move.y,
			ori.z * move.z + ori.x * move.x
		).normalized()
		
		_move *= keyboard_move_step
		if fast_mode:
			_move *= keyboard_move_step_multiplier
		_move_valid = true
	else:
		_move_valid = false
	
	if FAG_Utils.action_exact_match_pressed("CAMERA_ROTATE_LEFT"):
		_rotation.y = keyboard_rotation_step
	elif FAG_Utils.action_exact_match_pressed("CAMERA_ROTATE_RIGHT"):
		_rotation.y = -keyboard_rotation_step
	else:
		_rotation.y = 0
	
	if FAG_Utils.action_exact_match_pressed("CAMERA_ROTATE_UP"):
		_rotation.x = -keyboard_rotation_step 
	elif FAG_Utils.action_exact_match_pressed("CAMERA_ROTATE_DOWN"):
		_rotation.x = keyboard_rotation_step
	else:
		_rotation.x = 0
	
	if FAG_Utils.action_exact_match_pressed("CAMERA_SMOOTH_ZOOM_IN"):
		_zoom_z = -keyboard_zoom_step
	elif FAG_Utils.action_exact_match_pressed("CAMERA_SMOOTH_ZOOM_OUT"):
		_zoom_z = keyboard_zoom_step
	elif FAG_Utils.action_exact_match_pressed("CAMERA_SMOOTH_ZOOM_IN_FAST"):
		_zoom_z = -keyboard_zoom_step_fast
	elif FAG_Utils.action_exact_match_pressed("CAMERA_SMOOTH_ZOOM_OUT_FAST"):
		_zoom_z = keyboard_zoom_step_fast
	else:
		_zoom_z = 0
	
	if FAG_Utils.action_exact_match_pressed("CAMERA_FOV_ZOOM_IN") and FAG_Utils.action_exact_match_pressed("CAMERA_FOV_ZOOM_OUT"):
		_fov = 0
		_camera.fov = _default_fov
	elif FAG_Utils.action_exact_match_pressed("CAMERA_FOV_ZOOM_IN"):
		_fov = -keyboard_zoom_fov_step
	elif FAG_Utils.action_exact_match_pressed("CAMERA_FOV_ZOOM_OUT"):
		_fov = keyboard_zoom_fov_step
	else:
		_fov = 0

func _process(_delta: float) -> void:
	if not Input.is_anything_pressed():
		_last_input_time = Time.get_ticks_usec()
		return
	
	# use own delta, because argument is scaled with Engine.time_scale 
	var time := Time.get_ticks_usec()
	var delta := (time - _last_input_time) * 0.000001
	_last_input_time = time
	
	if _move_valid:
		_target.global_translate(_move * delta)
	
	if _rotation.y:
		_update_yaw(_rotation.y * delta)
	
	if _rotation.x:
		_update_pitch(_rotation.x * delta)
	
	if _zoom_z:
		_translate(Vector3(0, 0, _zoom_z * delta))
	
	if _fov:
		_update_zoom(_fov * delta)

func _unhandled_input(event: InputEvent) -> void:
	if _input_disabled:
		return
	if process_camera_input_after_gui:
		_camera_keyboard_input(event)
	if event is InputEventWithModifiers:
		# using event with echo for support mouse scroll and keyboard shortcuts here
		if FAG_Utils.action_exact_match_pressed("CAMERA_STEP_ZOOM_IN", event, true):
			_translate(Vector3(0, 0, -button_move_step_z))
		elif FAG_Utils.action_exact_match_pressed("CAMERA_STEP_ZOOM_IN_FAST", event, true):
			_translate(Vector3(0, 0, -button_move_step_z * button_move_step_z_multiplier))
		elif FAG_Utils.action_exact_match_pressed("CAMERA_STEP_ZOOM_OUT", event, true):
			_translate(Vector3(0, 0, button_move_step_z))
		elif FAG_Utils.action_exact_match_pressed("CAMERA_STEP_ZOOM_OUT_FAST", event, true):
			_translate(Vector3(0, 0, button_move_step_z * button_move_step_z_multiplier))
	if event is InputEventMouseMotion:
		if FAG_Utils.action_exact_match_pressed("CAMERA_MOUSE_ROTATE"):
			_update_yaw(-event.relative.x * mouse_rotation_step)
			_update_pitch(-event.relative.y * mouse_rotation_step)
		elif FAG_Utils.action_exact_match_pressed("CAMERA_MOUSE_MOVE"):
			_translate(Vector3(-event.relative.x, event.relative.y, 0) * mouse_move_step)
		elif FAG_Utils.action_exact_match_pressed("CAMERA_MOUSE_ZOOM"):
			_translate(Vector3(0, 0, event.relative.y * mouse_zooming_step))

func _input(event: InputEvent) -> void:
	if _input_disabled or process_camera_input_after_gui:
		return
	_camera_keyboard_input(event)
	
func _translate(value : Vector3):
	if _target != _camera:
		if value.z:
			_camera.position.z += value.z
			if _camera.position.z < 0:
				_camera.position.z = 0
		else:
			_target.translate(Vector3(-value.x, 0, value.y))
	else:
		_camera.translate(value)

func _update_zoom(value : float):
	_camera.fov = clamp(_camera.fov + value, 1, 179) # preventing errors in Godot code 

func _update_yaw(value : float):
	_target.rotation.y += value  # don't use _target.rotate_y(value) due to Euler rotations combining

func _update_pitch(value : float):
	_target.rotation.x = clamp(_target.rotation.x + value, PI/-2, PI/2)  # don't use _target.rotate_x(value) due to Euler rotations combining
