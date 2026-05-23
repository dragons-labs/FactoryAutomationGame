# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node3D

@export_group("Factory Blocks List")

@export var elements: Array[PackedScene] = []

@export_group("Factory Basic Settings")

@export var factory_control : Node
@export var factory_root : Node
@export var factory_blocks_main_node : Node3D
@export_group("Factory World Size Settings")

@export var grid_size := Vector3(1, 1, 1)
@export var ray_length := 300
@export var attachable_objects_collision_mask := 0xfffffff0
@export var blocking_space_objects_collision_mask := 0xfffffff0
@export var mouse_y_distance_per_scale_step := 30

signal on_block_add(block: Node3D)
signal on_block_remove(block: Node3D)

@onready var undo_redo := UndoRedo.new()
@onready var ui := %WorldEditorUI
@onready var camera := %Camera3D
@onready var _viewport := camera.get_viewport()


#region save / restore and close

func serialise() -> Array:
	var save_data = []
	for node in factory_blocks_main_node.get_children():
		if node == _new_element:
			continue
		var node_data = {
			"type": node.object_type,
			"position": node.position,
			"rotation": node.rotation,
			"scale": node.scale,
		}
		if node.get_block_control():
			node_data["block_name"] = node.get_block_control().get_block_name()
		if node.has_meta("block_config"):
			node_data["block_config"] = node.get_meta("block_config")
		
		save_data.append(node_data)
	return save_data

func restore(data : Array) -> void:
	for node_info in data:
		var packed_scene = ui._elements_dict[node_info.type][0]
		
		var node = packed_scene.instantiate()
		node.position = node_info.position
		node.rotation = node_info.rotation
		node.scale = node_info.scale
		if "block_config" in node_info:
			node.set_meta("block_config", node_info.block_config)
		
		factory_blocks_main_node.add_child(node)
		node.owner = factory_blocks_main_node
		
		_on_block_add(node, node_info.get("block_name", null))

func close() -> void:
	ui.reset_editor()
	camera.restore_defaults()
	_selected_elements.clear()
	_scaled_element = null
	_intersection = null
	_moving_in_progress = false
	for child in factory_blocks_main_node.get_children():
		factory_blocks_main_node.remove_child(child)
		child.queue_free()

#endregion

#region Block add / remove callbacks

func _on_block_add(element : Node3D, block_name = null) -> void:
	if "object_type" in element and element.object_type == "ComputerControlBlock":
		factory_control.setup_computer_control_blocks(element)
	elif "init" in element:
		element.init(factory_root, block_name)
	on_block_add.emit(element)

func _on_block_remove(element : Node3D) -> void:
	if "object_type" in element and element.object_type == "ComputerControlBlock":
		factory_control.remove_computer_control_blocks(element)
	elif "deinit" in element:
		element.deinit()
	on_block_remove.emit(element)

#endregion

#region 3D world raycast

var _intersection = null
var _intersection_point = Vector2(0,0)
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
		_intersection_point = _viewport.get_mouse_position()
		var ray_start = camera.project_ray_origin(_intersection_point)
		var ray_end = ray_start + camera.project_ray_normal(_intersection_point) * ray_length
		var exclude = []
		if _new_element:
			exclude.append_array(_new_element.get_physics_rids())
		if _moving_in_progress:
			for element in _selected_elements:
				exclude.append_array(element.get_physics_rids())
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
				if neighbor is not FAG_FactoryBlock:
					continue
				if new__intersection_grid_position.is_equal_approx( get_block_from_collider(neighbor.collider).global_position ):
					it_is_free_grid_position = false
					break
			
			# update _intersection_grid_position if it's free grid position
			if it_is_free_grid_position:
				_intersection_grid_position = new__intersection_grid_position
		_intersection_need_update = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse and not _block_3d_operation:
		_intersection_need_update = true

# while true temporary block 3d world raycasting
var _block_3d_operation := false

var _previous_ui_input_state

func disable_input() -> void:
	if _block_3d_operation:
		return
	_block_3d_operation = true
	_previous_ui_input_state = ui.input_allowed
	ui.input_allowed = false
	ui.process_mode = PROCESS_MODE_DISABLED
	ui.update_cursor(false, true)
	camera.disable_input()

func enable_input(force := false) -> void:
	camera.enable_input()
	ui.update_cursor(true, true)
	ui.process_mode = PROCESS_MODE_INHERIT
	ui.input_allowed = _previous_ui_input_state or force
	_block_3d_operation = false

#endregion

#region blocks selection

var _selected_elements := {}
@onready var _selection_material : Material = load("res://Factory/selection.material.tres")

func _select_block(block : FAG_FactoryBlock) -> void:
	for mesh in block.find_children("*", "MeshInstance3D"):
		mesh.material_overlay = _selection_material
	_selected_elements[block] = block.position

func _unselect_block(block : FAG_FactoryBlock, full := true) -> void:
	for mesh in block.find_children("*", "MeshInstance3D"):
		mesh.material_overlay = null
	if full:
		_selected_elements.erase(block)

func _unselect_all_blocks() -> void:
	for block in _selected_elements:
		_unselect_block(block, false)
	_selected_elements.clear()

#endregion

#region block config UI

var _last_ui_block = null

func _update_block_ui() -> void:
	# get factory block if only one block is selected
	var block = _selected_elements.keys()[0] if len(_selected_elements) == 1 else null
	
	# deattach block UI on block change
	if _last_ui_block and block != _last_ui_block:
		_last_ui_block.show_block_ui(null)
		_last_ui_block = null
	
	# hide menu on no block
	if not block:
		%BlockConfig.hide()
		return
	
	var block_config_visible = false
	
	# show block UI if available
	if "_gui" in block:
		%BlockUI.show()
		_last_ui_block = block
		_last_ui_block.show_block_ui(%BlockUI/BlockUI)
		block_config_visible = true
	else:
		%BlockUI.hide()
	
	# show block name if available
	if block.get_block_control():
		%NameUI.show()
		%NameUI/Block/Name.text = block.get_block_control().get_block_name()
		block_config_visible = true
	else:
		%NameUI.hide()
	
	# show menu if any content is shown
	%BlockConfig.visible = block_config_visible
	
	# set block info if menu is visible
	if block_config_visible:
		%InfoUI/TypeName.text = tr(block.ui_name)
		if block.ui_desc:
			%InfoUI.tooltip_text = tr(block.ui_desc)
		%InfoUI/TypeIcon.texture = block.ui_icon

func _on_block_name_change_ok_button() -> void:
	var block = _selected_elements.keys()[0] if len(_selected_elements) == 1 else null
	_rename_element(%NameUI/Block/Name.text, block)

#endregion

#region Rotate / Mirror / Delete blocks

func rotate_blocks(blocks : Variant, pivot = null, angle := PI/2, no_undo = false) -> void:
	var local_undo_redo : UndoRedo = UndoRedo.new() if no_undo else undo_redo
	
	local_undo_redo.create_action("3DWorld Element: Rotate")
	for block in blocks:
		local_undo_redo.add_do_method(block.rotate.bind(Vector3.UP, angle))
		local_undo_redo.add_undo_method(block.rotate.bind(Vector3.UP, -angle))
		local_undo_redo.add_undo_property(block, "position", block.position)
		if pivot != null:
			block.position = FAG_Utils.rotate_around_pivot_3D(block.position, pivot, angle).snapped(grid_size)
		if roundi(block.scale.x) % 2 == 0:
			block.position.x -= grid_size.x/2
			block.position.z += grid_size.z/2
		local_undo_redo.add_do_property(block, "position", block.position)
		local_undo_redo.add_do_method(_on_element_transform_update.bind(block))
		local_undo_redo.add_undo_method(_on_element_transform_update.bind(block))
	local_undo_redo.commit_action()
	
	if no_undo:
		local_undo_redo.free()

func mirror_blocks(blocks : Variant, pivot = null, no_undo = false) -> void:
	var local_undo_redo : UndoRedo = UndoRedo.new() if no_undo else undo_redo
	
	local_undo_redo.create_action("3DWorld Element: Mirror")
	for block in blocks:
		local_undo_redo.add_undo_property(block, "scale", block.scale)
		block.scale.z = -block.scale.z
		local_undo_redo.add_do_property(block, "scale", block.scale)
		if pivot != null:
			block.rotation.y = wrapf(block.rotation.y, -PI, PI)
			var abs_rotation = abs(block.rotation.y)
			if 1.5 < abs_rotation and abs_rotation < 1.6:
				local_undo_redo.add_undo_property(block, "rotation", block.rotation)
				block.rotation.y = -block.rotation.y
				local_undo_redo.add_do_property(block, "rotation", block.rotation)
			local_undo_redo.add_undo_property(block, "position", block.position)
			block.position = FAG_Utils.mirror_z(block.position, pivot)
			local_undo_redo.add_do_property(block, "position", block.position)
		local_undo_redo.add_do_method(_on_element_transform_update.bind(block))
		local_undo_redo.add_undo_method(_on_element_transform_update.bind(block))
	local_undo_redo.commit_action()
	
	if no_undo:
		local_undo_redo.free()

func remove_blocks(blocks : Variant) -> void:
	undo_redo.create_action("3DWorld Element: Remove")
	for block in blocks:
		undo_redo.add_do_method(factory_blocks_main_node.remove_child.bind(block))
		undo_redo.add_do_method(_on_block_remove.bind(block))
		undo_redo.add_undo_reference(block)
		undo_redo.add_undo_method(factory_blocks_main_node.add_child.bind(block))
		undo_redo.add_undo_method(_on_block_add.bind(block))
	undo_redo.commit_action()

#endregion

#region UI callbacks

var _new_element : Node3D = null
var _new_element_scene : PackedScene = null
var _scaled_element : Node3D = null
var _scaled_side
var _operation_init_point2D : Vector2
var _initial_scale : Vector3
var _initial_position : Vector3

func _on_active_ui_tool_changed(mode: int, element: PackedScene) -> void:
	if not ui:
		return
	
	if _new_element:
		factory_blocks_main_node.remove_child(_new_element)
		_new_element.queue_free()
		_new_element = null
	
	if mode == ui.ELEMENT and element:
		_new_element_scene = element
		_new_element = _new_element_scene.instantiate()
		factory_blocks_main_node.add_child(_new_element)
		_on_element_add__update()

func _on_element_add__update(_point = null) -> void:
	_new_element.position = _intersection_grid_position

func _on_element_add__finish(_point = null) -> void:
	if _intersection:
		_on_element_add__update()
		if _new_element.get_block_control():
			_show_name_dialog(_add_element)
		else:
			_add_element()

var _show_name_dialog_cllback = null

func _show_name_dialog(callback, block_name := ""):
	_show_name_dialog_cllback = callback
	ui.input_allowed = false
	camera.disable_input()
	%GetNameInput.text = block_name
	%GetNameDialog.show()
	%GetNameInput.grab_focus()

func _on_get_name_ok() -> void:
	_show_name_dialog_cllback.call(%GetNameInput.text.to_lower())
	_show_name_dialog_cllback = null
	ui.input_allowed = true
	camera.enable_input()
	%GetNameDialog.hide()

func _on_get_name_cancel() -> void:
	ui.input_allowed = true
	camera.enable_input()
	%GetNameDialog.hide()

func _add_element(block_name = null) -> void:
		var element = _new_element_scene.instantiate()
		element.position = _new_element.position
		element.rotation = _new_element.rotation
		undo_redo.create_action("3DWorld Element: Add")
		undo_redo.add_do_reference(element)
		undo_redo.add_do_method(factory_blocks_main_node.add_child.bind(element))
		undo_redo.add_do_method(_on_block_add.bind(element, block_name))
		undo_redo.add_undo_method(factory_blocks_main_node.remove_child.bind(element))
		undo_redo.add_undo_method(_on_block_remove.bind(element))
		undo_redo.commit_action()
		element.owner = factory_blocks_main_node

func _rename_element(block_name, element):
	element.get_block_control().set_block_name(block_name)

func _on_do_on_raycast_result(_mode: int, point: Vector2, raycast_result: Variant, multi_select : bool) -> void:
	if not raycast_result:
		_unselect_all_blocks()
		_update_block_ui()
		return
	
	match ui.active_ui_tool:
		ui.SELECT:
			if raycast_result in _selected_elements:
				if multi_select:
					_unselect_block(raycast_result)
			else:
				if not multi_select:
					_unselect_all_blocks()
				_select_block(raycast_result)
			_move_init_element = raycast_result
		ui.SCALE_IN_PROGRESS:
			if "object_type" in raycast_result and raycast_result.object_type == "ConveyorBelt":
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
			_unselect_block(raycast_result)
			remove_blocks([raycast_result])
		ui.ROTATE:
			_unselect_block(raycast_result)
			rotate_blocks([raycast_result])
		ui.MIRROR:
			_unselect_block(raycast_result)
			mirror_blocks([raycast_result])
		ui.RENAME:
			if raycast_result.get_block_control():
				_show_name_dialog(_rename_element.bind(raycast_result), raycast_result.get_block_control().get_block_name())
	
	_update_block_ui()

var _moving_in_progress := false
var _move_init_element

func _on_do_move_step(_point) -> void:
	_moving_in_progress = true
	var offset = _intersection_grid_position - _move_init_element.position + grid_size * 0.01
	for element in _selected_elements:
		element.position += offset.round()
		# uses round offset is need for scaled element with scale % 2 == 0
		# `+ grid_size * 0.01` to avoid object jumping/flickering

func _on_do_move_finish() -> void:
	if not _selected_elements:
		return
	
	# check (on first element if was moved)
	var first_element = _selected_elements.keys()[0]
	if first_element.position != _selected_elements[first_element]:
		# create common undo_redo action for all elements
		undo_redo.create_action("3DWorld Element: Move")
		for element in _selected_elements:
			undo_redo.add_do_property(element, "position", element.position)
			undo_redo.add_undo_property(element, "position", _selected_elements[element])
			undo_redo.add_do_method(_on_element_transform_update.bind(element))
			undo_redo.add_undo_method(_on_element_transform_update.bind(element))
		undo_redo.commit_action()
	
	_moving_in_progress = false

func _on_do_on_raycast_selection_finish(raycast_result: Variant, _multi_select_add : bool, _multi_select_rem : bool, _selection_box : Variant) -> void:
	if raycast_result: #  <=>  if "on_click" event:
		if "object_type" in raycast_result:
			if raycast_result.object_type == "ElectronicControlBlock":
				FAG_WindowManager.set_windows_visibility_recursive(factory_control.circuit_simulator_window, true)
			elif raycast_result.object_type == "ComputerControlBlock":
				var computer_id = raycast_result.get_meta("computer_id")
				FAG_WindowManager.set_windows_visibility_recursive(factory_control.computer_control_blocks[computer_id], true)

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

#endregion

#region Input handle

func _input(event: InputEvent) -> void:
	if not ui.input_allowed:
		return
	# override UI buttons shortcuts in some situations
	var mode = ui.active_ui_tool
	if FAG_Utils.action_exact_match_pressed("EDIT_ROTATE", event):
		if mode == ui.ELEMENT:
			_new_element.rotate(Vector3.UP, -PI/2)
			get_viewport().set_input_as_handled()
		elif mode == ui.SELECT and len(_selected_elements) > 0:
			rotate_blocks(_selected_elements, _intersection.position)
			get_viewport().set_input_as_handled()
	elif FAG_Utils.action_exact_match_pressed("EDIT_MIRROR", event):
		if mode == ui.ELEMENT:
			_new_element.scale.z = -_new_element.scale.z
			get_viewport().set_input_as_handled()
		elif mode == ui.SELECT and len(_selected_elements) > 0:
			mirror_blocks(_selected_elements, _intersection.position)
			get_viewport().set_input_as_handled()
	elif FAG_Utils.action_exact_match_pressed("EDIT_DELETE", event):
		if mode == ui.SELECT and len(_selected_elements) > 0:
			remove_blocks(_selected_elements)
			get_viewport().set_input_as_handled()

func _on_mouse_enter_exit_gui_area(enter: bool) -> void:
	camera.use_mouse_control = not enter

#endregion

#region Init - configure UI, etc

func _ready() -> void:
	%BlockConfig.hide()
	
	ui.do_raycast = _get_block_from_raycast.bind()
	ui.undo.connect(undo_redo.undo)
	ui.redo.connect(undo_redo.redo)
	
	for element in elements:
		ui.add_element(element)

func _get_block_from_raycast(_point):
	if (_intersection_point-_viewport.get_mouse_position()).length_squared() > 4:
		_intersection = null
		_intersection_need_update = true
	if _intersection:
		var block := get_block_from_collider(_intersection.collider)
		if block.get_parent() == factory_blocks_main_node:
			return block
	return null

func set_visibility(value : bool) -> void:
	visible = value
	ui.call_deferred("set_visibility", value)

#endregion

#region Utils

func _on_element_transform_update(element):
	if element.has_method("on_transform_update"):
		element.on_transform_update()

static func get_block_from_collider(element : PhysicsBody3D) -> Node3D:
	return element.get_parent()

#endregion
