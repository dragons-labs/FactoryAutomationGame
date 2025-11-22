# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

class_name FAG_2DGrid_Elements
 
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
	var save_data = []
	for element in main_node.get_children():
		var values := {}
		for info_node in element.get_children():
			if info_node is LineEdit and info_node.text:
				values[info_node.name] = info_node.text
		
		save_data.append({
			"type": element.subtype,
			"values": values,
			"position": element.position,
			"rotation": element.rotation,
			"scale": element.scale,
		})
	return save_data

func restore(data : Array, elements : Dictionary, offset := Vector2.ZERO, duplicate_mode := false) -> void:
	var new_elements = []
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
		
		for info_node in element.get_children():
			if info_node.name in element_info.values:
				info_node.text = element_info.values[info_node.name]
		
		main_node.add_child(element)
		
		if duplicate_mode:
			new_elements.append(element)
		else:
			element.owner = owner_node
			on_element_add.emit(element)
	
	if duplicate_mode:
		add_elements__init(new_elements, offset, false, false)


### Add new element

var _new_elements := {}
var _new_elements_init_point : Vector2

func add_element__init(element_scene : PackedScene, point : Vector2) -> void:
	add_elements__init([element_scene.instantiate()], point, false, true)

func add_elements__init(elements : Array, point : Vector2, duplicate := true, at_cursor_position := false) -> void:
	_new_elements_init_point = point
	add_element__cancel()
	for element in elements:
		var new_element = element.duplicate_element() if duplicate else element
		_new_elements[new_element] = point if at_cursor_position else new_element.position
		new_element.set_active(false)
		main_node.add_child(new_element)
	add_element__update(point)

func add_element__finish(point : Vector2) -> void:
	add_element__update(point)
	
	undo_redo.create_action("Grid Element: Add")
	for new_element in _new_elements:
		var element = new_element.duplicate_element()
		element.set_active(true)
		undo_redo.add_do_reference(element)
		undo_redo.add_do_method(_add_element.bind(element))
		undo_redo.add_undo_method(_remove_element.bind(element))
	undo_redo.commit_action()

func add_element__cancel() -> void:
	for new_element in _new_elements:
		main_node.remove_child(new_element)
		new_element.queue_free()
	_new_elements.clear()

func add_element__update(point : Vector2) -> void:
	var move = point - _new_elements_init_point
	for new_element in _new_elements:
		new_element.position = (_new_elements[new_element] + move).snapped(grid_size)


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
		undo_redo.add_do_method(element.on_transform_updated.bind())
		undo_redo.add_undo_method(element.on_transform_updated.bind())
	
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
		
		undo_redo.add_do_method(element.on_transform_updated.bind())
		undo_redo.add_undo_method(element.on_transform_updated.bind())
	
	if finish_undo_redo_action:
		undo_redo.commit_action()
	return true


### Utils

func get_all_elements() -> Array:
	return main_node.get_children()

func find_element_by_point(point : Vector2, skip_element : Node2D = null) -> Node2D:
	for element in main_node.get_children():
		if element != skip_element:
			var image = element.get_node("Image")
			if image.get_rect().has_point(image.to_local(point)):
				return element
	return null

func find_elements_on_area(area : Rect2) -> Array:
	var ret = []
	for element in main_node.get_children():
		var image = element.get_node("Image")
		if (image.global_transform * image.get_rect()).intersects(area):
			ret.append(element)
	return ret

func find_all_terminals_by_point(point : Vector2, squared_distance : float, skip_element : Node2D = null) -> Array[Node2D]:
	var res : Array[Node2D]
	for element in main_node.get_children():
		if element != skip_element:
			for terminal in element.get_node("Connections").get_children():
				if terminal.global_position.distance_squared_to(point) <= squared_distance:
					res.append(terminal)
	return res

func _add_element(element : Node2D) -> void:
	main_node.add_child(element)
	element.owner = owner_node
	on_element_add.emit(element)

func _remove_element(element : Node2D) -> void:
	main_node.remove_child(element)
	on_element_remove.emit(element)
