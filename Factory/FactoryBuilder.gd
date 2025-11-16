# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node3D

@export_group("Factory Blocks List")

@export var elements: Array[PackedScene] = []

@export_group("Factory Basic Settings")

@export var factory_control : Node
@export var factory_blocks_main_node : Node3D
@export var defualt_computer_system_id = 0

@export_group("Factory World Size Settings")

@export var grid_size := Vector3(1, 1, 1)
@export var ray_length := 300
@export var attachable_objects_collision_mask := 0xffffffff
@export var blocking_space_objects_collision_mask := 0xffffffff
@export var mouse_y_distance_per_scale_step := 30

signal on_block_add(block: Node3D)
signal on_block_remove(block: Node3D)

@onready var undo_redo := UndoRedo.new()
@onready var ui := %WorldEditorUI
@onready var camera := %Camera3D
@onready var _viewport := camera.get_viewport()

### if true allow interact with static block (like producer, consumer and world elements)
@onready var developer_mode := false


### Save / Restore

func serialise() -> Array:
	var save_data = []
	for node in factory_blocks_main_node.get_children():
		if node == _new_element:
			continue
		var node_data = {
			"type": node.get_child(0).object_subtype,
			"position": node.position,
			"rotation": node.rotation,
			"scale": node.scale,
		}
		if node.has_meta("in_game_name"):
			node_data["in_game_name"] = node.get_meta("in_game_name")
		if node.has_meta("using_computer_id"):
			node_data["using_computer_id"] = node.get_meta("using_computer_id")
		
		save_data.append(node_data)
	return save_data

func restore(data : Array) -> void:
	for node_info in data:
		var packed_scene = ui._elements_dict[node_info.type][0]
		
		var node = packed_scene.instantiate()
		node.position = FAG_Utils.Vector3_from_JSON(node_info.position)
		node.rotation = FAG_Utils.Vector3_from_JSON(node_info.rotation)
		node.scale = FAG_Utils.Vector3_from_JSON(node_info.scale)
		if "in_game_name" in node_info:
			node.set_meta("in_game_name", node_info.in_game_name)
		if "using_computer_id" in node_info:
			node.set_meta("using_computer_id", int(node_info.using_computer_id)) # TODO this causes incompatibility with non integer computer ids
		
		factory_blocks_main_node.add_child(node)
		node.owner = factory_blocks_main_node
		
		_on_block_add(node)

func save_tscn(save_file : String) -> bool:
	var scene = PackedScene.new()
	var result = scene.pack(factory_blocks_main_node)
	if result == OK:
		result = ResourceSaver.save(scene, save_file)
		if result == OK:
			print("Factory blocks saved successfully")
			return true
	return false

func restore_tscn(save_file : String) -> void:
	var saved_data = load(save_file).instantiate()

	for n in saved_data.get_children():
		var node = n.duplicate()
		factory_blocks_main_node.add_child(node)
		node.owner = factory_blocks_main_node
		_on_block_add(node)
	
	saved_data.free() # this delete all child of saved_data also
	# (https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#memory-management)

func close() -> void:
	ui.reset_editor()
	_moving_elements.clear()
	_scaled_element = null
	_intersection = null
	_remove_subnodes(factory_blocks_main_node)

func _remove_subnodes(destination : Node3D) -> void:
	for n in destination.get_children():
		destination.remove_child(n)
		n.queue_free()


### Block add / remove callbacks

func _on_block_add(element : Node3D) -> void:
	var info_obj = get_info_from_block(element)
	if "object_subtype" in info_obj and info_obj.object_subtype == "ComputerControlBlock":
		factory_control.setup_computer_control_blocks(element)
	elif "factory_signals" in info_obj:
		factory_control.register_factory_signals(
			info_obj.factory_signals[0],
			info_obj.factory_signals[1],
			info_obj.factory_signals[2],
			element.get_meta("in_game_name", ""),
			element.get_meta("using_computer_id", defualt_computer_system_id),
		)
	on_block_add.emit(element)

func _on_block_remove(element : Node3D) -> void:
	var info_obj = get_info_from_block(element)
	if "object_subtype" in info_obj and info_obj.object_subtype == "ComputerControlBlock":
		factory_control.remove_computer_control_blocks(element)
	elif "factory_signals" in info_obj:
		factory_control.unregister_factory_signals(
			info_obj.factory_signals[0],
			info_obj.factory_signals[1],
			info_obj.factory_signals[2],
			element.get_meta("in_game_name", ""),
			element.get_meta("using_computer_id", defualt_computer_system_id),
		)
	on_block_remove.emit(element)



### 3D world raycast

var _intersection = null
var _intersection_grid_position : Vector3
var _intersection_need_update = true

@onready var neighbors_sphere = _create_collision_sphere()

func _create_collision_sphere():
	var shape_rid = PhysicsServer3D.sphere_shape_create()
	var radius = 2 * grid_size.length()
	PhysicsServer3D.shape_set_data(shape_rid, radius)
	return shape_rid

func _process(_delta) -> void:
	if _intersection_need_update:
		var point = _viewport.get_mouse_position()
		var ray_start = camera.project_ray_origin(point)
		var ray_end = ray_start + camera.project_ray_normal(point) * ray_length
		var exclude = []
		if _new_element:
			exclude.append_array(_new_element.get_child(0).physics_rids)
		for element in _moving_elements:
			exclude.append_array(element.get_child(0).physics_rids)
		var ray_query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, attachable_objects_collision_mask, exclude)
		_intersection = get_world_3d().direct_space_state.intersect_ray(ray_query)
		
		if _intersection:
			# calculate new value of _intersection_grid_position
			var new__intersection_grid_position = _intersection.position.snapped(grid_size)
			if _intersection.normal.x < 0:
				new__intersection_grid_position.x -= grid_size.x
			if _intersection.normal.y < 0:
				new__intersection_grid_position.y -= grid_size.y
			if _intersection.normal.z < 0:
				new__intersection_grid_position.z -= grid_size.z
			
			# check if this grid position is free
			var sphere_query := PhysicsShapeQueryParameters3D.new()
			sphere_query.shape_rid = neighbors_sphere
			sphere_query.collision_mask = blocking_space_objects_collision_mask
			sphere_query.exclude = exclude
			sphere_query.motion = new__intersection_grid_position
			var neighbors = get_world_3d().direct_space_state.intersect_shape(sphere_query)
			
			var it_is_free_grid_position = true
			for neighbor in neighbors:
				if new__intersection_grid_position.is_equal_approx( get_block_from_collider(neighbor.collider).global_position ):
					it_is_free_grid_position = false
					break
			
			# update _intersection_grid_position if it's free grid position
			if it_is_free_grid_position:
				_intersection_grid_position = new__intersection_grid_position
		_intersection_need_update = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_intersection_need_update = true


### UI callbacks

var _new_element : Node3D = null
var _new_element_scene : PackedScene = null
var _moving_elements := {}
var _scaled_element : Node3D = null
var _scaled_side
var _operation_init_point2D : Vector2
var _initial_scale : Vector3
var _initial_position : Vector3

func _on_active_ui_tool_changed(mode: int, _button_name: String, element: PackedScene) -> void:
	if not ui:
		return
	
	if _new_element:
		factory_blocks_main_node.remove_child(_new_element)
		_new_element.queue_free()
		_new_element = null
	
	if mode == ui.ELEMENT:
		_new_element_scene = element
		_new_element = _new_element_scene.instantiate()
		factory_blocks_main_node.add_child(_new_element)
		_on_element_add__update()

func _on_element_add__update(_point = null) -> void:
	_new_element.position = _intersection_grid_position

func _on_element_add__finish(_point = null) -> void:
	if _intersection:
		_on_element_add__update()
		var info_obj = get_info_from_block(_new_element)
		if "factory_signals" in info_obj:
			ui.input_allowed = false
			camera.disable_input()
			%GetNameInput.text = ""
			%GetNameDialog.show()
			%GetNameInput.grab_focus()
		else:
			_add_element()

func _on_get_name_ok() -> void:
	_add_element(%GetNameInput.text.to_lower())
	ui.input_allowed = true
	camera.enable_input()
	%GetNameDialog.hide()

func _on_get_name_cancel() -> void:
	ui.input_allowed = true
	camera.enable_input()
	%GetNameDialog.hide()

func _add_element(block_name := "") -> void:
		var element = _new_element_scene.instantiate()
		element.position = _new_element.position
		element.rotation = _new_element.rotation
		if block_name:
			element.set_meta("in_game_name", block_name)
		undo_redo.create_action("3DWorld Element: Add")
		undo_redo.add_do_reference(element)
		undo_redo.add_do_method(factory_blocks_main_node.add_child.bind(element))
		undo_redo.add_do_method(_on_block_add.bind(element))
		undo_redo.add_undo_method(factory_blocks_main_node.remove_child.bind(element))
		undo_redo.add_undo_method(_on_block_remove.bind(element))
		undo_redo.add_do_method(_on_element_transform_update.bind(element))
		undo_redo.add_undo_method(_on_element_transform_update.bind(element))
		undo_redo.commit_action()
		element.owner = factory_blocks_main_node

func _on_do_on_raycast_result(_mode: int, point: Vector2, raycast_result: Variant) -> void:
	match ui.get_active_ui_tool_mode():
		ui.SELECT:
			_moving_elements[raycast_result] = raycast_result.position
		ui.SCALE_IN_PROGRESS:
			var info_obj = get_info_from_block(raycast_result)
			if "object_subtype" in info_obj and info_obj.object_subtype == "ConveyorBelt":
				var rotated_normal = Quaternion.from_euler(raycast_result.global_rotation) * _intersection.normal
				if not is_zero_approx(rotated_normal.x):
					_scaled_element = raycast_result
					_operation_init_point2D = point
					_initial_scale = raycast_result.scale
					_initial_position = raycast_result.position
					if rotated_normal.x > 0:
						_scaled_side = 1
					else:
						_scaled_side = -1
		ui.DELETE:
			undo_redo.create_action("3DWorld Element: Remove")
			undo_redo.add_do_method(factory_blocks_main_node.remove_child.bind(raycast_result))
			undo_redo.add_do_method(_on_block_remove.bind(raycast_result))
			undo_redo.add_undo_reference(raycast_result)
			undo_redo.add_undo_method(factory_blocks_main_node.add_child.bind(raycast_result))
			undo_redo.add_undo_method(_on_block_add.bind(raycast_result))
			undo_redo.commit_action()
		ui.ROTATE:
			undo_redo.create_action("3DWorld Element: Rotate")
			undo_redo.add_do_method(raycast_result.rotate.bind(Vector3.UP, PI/2))
			undo_redo.add_undo_reference(raycast_result)
			undo_redo.add_undo_method(raycast_result.rotate.bind(Vector3.UP, -PI/2))
			if roundi(raycast_result.scale.x) % 2 == 0:
				undo_redo.add_undo_property(raycast_result, "position", raycast_result.position)
				raycast_result.position.x -= grid_size.x/2
				raycast_result.position.z += grid_size.z/2
				undo_redo.add_do_property(raycast_result, "position", raycast_result.position)
			undo_redo.add_do_method(_on_element_transform_update.bind(raycast_result))
			undo_redo.add_undo_method(_on_element_transform_update.bind(raycast_result))
			undo_redo.commit_action()
		ui.MIRROR:
			undo_redo.create_action("3DWorld Element: Mirror")
			undo_redo.add_undo_property(raycast_result, "scale", raycast_result.scale)
			raycast_result.scale.z = -raycast_result.scale.z
			undo_redo.add_do_property(raycast_result, "scale", raycast_result.scale)
			undo_redo.add_do_method(_on_element_transform_update.bind(raycast_result))
			undo_redo.add_undo_method(_on_element_transform_update.bind(raycast_result))
			undo_redo.commit_action()

func _on_do_move_step(_point) -> void:
	for element in _moving_elements:
		element.position = _intersection_grid_position

func _on_do_move_finish() -> void:
	if not _moving_elements:
		return
	
	# check (on first element if was moved)
	var first_element = _moving_elements.keys()[0]
	if first_element.position != _moving_elements[first_element]:
		# create common undo_redo action for all elements
		undo_redo.create_action("3DWorld Element: Move")
		for element in _moving_elements:
			undo_redo.add_do_property(element, "position", element.position)
			undo_redo.add_undo_property(element, "position", _moving_elements[element])
			undo_redo.add_do_method(_on_element_transform_update.bind(element))
			undo_redo.add_undo_method(_on_element_transform_update.bind(element))
		undo_redo.commit_action()
	_moving_elements.clear()

func _on_do_on_raycast_selection_finish(raycast_result: Variant) -> void:
	if raycast_result: #  <=>  if "on_click" event:
		var info_obj = get_info_from_block(raycast_result)
		if "object_subtype" in info_obj:
			if info_obj.object_subtype == "ElectronicControlBlock":
				FAG_WindowManager.set_windows_visibility_recursive(factory_control.circuit_simulator_window, true)
			elif info_obj.object_subtype == "ComputerControlBlock":
				var computer_id = raycast_result.get_meta("computer_id")
				FAG_WindowManager.set_windows_visibility_recursive(factory_control.computer_control_blocks[computer_id], true)
	_moving_elements.clear()

func _on_do_scale_step(point: Vector2) -> void:
	if _intersection and _scaled_element:
		var distance = (_operation_init_point2D - point).y
		var decrease_increase = 0
		if distance < -mouse_y_distance_per_scale_step:
			decrease_increase = 1
		elif distance > mouse_y_distance_per_scale_step and _scaled_element.scale.x > 1:
			decrease_increase = -1
		if decrease_increase:
			_scaled_element.scale.x += decrease_increase
			var element_rotation = abs(_scaled_element.rotation.y)
			if 1 < element_rotation and element_rotation < 2: # about +/- pi/2
				_scaled_element.position.z += decrease_increase * _scaled_side * grid_size.z/2
			else:
				_scaled_element.position.x += decrease_increase * _scaled_side * grid_size.x/2
			_operation_init_point2D = point

func _on_do_scale_finish() -> void:
	if _scaled_element:
		undo_redo.create_action("3DWorld Element: Scale")
		undo_redo.add_do_property(_scaled_element, "scale", _scaled_element.scale)
		undo_redo.add_do_property(_scaled_element, "position", _scaled_element.position)
		undo_redo.add_undo_property(_scaled_element, "scale", _initial_scale)
		undo_redo.add_undo_property(_scaled_element, "position", _initial_position)
		undo_redo.commit_action()
		_scaled_element = null

func _on_ui_focus_lost() -> void:
	_intersection = null
	# NOTE: do NOT set `_intersection_need_update = true` here
	# to avoid update _intersection before update mouse position after get focus again


### Input handle

func _input(event: InputEvent) -> void:
	if not ui.input_allowed:
		return
	# override UI buttons shortcuts in some situations
	if event.is_action_pressed("EDIT_ROTATE", false, true) and ui.get_active_ui_tool_mode() == ui.ELEMENT:
		_new_element.rotate(Vector3.UP, -PI/2)
		get_viewport().set_input_as_handled()

func _on_mouse_enter_exit_gui_area(enter: bool) -> void:
	camera.use_mouse_control = not enter


### Init - configure UI, etc

func _ready() -> void:
	ui.do_raycast = _get_block_from_raycast.bind()
	ui.undo.connect(undo_redo.undo)
	ui.redo.connect(undo_redo.redo)
	
	for element in elements:
		ui.add_element(element)

func _get_block_from_raycast(_point):
	if _intersection:
		var block := get_block_from_collider(_intersection.collider)
		var info_obj = get_info_from_block(block)
		if "object_type" in info_obj and (
			info_obj.object_type == "FactoryBlock" or
			(developer_mode and info_obj.object_type == "FactoryStaticBlock")
		):
			return block
	return null

func set_visibility(value : bool) -> void:
	visible = value
	ui.call_deferred("set_visibility", value)


### Utils

func _on_element_transform_update(element):
	if element.get_child(0).has_method("on_transform_update"):
		element.get_child(0).on_transform_update()

static func get_block_from_collider(element : PhysicsBody3D) -> Node3D:
	return element.get_parent()
	
static func get_info_from_block(element: Node3D) -> Variant:
	return element.get_child(0)
