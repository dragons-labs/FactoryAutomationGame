# SPDX-FileCopyrightText: 2025 Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-FileCopyrightText: Copyright (c) 2014-present Godot Engine contributors.
# SPDX-FileCopyrightText: Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
# SPDX-License-Identifier: MIT

# Based on https://github.com/godotengine/godot-demo-projects/tree/master/viewport/gui_in_3d

extends Node3D

## Packed scene with GUI to display, instanced scene root node will be available as [member gui].
## Alternatively you can use the "Editable Children" option and place the GUI as children of SubViewport.
@export var gui_scene : PackedScene :
	set(new_scene):
		gui_scene = new_scene
		if _node_viewport and new_scene:
			if gui:
				_node_viewport.remove_child(gui)
				gui.queue_free()
			gui = gui_scene.instantiate()
			_node_viewport.add_child(gui)
	get():
		return gui_scene

## Size of GUI screen from 3D world point of view.
@export var screen_size_3d := Vector2(1, 1) :
	set(new_size):
		screen_size_3d = new_size
		if _node_collision:
			_node_quad.mesh.size = screen_size_3d
			_node_collision.shape.size.x = screen_size_3d.x
			_node_collision.shape.size.y = screen_size_3d.y
	get():
		return screen_size_3d

## Size of GUI screen from GUI elements point of view.
@export var screen_size_2d := Vector2(512, 512) :
	set(new_size):
		screen_size_2d = new_size
		if _node_viewport:
			_node_viewport.size = screen_size_2d
	get():
		return screen_size_2d

## Billboard mode for GUI screen.
## (this is not real / material base bilbord but custom Gui3DNode implementation)
@export var billboard_mode : BaseMaterial3D.BillboardMode :
	set(new_mode):
		billboard_mode = new_mode
		if billboard_mode != BaseMaterial3D.BillboardMode.BILLBOARD_DISABLED:
			# run billboard specific code only if billboard mode is set
			set_process(true)
		else:
			set_process(false)
	get():
		return billboard_mode

## Auto realase focus while mouse exited area
@export var release_focus := true

## shortcut to GUI root node
var gui : Node = null

# emited when mouse enter/exit area
signal mouse_inside(mouse_inside: bool)

# emited on focus changes (when release_focus == false also on mouse enter/exit area)
signal focus_inside(focus: bool, mouse_inside: bool, from_mouse: bool)

@onready var _node_viewport: SubViewport = $SubViewport
@onready var _node_quad: MeshInstance3D = $Quad
@onready var _node_area: Area3D = $Quad/Area3D
@onready var _node_collision: CollisionShape3D = $Quad/Area3D/CollisionShape3D

func _ready() -> void:
	# call setters
	screen_size_3d = screen_size_3d
	screen_size_2d = screen_size_2d
	billboard_mode = billboard_mode
	# create gui scene after set view port size (screen_size_2d)
	gui_scene = gui_scene
	
	# update viewport_path in viewport material (needed if Gui3DNode is used with "Editable Children" option)
	_node_quad.get_surface_override_material(0).albedo_texture.viewport_path = _node_viewport.get_path()
	
	# connect input signals from Area3D
	_node_area.mouse_entered.connect(_mouse_entered_area)
	_node_area.mouse_exited.connect(_mouse_exited_area)
	_node_area.input_event.connect(_mouse_input_event)
	
	_node_viewport.gui_focus_changed.connect(_on_gui_focus_changed)

func _process(_delta: float) -> void:
	_rotate_as_billboard()


## Used for checking if the mouse is inside the Area3D.
var _is_mouse_inside := false

## The last processed input touch/mouse event. Used to calculate relative movement.
var _last_event_pos2D := Vector2()

## The time of the last event in seconds since engine start.
var _last_event_time := -1.0

func _mouse_entered_area() -> void:
	_is_mouse_inside = true
	# Notify the viewport that the mouse is now hovering it.
	_node_viewport.notification(NOTIFICATION_VP_MOUSE_ENTER)
	mouse_inside.emit(true)
	if not release_focus:
		focus_inside.emit(len(_focus_owners) != 0, _is_mouse_inside, true)

func _mouse_exited_area() -> void:
	# Notify the viewport that the mouse is no longer hovering it.
	_node_viewport.notification(NOTIFICATION_VP_MOUSE_EXIT)
	_is_mouse_inside = false
	mouse_inside.emit(false)
	if release_focus:
		for n in _focus_owners:
			n.release_focus()
	else:
		focus_inside.emit(len(_focus_owners) != 0, _is_mouse_inside, true)

func _unhandled_input(input_event: InputEvent) -> void:
	# Check if the event is a non-mouse/non-touch event
	for mouse_event in [InputEventMouseButton, InputEventMouseMotion, InputEventScreenDrag, InputEventScreenTouch]:
		if is_instance_of(input_event, mouse_event):
			# If the event is a mouse/touch event, then we can ignore it here, because it will be
			# handled via Physics Picking.
			return
	_node_viewport.push_input(input_event)

func _mouse_input_event(_camera: Camera3D, input_event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# Get mesh size to detect edges and make conversions. This code only supports PlaneMesh and QuadMesh.
	var quad_mesh_size: Vector2 = _node_quad.mesh.size

	# Event position in Area3D in world coordinate space.
	var event_pos3D := event_position

	# Current time in seconds since engine start.
	var now := Time.get_ticks_msec() / 1000.0

	# Convert position to a coordinate space relative to the Area3D node.
	# NOTE: `affine_inverse()` accounts for the Area3D node's scale, rotation, and position in the scene!
	event_pos3D = _node_quad.global_transform.affine_inverse() * event_pos3D

	var event_pos2D := Vector2()

	if _is_mouse_inside:
		# Convert the relative event position from 3D to 2D.
		event_pos2D = Vector2(event_pos3D.x, -event_pos3D.y)

		# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
		# We need to convert it into the following range: -0.5 -> 0.5
		event_pos2D.x = event_pos2D.x / quad_mesh_size.x
		event_pos2D.y = event_pos2D.y / quad_mesh_size.y
		# Then we need to convert it into the following range: 0 -> 1
		event_pos2D.x += 0.5
		event_pos2D.y += 0.5

		# Finally, we convert the position to the following range: 0 -> viewport.size
		event_pos2D.x *= _node_viewport.size.x
		event_pos2D.y *= _node_viewport.size.y
		# We need to do these conversions so the event's position is in the viewport's coordinate system.

	elif _last_event_pos2D != null:
		# Fall back to the last known event position.
		event_pos2D = _last_event_pos2D

	# Set the event's position and global position.
	input_event.position = event_pos2D
	if input_event is InputEventMouse:
		input_event.global_position = event_pos2D

	# Calculate the relative event distance.
	if input_event is InputEventMouseMotion or input_event is InputEventScreenDrag:
		# If there is not a stored previous position, then we'll assume there is no relative motion.
		if _last_event_pos2D == null:
			input_event.relative = Vector2(0, 0)
		# If there is a stored previous position, then we'll calculate the relative position by subtracting
		# the previous position from the new position. This will give us the distance the event traveled from prev_pos.
		else:
			input_event.relative = event_pos2D - _last_event_pos2D
			input_event.velocity = input_event.relative / (now - _last_event_time)

	# Update _last_event_pos2D with the position we just calculated.
	_last_event_pos2D = event_pos2D

	# Update _last_event_time to current time.
	_last_event_time = now

	# Finally, send the processed input event to the viewport.
	_node_viewport.push_input(input_event)

func _rotate_as_billboard() -> void:
	# custom billboard implementation - needed for rotate physics (collision) node,
	# but also apply to mesh node (instead of using billboard material) to keep it in sync with collision shape

	# Get the camera.
	var camera := get_viewport().get_camera_3d()
	# Look in the same direction as the camera.
	var look := camera.to_global(Vector3(0, 0, -100)) - camera.global_transform.origin
	look = _node_quad.position + look

	# Y-Billboard: Lock Y rotation, but gives bad results if the camera is tilted.
	if billboard_mode == 2:
		look = Vector3(look.x, 0, look.z)

	_node_quad.look_at(look, Vector3.UP)

	# Rotate in the Z axis to compensate camera tilt.
	_node_quad.rotate_object_local(Vector3.BACK, camera.rotation.z)

var _focus_owners = []

func _on_gui_focus_exited(node: Control) -> void:
	_focus_owners.erase(node)
	if len(_focus_owners) == 0:
		focus_inside.emit(false, _is_mouse_inside, false)
	
func _on_gui_focus_changed(node: Control) -> void:
	_focus_owners.append(node)
	node.focus_exited.connect(_on_gui_focus_exited.bind(node), CONNECT_ONE_SHOT)
	focus_inside.emit(true, _is_mouse_inside, false)
