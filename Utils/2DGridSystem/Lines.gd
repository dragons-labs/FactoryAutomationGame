# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

### Constructor and requires read-only properties values

var main_node : Node2D = null
var owner_node : Node2D = null
var undo_redo : UndoRedo = null
var _fake_undo_redo : UndoRedo = null
var grid_size : Vector2

func _init(main_node_ : Node2D, owner_node_ : Node2D = null, undo_redo_ : UndoRedo = null, grid_size_ := Vector2(20, 20)) -> void:
	main_node = main_node_
	if owner_node_:
		owner_node = owner_node_
	else:
		owner_node = main_node
	if undo_redo_:
		undo_redo = undo_redo_
	else:
		undo_redo = UndoRedo.new()
	_fake_undo_redo = UndoRedo.new()
	_fake_undo_redo.max_steps = 1
	grid_size = grid_size_


### Properties (can be changed on run)

@export var line_width := 3
@export var line_color := Color.WHITE
@export var orthogonal_lines := true
@export var marker_radius_multipler := 1.75
@export var ConnectionMarker = FAG_Utils.load(self, "ConnectionMarker.gd")

### Serialise / Restore

func serialise() -> Array:
	var save_data = []
	for line in main_node.get_children():
		save_data.append(Array(line.points))
	return save_data

func restore(data : Array, offset := Vector2.ZERO, duplicate_mode := false) -> void:
	var lines = []
	for line_info in data:
		var _new_line = Line2D.new()
		_new_line.width = line_width
		_new_line.default_color = line_color
		for point in line_info:
			_new_line.add_point(point + offset)
		main_node.add_child(_new_line)
		if duplicate_mode:
			lines.append(_new_line)
	if duplicate_mode:
		move_duplicate_init(lines, offset, false)
	update_connections(true)


### Undo Redo support functions (for pseudo action merging)

func need_execute_next_undo(action_name : String) -> bool:
	return action_name == "Grid Line: Add segment" or action_name == "Grid Line: Init new line"

func need_execute_next_redo(action_name : String) -> bool:
	return action_name == "Grid Line: Add segment" or action_name == "Grid Line: Finish adding line"


### Draw new line

var new_line : Line2D = null
var has_drawing_point := false

func new_line__add_point(point : Vector2) -> void:
	if not new_line:
		new_line = Line2D.new()
		new_line.width = line_width
		new_line.default_color = line_color
		new_line.add_point(point.snapped(grid_size))
		has_drawing_point = false
		
		undo_redo.create_action("Grid Line: Init new line")
		
		undo_redo.add_do_reference(new_line)
		undo_redo.add_do_property(self, "new_line", new_line)
		undo_redo.add_do_method(main_node.add_child.bind(new_line))
		undo_redo.add_do_property(new_line, "owner", owner_node)
		
		undo_redo.add_undo_method(main_node.remove_child.bind(new_line))
		# equivalent of `new_line.queue_free()` will be called on "redo" lost in result of `add_do_reference(new_line)`
		undo_redo.add_undo_property(self, "new_line", null)
		undo_redo.add_undo_method(update_connections.bind(false))
		
		undo_redo.commit_action()
	else:
		var line_len = _add_line_new_point(point)
		if line_len > 2:
			connect_segments(new_line, line_len-2)
		
		undo_redo.create_action("Grid Line: Add segment")
		undo_redo.add_do_property(new_line, "points", new_line.points)
		undo_redo.add_do_property(self, "has_drawing_point", false)
		undo_redo.add_undo_property(new_line, "points", new_line.points)
		undo_redo.commit_action()

func new_line__update_segment(point : Vector2) -> void:
	if new_line:
		_add_line_new_point(point)
		has_drawing_point = true

func new_line__finish() -> void:
	if new_line:
		if has_drawing_point:
			new_line.remove_point(new_line.get_point_count()-1)
		
		if new_line.get_point_count() < 2:
			undo_redo.undo()
		else:
			undo_redo.create_action("Grid Line: Finish adding line")
			undo_redo.add_undo_property(self, "new_line", new_line)
			undo_redo.add_undo_property(self, "has_drawing_point", false)
			
			# update "on line" connections
			#  first full update with line merging (and registering in undo/redo)
			update_connections(true, undo_redo)
			#  next only refresh markers for redo action
			undo_redo.add_do_method(update_connections.bind(false))
			# NOTE: marker refresh for undo action is in new_line__add_point because it must be call after real line remove
			
			undo_redo.add_do_property(self, "new_line", null)
			undo_redo.commit_action()

func _add_line_new_point(point : Vector2) -> int:
	var line_len := new_line.get_point_count()
	
	if has_drawing_point and orthogonal_lines:
		var last_point = new_line.get_point_position(line_len - 2)
		var delta = (last_point - point).abs()
		if delta.x > delta.y:
			point.y = last_point.y
		else:
			point.x = last_point.x
	
	point = point.snapped(grid_size)
	
	if has_drawing_point:
		new_line.set_point_position(line_len - 1, point)
		return line_len
	else:
		new_line.add_point(point)
		return line_len + 1


### Move or duplicate lines

var _moving_lines := []
var _moving_lines_init_point : Vector2
var _moving_lines_need_free := false

func move_duplicate_init(lines : Array, point : Vector2, duplicate) -> void:
	_moving_lines_init_point = point
	move_duplicate_cancel(duplicate)
	for l : Variant in lines:
		var ld : Dictionary = get_with_indexes(l)
		if duplicate:
			ld = ld.duplicate()
			ld.line = ld.line.duplicate()
			ld.indexes = ld.indexes.duplicate()
			main_node.add_child(ld.line)
		ld["org_pos"] = ld.line.points
		_moving_lines.append(ld)
	move_duplicate_update(point)

func move_duplicate_update(point : Vector2) -> void:
	var move = point - _moving_lines_init_point
	for ld : Dictionary in _moving_lines:
		for i in ld.indexes:
			ld.line.set_point_position(
				i, (ld.org_pos[i] + move).snapped(grid_size)
			)
	update_connections(false)

func move_duplicate_finish(duplicate := true, start_undo_redo_action = true, finish_undo_redo_action = true) -> int:
	if not _moving_lines:
		return 0
	
	if start_undo_redo_action:
		undo_redo.create_action("Grid Editor: " + "Add Lines" if duplicate else "Move")
	
	for ld : Dictionary in _moving_lines:
		if duplicate:
			var line = ld.line.duplicate()
			undo_redo.add_do_reference(line)
			undo_redo.add_do_method(main_node.add_child.bind(line))
			undo_redo.add_undo_method(main_node.remove_child.bind(line))
		else:
			undo_redo.add_do_property(ld.line, "points", ld.line.points)
			undo_redo.add_undo_property(ld.line, "points", ld.org_pos)
	
	# do not call `update_connections(true, undo_redo)` here to avoid merge lines in duplication buffer
	undo_redo.add_do_method(update_connections.bind(false))
	undo_redo.add_undo_method(update_connections.bind(false))
	
	if finish_undo_redo_action:
		undo_redo.commit_action()
	return 1

func move_duplicate_cancel(next_val := false) -> void:
	if _moving_lines_need_free:
		for ld : Dictionary in _moving_lines:
			main_node.remove_child(ld.line)
			ld.line.queue_free()
	_moving_lines_need_free = next_val
	_moving_lines.clear()

func duplicate_rotate(angle : float, point : Vector2) -> void:
	rotate_lines(_moving_lines, angle, point, true, true, true)
	_update_moving_lines_positions(point)

func duplicate_mirror(point : Vector2) -> void:
	mirror_lines(_moving_lines, point, true, true, true)
	_update_moving_lines_positions(point)

func _update_moving_lines_positions(point : Vector2) -> void:
	for ld : Dictionary in _moving_lines:
		ld.org_pos = []
		for i in range(ld.line.get_point_count()):
			var pos = ld.line.get_point_position(i).snapped(grid_size)
			ld.line.set_point_position( i, pos )
			ld.org_pos.append(pos)
	_moving_lines_init_point = point


### Rotate or mirror lines

func _update_lines(lines : Array, start_undo_redo_action : bool, finish_undo_redo_action : bool, no_undo : bool, operation : Callable, action) -> int:
	if not lines:
		return 0
	
	var local_undo_redo = _fake_undo_redo if no_undo else undo_redo
	if start_undo_redo_action or no_undo:
		local_undo_redo.create_action("Grid Editor: " + action)
	
	for l in lines:
		var ld : Dictionary = get_with_indexes(l)
		var points = ld.line.points
		for i in ld.indexes:
			points[i] = operation.call(points[i])
		local_undo_redo.add_do_property(ld.line, "points", points)
		local_undo_redo.add_undo_property(ld.line, "points", ld.line.points)
	
	local_undo_redo.add_do_method(update_connections.bind(false))
	local_undo_redo.add_undo_method(update_connections.bind(false))
	
	if finish_undo_redo_action or no_undo:
		local_undo_redo.commit_action()
	return 1

func rotate_lines(lines : Array, angle : float, pivot, start_undo_redo_action = true, finish_undo_redo_action = true, no_undo = false) -> int:
	return _update_lines(lines, start_undo_redo_action, finish_undo_redo_action, no_undo, FAG_Utils.rotate_around_pivot.bind(pivot.snapped(grid_size), angle), "Rotate")

func mirror_lines(lines : Array, pivot, start_undo_redo_action = true, finish_undo_redo_action = true, no_undo = false) -> int:
	return _update_lines(lines, start_undo_redo_action, finish_undo_redo_action, no_undo, FAG_Utils.mirror_y.bind(pivot.snapped(grid_size)), "Mirror")


### Remove lines or its segments

func _delete_line(line : Line2D) -> void:
	undo_redo.add_undo_reference(line)
	undo_redo.add_undo_property(line, "points", line.points)
	undo_redo.add_undo_method(main_node.add_child.bind(line))
	undo_redo.add_do_method(line.clear_points.bind())
	undo_redo.add_do_method(main_node.remove_child.bind(line))

func delete_lines(lines : Array, start_undo_redo_action = true, finish_undo_redo_action = true) -> int:
	if not lines:
		return 0
	
	if start_undo_redo_action:
		undo_redo.create_action("Grid Editor: Remove")
	
	for l in lines:
		if "indexes" in l:
			if not split_line(l.line, l.indexes, l.indexes, false, false):
				_delete_line(l.line)
		else:
			_delete_line(l)
	
	undo_redo.add_do_method(update_connections.bind(false))
	undo_redo.add_undo_method(update_connections.bind(false))
	
	if finish_undo_redo_action:
		undo_redo.commit_action()
	return 1


### Line split and merge

func split_lines(lines : Array, return_all := false):
	var ret = []
	for l in lines:
		var idx = 0
		var ld : Dictionary = get_with_indexes(l)
		for nl in split_line(ld.line, ld.indexes, []):
			if return_all or idx in ld.indexes:
				ret.append(nl)
			idx += ld.line.get_point_count()
	return ret

func split_line(line : Line2D, positions : Array, skip_positions : Array, start_undo_redo_action = true, finish_undo_redo_action = true):
	var new_lines = []
	var points = line.points
	if len(points) < 2:
		if 0 in skip_positions or 1 in skip_positions:
			return []
		else:
			return [line]
	
	if start_undo_redo_action:
		undo_redo.create_action("Split Lines")
	
	# create new points lists
	var prev_pos = 0
	for pos in positions + [len(points)]:
		if pos not in skip_positions and prev_pos not in skip_positions:
			var nline_points = points.slice(prev_pos, pos+1)
			if len(nline_points) > 1:
				var nline : Line2D
				if len(new_lines) == 0:
					undo_redo.add_undo_property(line, "points", line.points)
					nline = line
				else: 
					nline = Line2D.new()
					nline.width = line.width
					nline.default_color = line.default_color
					undo_redo.add_do_reference(nline)
					undo_redo.add_do_method(main_node.add_child.bind(nline))
					undo_redo.add_do_property(nline, "owner", owner_node)
					undo_redo.add_undo_method(main_node.remove_child.bind(nline))
				undo_redo.add_do_property(nline, "points", nline_points)
				new_lines.append(nline)
		prev_pos = pos
	
	if finish_undo_redo_action:
		undo_redo.commit_action()
	
	return new_lines

func merge_lines() -> void:
	var are_lines_to_merge = update_connections(false)
	if are_lines_to_merge and not undo_redo.has_redo():
		undo_redo.create_action("Merge Lines")
		update_connections(true, undo_redo)
		undo_redo.commit_action()


### Utils - Find lines

func find_line_by_point(point : Vector2, skip_line : Line2D = null) -> Dictionary:
	for line in main_node.get_children():
		if line == skip_line:
			continue
		var squared_width : float = line.width * line.width
		var squared_width2 : float = squared_width * 4
		for i in range(line.get_point_count() - 1):
			var point_on_segment := Geometry2D.get_closest_point_to_segment(
				point, line.get_point_position(i), line.get_point_position(i+1)
			)
			var indexes := [i, i+1]
			if point_on_segment.distance_squared_to(line.get_point_position(i)) <= squared_width2:
				indexes = [i]
			if point_on_segment.distance_squared_to(line.get_point_position(i+1)) <= squared_width2:
				indexes = [i+1]
			if point_on_segment.distance_squared_to(point) <= squared_width:
				return {"line": line, "indexes": indexes, "hit_point": point_on_segment}
	return {}

func find_line_by_endpoint(point : Vector2, skip_line : Line2D = null) -> Dictionary:
	for line in main_node.get_children():
		if line == skip_line or line.get_point_count() < 2:
			continue
		for i in [0, line.get_point_count() - 1]:
			if is_zero_approx(point.distance_squared_to(line.get_point_position(i))):
				return {"line": line, "index": i}
	return {};

func find_all_lines_by_point(point : Vector2, squared_distance : float, skip_line : Line2D = null) -> Array[Line2D]:
	var res : Array[Line2D]
	for line in main_node.get_children():
		if line != skip_line:
			for i in range(0, line.get_point_count() - 1):
				var point_on_segment = Geometry2D.get_closest_point_to_segment(
					point, line.get_point_position(i), line.get_point_position(i+1)
				)
				if point_on_segment.distance_squared_to(point) <= squared_distance:
					res.append(line)
					break
	return res

func find_lines_on_area(area : Rect2) -> Array[Dictionary]:
	var ret : Array[Dictionary]
	for line in main_node.get_children():
		var indexes = []
		for i in range(0, line.get_point_count()):
			if area.has_point(line.get_point_position(i)):
				indexes.append(i)
		if indexes:
			ret.append({"line": line, "indexes": indexes})
	return ret


### Utils - Segments indexes

static func get_with_indexes(line : Variant) -> Dictionary:
	if line is Line2D:
		return {"line": line, "indexes": range(line.get_point_count())}
	if not "indexes" in line:
		line["indexes"] = range(line.line.get_point_count())
	return line

static func get_line(line : Variant) -> Line2D:
	return line if (line is Line2D) else line.line


### Utils - Connections markers and line merge

static func _reverse_line(line: Line2D) -> void:
	var points = line.points
	points.reverse()
	line.clear_points()
	for p in points:
		line.add_point(p)

static func connect_segments(line : Line2D, index : int) -> void:
	# check angle between segments and join segment if possible
	var p3 = line.get_point_position(index-1)
	var p2 = line.get_point_position(index)
	var p1 = line.get_point_position(index+1)
	var t1 = (p3.x-p2.x)/(p3.y-p2.y)
	var t2 = (p2.x-p1.x)/(p2.y-p1.y)
	if is_equal_approx(t1, t2) or (is_equal_approx(p3.y, p2.y) and is_equal_approx(p2.y, p1.y)):
		line.remove_point(index)

static func _transfer_line_points(src : Line2D, dst : Line2D, reverse_src : bool, reverse_dst : bool, local_undo_redo = null, remove_src := true) -> void:
	var points = src.points
	var old_size = dst.get_point_count()
	
	if local_undo_redo:
		local_undo_redo.add_undo_reference(src)
		local_undo_redo.add_undo_property(src, "points", src.points)
		local_undo_redo.add_undo_property(dst, "points", dst.points)
	
	if reverse_dst:
		_reverse_line(dst)
	if reverse_src:
		points.reverse()
	for i in range(len(points)):
		if i==0 and points[0] == dst.get_point_position(dst.get_point_count()-1):
			continue
		dst.add_point(points[i])
	
	connect_segments(dst, old_size-1)
	
	src.clear_points()
	if remove_src:
		var scr_parent = src.get_parent()
		if local_undo_redo:
			local_undo_redo.add_do_property(dst, "points", dst.points)
			local_undo_redo.add_do_method(scr_parent.remove_child.bind(src))
			local_undo_redo.add_undo_method(scr_parent.add_child.bind(src))
		else:
			scr_parent.remove_child(src)
			src.queue_free()

static func _remove_marker(line, marker_node_name):
	if line.has_node(marker_node_name):
		var marker = line.get_node(marker_node_name)
		line.remove_child(marker)
		marker.queue_free()

func _update_connections(lines: Array, do_line_merge, local_undo_redo) -> Array:
	var line_to_repeat = []
	# for each line
	for line in lines:
		# skip 0 and 1 point lines
		if line.get_point_count() < 2:
			continue
		# for first and last point on line
		for i in [0, line.get_point_count() - 1]:
			var point = line.get_point_position(i)
			var other_line = find_line_by_point(point, line)
			var marker_node_name = "c0" if i == 0 else "c1"
			# if found other line in this point
			if other_line:
				# if this is begin of other line
				if len(other_line.indexes) == 1 and other_line.indexes[0] == 0:
					_remove_marker(line, marker_node_name)
					if do_line_merge:
						_transfer_line_points(other_line.line, line, false, i==0, local_undo_redo)
					line_to_repeat.append(line)
				# or if this is end of other line
				elif len(other_line.indexes) == 1 and other_line.indexes[0] == other_line.line.get_point_count() - 1:
					_remove_marker(line, marker_node_name)
					if do_line_merge:
						_transfer_line_points(other_line.line, line, true, i==0, local_undo_redo)
					line_to_repeat.append(line)
				# otherwise ... add / update connection marker
				else:
					var marker = null
					if line.has_node(marker_node_name):
						marker = line.get_node(marker_node_name)
					else:
						marker = ConnectionMarker.new(line_color, line.width * marker_radius_multipler)
						marker.name = marker_node_name
						line.add_child(marker)
					marker.global_position = point
			else:
				_remove_marker(line, marker_node_name)
	return line_to_repeat

func update_connections(do_line_merge := false, local_undo_redo = null) -> bool:
	var line_to_repeat = _update_connections(main_node.get_children(), do_line_merge, local_undo_redo)
	
	var ret = len(line_to_repeat) != 0
	if not do_line_merge:
		return ret
	
	while line_to_repeat:
		line_to_repeat = _update_connections(line_to_repeat, do_line_merge, local_undo_redo)
	return ret
