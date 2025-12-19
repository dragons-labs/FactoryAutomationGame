# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

### Constructor and requires read-only properties values

var main_node : Node2D = null
var owner_node : Node2D = null
var undo_redo : UndoRedo = null
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
	grid_size = grid_size_


### Properties (can be changed on run)

var line_width := 3
var line_color := Color.WHITE
var orthogonal_lines := true
var marker_radius_multipler := 1.75
var ConnectionMarker : Object = FAG_Utils.load(self, "ConnectionMarker.gd")

### Serialise / Restore

func serialise() -> Array:
	var save_data = []
	for line in main_node.get_children():
		save_data.append(Array(line.points))
	return save_data

func restore(data : Array, offset := Vector2.ZERO, duplicate_mode := false) -> void:
	var segments = []
	for line_info in data:
		var _new_line = Line2D.new()
		_new_line.width = line_width
		_new_line.default_color = line_color
		for point in line_info:
			_new_line.add_point(point + offset)
		main_node.add_child(_new_line)
		if duplicate_mode:
			segments.append({"line": _new_line})
	if duplicate_mode:
		init_duplicate(segments, offset, false)
	update_connections()

### Undo Redo counters (for pseudo action merging)

var _need_undo_in_object_mode := 0
var _need_redo_in_object_mode := 0

func _update_need_undo_redo_after_undo(undo_update := 0, redo_set := 0) -> void:
	_need_undo_in_object_mode -= 1
	if _need_undo_in_object_mode < 0:
		_need_undo_in_object_mode = 0
	
	_need_undo_in_object_mode += undo_update
	_need_redo_in_object_mode = redo_set + 1
	
func _update_need_undo_redo_after_redo(redo_update := 0, undo_set := 0) -> void:
	_need_redo_in_object_mode -= 1
	if _need_redo_in_object_mode < 0:
		_need_redo_in_object_mode = 0
	
	_need_redo_in_object_mode += redo_update
	_need_undo_in_object_mode = undo_set + 1

func need_execute_next_undo_in_object_mode() -> bool:
	return _need_undo_in_object_mode > 0

func need_execute_next_redo_in_object_mode() -> bool:
	if not undo_redo.has_redo():
		return false
	
	if _need_redo_in_object_mode > 0:
		return true
	
	# if next redo is "Grid Line: Finish adding line"
	if undo_redo.get_action_name(undo_redo.get_current_action()+1) == "Grid Line: Finish adding line":
		return true
	
	return false


### Draw new line

var new_line : Line2D = null
var has_drawing_point := false

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
		undo_redo.add_do_method(_update_need_undo_redo_after_redo.bind(1))
		
		undo_redo.add_undo_method(main_node.remove_child.bind(new_line))
		# equivalent of `new_line.queue_free()` will be called on "redo" lost in result of `add_do_reference(new_line)`
		undo_redo.add_undo_property(self, "new_line", null)
		undo_redo.add_undo_method(_update_need_undo_redo_after_undo.bind())
		
		undo_redo.commit_action()
	else:
		var line_len = _add_line_new_point(point)
		if line_len > 2:
			connect_segments(new_line, line_len-2)
		
		undo_redo.create_action("Grid Line: Add segment")
		
		undo_redo.add_do_property(new_line, "points", new_line.points)
		undo_redo.add_do_property(self, "has_drawing_point", false)
		undo_redo.add_do_method(_update_need_undo_redo_after_redo.bind(0, 1))
		
		undo_redo.add_undo_property(new_line, "points", new_line.points)
		undo_redo.add_undo_method(_update_need_undo_redo_after_undo.bind(0, 1))
		
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
			
			# check connection on start point
			var index = 0
			var line_to_connect = find_line_by_endpoint(new_line.get_point_position(index), new_line)
			if line_to_connect:
				new_line = connect_lines(line_to_connect.line, line_to_connect.index, new_line, index, undo_redo)
			
			# check connection on end point
			index = new_line.get_point_count()-1 # if we merge at start point then this must be called with new value of new_line
			line_to_connect = find_line_by_endpoint(new_line.get_point_position(index), new_line)
			if line_to_connect:
				new_line = connect_lines(line_to_connect.line, line_to_connect.index, new_line, index, undo_redo)
			
			# update "on line" connections
			undo_redo.add_do_method(update_connections)
			undo_redo.add_undo_method(update_connections)
			
			undo_redo.add_do_method(_update_need_undo_redo_after_redo.bind())
			undo_redo.add_undo_method(_update_need_undo_redo_after_undo.bind(2))
			
			undo_redo.add_do_property(self, "new_line", null)
			undo_redo.commit_action()


### Move segments / points of existed lines

var _moving_segments := {}
var _moving_init_point : Vector2

func update_segment__init(segments : Array, point : Vector2) -> void:
	_moving_init_point = point
	for segment in segments:
		_moving_segments[segment] = segment.line.points

func move_segment__cancel() -> void:
	_moving_segments.clear()

func update_segment__step(point : Vector2) -> void:
	var move = point - _moving_init_point
	for segment in _moving_segments:
		for point_index_in_line in segment.indexes:
			segment.line.set_point_position(
				point_index_in_line, (_moving_segments[segment][point_index_in_line] + move).snapped(grid_size)
			)
	update_connections()
	# intentionally do not call connect_lines (for inner points) / connect_segments (for end point) here

func update_segment__finish(start_undo_redo_action = true, finish_undo_redo_action = true) -> bool:
	if not _moving_segments:
		return false
	
	# check (on first element if was moved)
	var first_segment = _moving_segments.keys()[0]
	var first_index = first_segment.indexes[0]
	var ret = false
	if first_segment.line.get_point_position(first_index) != _moving_segments[first_segment][first_index]:
		# create common undo_redo action for all elements
		if start_undo_redo_action:
			undo_redo.create_action("Grid Editor: Move")
		
		for segment in _moving_segments:
			undo_redo.add_do_property(segment.line, "points", segment.line.points)
			undo_redo.add_undo_property(segment.line, "points", _moving_segments[segment])
		
		undo_redo.add_do_method(update_connections)
		undo_redo.add_undo_method(update_connections)
		
		if finish_undo_redo_action:
			undo_redo.commit_action()
		ret = true
	_moving_segments.clear()
	return ret


### Remove segments / points of existed lines

func remove_segment(segments : Array, start_undo_redo_action = true, finish_undo_redo_action = true) -> bool:
	if not segments:
		return false
	
	if start_undo_redo_action:
		undo_redo.create_action("Grid Editor: Remove line segment")
	
	for segment in segments:
		var line : Line2D = segment.line
		var indexes_to_remove : Array = segment.indexes # indexes are always sorted
		
		# prepare new_points - array of points list (each list for one line)
		var new_points := []
		var new_sub_points := []
		var i = 0 # index in line.points
		var j = 0 # index in indexes_to_remove
		while i < len(line.points) and j < len(indexes_to_remove):
			new_sub_points = []
			while i < indexes_to_remove[j]:
				new_sub_points.append(line.points[i])
				i += 1
			
			var old_j = j
			while j + 1 < len(indexes_to_remove) and indexes_to_remove[j+1] == indexes_to_remove[j] + 1:
				j += 1
			
			if old_j != j:
				new_sub_points.append(line.points[i])
				i = indexes_to_remove[j]
			else:
				i = indexes_to_remove[j]+1
			
			if len(new_sub_points) > 1:
				new_points.append(new_sub_points)
			
			j += 1
		
		# add all points located after last pointy to remove
		new_sub_points = []
		while i < len(line.points):
			new_sub_points.append(line.points[i])
			i += 1
		if len(new_sub_points) > 1:
			new_points.append(new_sub_points)
		
		# remove / update / create new line based on new_points
		if len(new_points) < 1:
			undo_redo.add_undo_reference(line)
			undo_redo.add_do_method(main_node.remove_child.bind(line))
			undo_redo.add_undo_method(main_node.add_child.bind(line))
		else:
			undo_redo.add_undo_property(line, "points", line.points)
			undo_redo.add_do_property(line, "points", new_points[0])
			
			for k in range(1, len(new_points)):
				# create new line
				var splited_line = Line2D.new()
				splited_line.width = line_width
				splited_line.default_color = line_color
				
				# add new line with subset of points
				undo_redo.add_do_reference(splited_line)
				undo_redo.add_do_method(main_node.add_child.bind(splited_line))
				undo_redo.add_do_property(splited_line, "owner", owner_node)
				undo_redo.add_do_property(splited_line, "points", new_points[k])
				undo_redo.add_undo_method(main_node.remove_child.bind(splited_line))
	
	undo_redo.add_do_method(update_connections)
	undo_redo.add_undo_method(update_connections)
	
	if finish_undo_redo_action:
		undo_redo.commit_action()
	return true


### Rotate and mirror group of lines
func rotate_segments(segments : Array, angle : float, pivot, start_undo_redo_action = true, finish_undo_redo_action = true) -> bool:
	if not segments:
		return false
	
	if start_undo_redo_action:
		undo_redo.create_action("Grid Editor: Rotate")
	for segment in segments:
		var line : Line2D = segment.line
		var points := line.points
		for i in segment.indexes:
			points[i] = FAG_Utils.rotate_around_pivot(points[i], pivot, angle)
		undo_redo.add_do_property(line, "points", points)
		undo_redo.add_undo_property(line, "points", line.points)
	
	undo_redo.add_do_method(update_connections)
	undo_redo.add_undo_method(update_connections)
	
	if finish_undo_redo_action:
		undo_redo.commit_action()
	return true

func mirror_segments(segments : Array, pivot, start_undo_redo_action = true, finish_undo_redo_action = true) -> bool:
	if not segments:
		return false
	
	if start_undo_redo_action:
		undo_redo.create_action("Grid Editor: Mirror")
	for segment in segments:
		var line : Line2D = segment.line
		var points := line.points
		for i in segment.indexes:
			points[i] = FAG_Utils.mirror_y(points[i], pivot)
		undo_redo.add_do_property(line, "points", points)
		undo_redo.add_undo_property(line, "points", line.points)
	
	undo_redo.add_do_method(update_connections)
	undo_redo.add_undo_method(update_connections)
	
	if finish_undo_redo_action:
		undo_redo.commit_action()
	return true


### Duplicate lines

var _new_lines := {}
var _new_lines_init_point : Vector2

func init_duplicate(segments : Array, point : Vector2, duplicate := true) -> void:
	_new_lines_init_point = point
	duplicate_cancel()
	for segment in segments:
		var _new_line = segment.line.duplicate() if duplicate else segment.line
		# TODO use only segments matched to segment.indexes (if indexes is available) ... if need (split line) then add new lines
		_new_lines[_new_line] = []
		_new_lines[_new_line].resize(_new_line.get_point_count())
		for i in range(_new_line.get_point_count()):
			_new_lines[_new_line][i] = segment.line.get_point_position(i)
		main_node.add_child(_new_line)
	duplicate_update(point)

func duplicate_finish(point : Vector2) -> void:
	duplicate_update(point)
	
	undo_redo.create_action("Grid Line(s): Add")
	for _new_line in _new_lines:
		var line = _new_line.duplicate() # BUG: https://github.com/godotengine/godot/issues/92880
		undo_redo.add_do_reference(line)
		undo_redo.add_do_method(main_node.add_child.bind(line))
		undo_redo.add_undo_method(main_node.remove_child.bind(line))
		undo_redo.add_do_method(update_connections)
		undo_redo.add_undo_method(update_connections)
	undo_redo.commit_action()

func duplicate_cancel() -> void:
	for _new_line in _new_lines:
		main_node.remove_child(_new_line)
		_new_line.queue_free()
	_new_lines.clear()

func duplicate_update(point : Vector2) -> void:
	var move = point - _new_lines_init_point
	for _new_line in _new_lines:
		for i in range(_new_line.get_point_count()):
			_new_line.set_point_position(
				i, (_new_lines[_new_line][i] + move).snapped(grid_size)
			)


### Edit existed lines

# NOTE: those functions need externally handling of Undo-Redo API

func connect_lines(lineA : Line2D, point_index_on_lineA: int, lineB : Line2D, point_index_on_lineB: int, undo_redo_ : UndoRedo = null) -> Line2D:
	if lineA.has_node("c0" if point_index_on_lineA == 0 else "c1"):
		# do not connect to line with connection marker
		return lineB
	
	var pointsA := lineA.points
	if undo_redo_:
		undo_redo_.add_undo_property(lineA, "points", pointsA)
	if point_index_on_lineA == 0:
		pointsA.reverse()
		lineA.points = pointsA
	
	var pointsB := lineB.points
	if undo_redo_:
		undo_redo_.add_undo_reference(lineB)
		undo_redo_.add_undo_method(main_node.add_child.bind(lineB))
		undo_redo_.add_undo_property(lineB, "points", pointsB)
	if point_index_on_lineB > 0:
		pointsB.reverse()
	
	for i in range(1, len(pointsB)):
		lineA.add_point(pointsB[i])
	
	connect_segments(lineA, len(pointsA) - 1)
	
	if undo_redo_:
		undo_redo_.add_do_method(main_node.remove_child.bind(lineB))
		# equivalent of `lineB.queue_free()` will be called on "undo" lost in result of `add_undo_reference(lineB)`
		undo_redo_.add_do_property(lineA, "points", lineA.points)
		lineB.clear_points()
	else:
		main_node.remove_child(lineB)
		lineB.queue_free()
	
	return lineA

static func connect_segments(line : Line2D, index : int) -> void:
	# check angle between segments and join segment if possible
	var p3 = line.get_point_position(index-1)
	var p2 = line.get_point_position(index)
	var p1 = line.get_point_position(index+1)
	var t1 = (p3.x-p2.x)/(p3.y-p2.y)
	var t2 = (p2.x-p1.x)/(p2.y-p1.y)
	if is_equal_approx(t1, t2) or (is_equal_approx(p3.y, p2.y) and is_equal_approx(p2.y, p1.y)):
		line.remove_point(index)


### Utils


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
				return {"line": line, "point": point_on_segment, "indexes": indexes}
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

func find_segments_on_area(area : Rect2) -> Array:
	var ret = []
	for line in main_node.get_children():
		var indexes = []
		for i in range(0, line.get_point_count()):
			if area.has_point(line.get_point_position(i)):
				indexes.append(i)
		if indexes:
			ret.append({"line": line, "indexes": indexes})
	return ret

func update_connections() -> void:
	for line in main_node.get_children():
		for i in [0, line.get_point_count() - 1]:
			var point = line.get_point_position(i)
			var connection_point = find_line_by_point(point, line)
			var marker_node_name = "c0" if i == 0 else "c1"
			if connection_point:
				var marker = null
				if line.has_node(marker_node_name):
					marker = line.get_node(marker_node_name)
				else:
					marker = ConnectionMarker.new(line_color, line.width * marker_radius_multipler)
					marker.name = marker_node_name
					line.add_child(marker)
				marker.global_position = point
			else:
				if line.has_node(marker_node_name):
					var marker = line.get_node(marker_node_name)
					line.remove_child(marker)
					marker.queue_free()
