# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

class_name Grid2D_Elements
 
signal on_element_add(element: Node2D)
signal on_element_remove(element: Node2D)


### Constructor and requires read-only properties values

var main_node : Node2D = null
var owner_node : Node2D = null
var undo_redo : UndoRedo = null
var grid_size : Vector2

func _init(main_node_ : Node2D, owner_node_ : Node2D = null, undo_redo_ : UndoRedo = null, grid_size_ = Vector2(20, 20)):
	main_node = main_node_
	if owner_node_:
		owner_node = owner_node_
	else:
		owner_node = main_node
	if undo_redo_:
		undo_redo = undo_redo_
	else:
		undo_redo = UndoRedo.new()
	grid_size = grid_size_


### Serialise / Restore

func serialise() -> Array:
	store_infos()
	var save_data = []
	for element in main_node.get_children():
		var values := {}
		for info_node in Grid2D_BaseElement.get_from_element(element).get_children():
			if info_node is LineEdit and info_node.text:
				values[info_node.name] = info_node.text
		
		save_data.append({
			"type": Grid2D_BaseElement.get_from_element(element).subtype,
			"values": values,
			"position": element.position,
			"rotation": element.rotation,
			"scale": element.scale,
		})
	return save_data

func restore(data : Array, elements : Dictionary, offset := Vector2(0, 0)) -> void:
	for element_info in data:
		var packed_scene = elements[element_info.type][0]
		
		var button = elements[element_info.type][1]
		if button.visible == false or button.disabled == true:
			# skip (on import operation) elements not currently available
			# (not available on level or quantity limit exceeded)
			continue
		
		var element = packed_scene.instantiate()
		element.position = FAG_Utils.Vector2_from_JSON(element_info.position) + offset
		element.rotation = element_info.rotation
		element.scale = FAG_Utils.Vector2_from_JSON(element_info.scale)
		
		for info_node in Grid2D_BaseElement.get_from_element(element).get_children():
			if info_node.name in element_info.values:
				info_node.text = element_info.values[info_node.name]
		
		main_node.add_child(element)
		element.owner = main_node
		
		on_element_add.emit(element)

func store_infos() -> void:
	# for tscn save mode
	for element in main_node.get_children():
		var info := {}
		for info_node in Grid2D_BaseElement.get_from_element(element).get_children():
			if info_node is LineEdit and info_node.text:
				info[info_node.name] = info_node.text
		if info:
			element.set_meta("grid_element_info", info)
		elif element.has_meta("grid_element_info"):
			element.remove_meta("grid_element_info")

func restore_infos_and_emit_element_add(element : Node2D) -> void:
	# for tscn restore mode
	if element.has_meta("grid_element_info"):
		var info = element.get_meta("grid_element_info")
		for info_node in Grid2D_BaseElement.get_from_element(element).get_children():
			if info_node.name in info:
				info_node.text = info[info_node.name]
	on_element_add.emit(element)


### Add new element

var new_element : Node2D = null

func init_element(element_scene : PackedScene, point : Vector2) -> void:
	cancel_element()
	new_element = element_scene.instantiate()
	Grid2D_BaseElement.get_from_element(new_element).set_active(false)
	main_node.add_child(new_element)
	update_element(point)

func add_element(point : Vector2) -> void:
	update_element(point)
	
	var element = new_element.duplicate() # BUG: https://github.com/godotengine/godot/issues/92880
	Grid2D_BaseElement.get_from_element(element).set_active(true)
	
	undo_redo.create_action("Grid Element: Add")
	undo_redo.add_do_reference(element)
	undo_redo.add_do_method(_add_element.bind(element))
	undo_redo.add_undo_method(_remove_element.bind(element))
	undo_redo.commit_action()
	element.owner = owner_node

func cancel_element() -> void:
	if new_element:
		main_node.remove_child(new_element)
		new_element.queue_free()
		new_element = null

func update_element(point : Vector2) -> void:
	if new_element:
		new_element.position = point.snapped(grid_size)


### Move existed element

var _moving_elements := {}
var _moving_init_point : Vector2

func move_element__init(elements : Array, point : Vector2) -> void:
	_moving_init_point = point
	for element in elements:
		_moving_elements[element] = element.position

func move_element__cancel() -> void:
	_moving_elements.clear()

func move_element__step(point : Vector2) -> void:
	var move = point - _moving_init_point
	for element in _moving_elements:
		element.position = (_moving_elements[element] + move).snapped(grid_size)

func move_element__finish(start_undo_redo_action = true, finish_undo_redo_action = true) -> bool:
	if not _moving_elements:
		return false
	
	# check (on first element if was moved)
	var first_element = _moving_elements.keys()[0]
	var ret = false
	if first_element.position != _moving_elements[first_element]:
		# create common undo_redo action for all elements
		if start_undo_redo_action:
			undo_redo.create_action("Grid Editor: Move")
		
		for element in _moving_elements:
			undo_redo.add_do_property(element, "position", element.position)
			undo_redo.add_undo_property(element, "position", _moving_elements[element])
		
		if finish_undo_redo_action:
			undo_redo.commit_action()
		ret = true
	_moving_elements.clear()
	return ret


### Rotate / Mirror / Delete existed element

func delete_elements(elements : Array, start_undo_redo_action = true, finish_undo_redo_action = true) -> bool:
	if not elements:
		return false
	
	if start_undo_redo_action:
		undo_redo.create_action("Grid Editor: Delete")
	for element in elements:
		undo_redo.add_do_method(_remove_element.bind(element))
		undo_redo.add_undo_reference(element)
		undo_redo.add_undo_method(_add_element.bind(element))
	
	if finish_undo_redo_action:
		undo_redo.commit_action()
	return true

func rotate_elements(elements : Array, angle : float, pivot = null, start_undo_redo_action = true, finish_undo_redo_action = true) -> bool:
	if not elements:
		return false
	
	if start_undo_redo_action:
		undo_redo.create_action("Grid Editor: Rotate")
	for element in elements:
		undo_redo.add_do_method(element.rotate.bind(angle))
		undo_redo.add_undo_method(element.rotate.bind(-angle))
		if pivot != null:
			undo_redo.add_do_property(element, "position", FAG_Utils.rotate_around_pivot(element.position, pivot, angle))
			undo_redo.add_undo_property(element, "position", element.position)
		undo_redo.add_do_method(Grid2D_BaseElement.get_from_element(element).on_transform_updated.bind())
		undo_redo.add_undo_method(Grid2D_BaseElement.get_from_element(element).on_transform_updated.bind())
	
	if finish_undo_redo_action:
		undo_redo.commit_action()
	return true

func mirror_elements(elements : Array, pivot = null, start_undo_redo_action = true, finish_undo_redo_action = true) -> bool:
	if not elements:
		return false
	
	if start_undo_redo_action:
		undo_redo.create_action("Grid Editor: Mirror")
	for element in elements:
		undo_redo.add_undo_property(element, "scale", element.scale)
		element.scale.y = -element.scale.y
		undo_redo.add_do_property(element, "scale", element.scale)
		
		if pivot != null:
			# in group mirror we only make up-down mirror, so rotated +/- 0.5 PI elements must be rotated 180°
			var abs_rotation = abs(element.rotation)
			if 1.4 < abs_rotation and abs_rotation < 1.6:
				undo_redo.add_undo_property(element, "rotation", element.rotation)
				element.rotation = -element.rotation
				undo_redo.add_do_property(element, "rotation", element.rotation)
			
			undo_redo.add_undo_property(element, "position", element.position)
			element.position = FAG_Utils.mirror_y(element.position, pivot)
			undo_redo.add_do_property(element, "position", element.position)
		
		undo_redo.add_do_method(Grid2D_BaseElement.get_from_element(element).on_transform_updated.bind())
		undo_redo.add_undo_method(Grid2D_BaseElement.get_from_element(element).on_transform_updated.bind())
	
	if finish_undo_redo_action:
		undo_redo.commit_action()
	return true


### Utils

func get_all_elements() -> Array:
	return main_node.get_children()

func find_element_by_point(point : Vector2, skip_element : Node2D = null) -> Node2D:
	for element in main_node.get_children():
		if element != skip_element:
			var image = Grid2D_BaseElement.get_from_element(element).get_node("Image")
			if image.get_rect().has_point(image.to_local(point)):
				return element
	return null

func find_elements_on_area(area : Rect2) -> Array:
	var ret = []
	for element in main_node.get_children():
		var image = Grid2D_BaseElement.get_from_element(element).get_node("Image")
		if (image.global_transform * image.get_rect()).intersects(area):
			ret.append(element)
	return ret

func find_all_terminals_by_point(point : Vector2, squared_distance : float, skip_element : Node2D = null) -> Array[Node2D]:
	var res : Array[Node2D]
	for element in main_node.get_children():
		if element != skip_element:
			for terminal in Grid2D_BaseElement.get_from_element(element).get_node("Connections").get_children():
				if terminal.global_position.distance_squared_to(point) <= squared_distance:
					res.append(terminal)
	return res

func _add_element(element : Node2D) -> void:
	main_node.add_child(element)
	on_element_add.emit(element)

func _remove_element(element : Node2D) -> void:
	main_node.remove_child(element)
	on_element_remove.emit(element)
