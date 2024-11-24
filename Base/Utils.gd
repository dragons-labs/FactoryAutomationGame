# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends RefCounted
class_name FAG_Utils

#
# 2D geometry
#

## return point mirrored in y around pivot
static func mirror_y(point : Vector2, pivot : Vector2) -> Vector2:
	point.y = 2 * pivot.y - point.y #  ==  point.y - 2 * offset_in_y  ==  point.y - 2 * (point.y - pivot.y)
	return point

static func rotate_around_pivot(point : Vector2, pivot : Vector2, angle : float) -> Vector2:
	return (pivot - point).rotated(-angle) + pivot

#
# input related
#

static func create_shorcut(action_name : StringName) -> Shortcut:
	var shortcut := Shortcut.new()
	shortcut.events = InputMap.action_get_events(action_name)
	return shortcut

static func action_exact_match(action_name : String, event : InputEvent) -> bool:
	var result = event.is_action(action_name, true)
	return _match_double_click(action_name, event, result)

static func action_exact_match_pressed(action_name : String, event : InputEvent = null, allow_echo := false) -> bool:
	if event:
		var result = event.is_action_pressed(action_name, allow_echo, true)
		return _match_double_click(action_name, event, result)
	else:
		return Input.is_action_pressed(action_name, true)

static func _match_double_click(action_name : String, event : InputEvent, result : bool) -> bool:
	if result and event is InputEventMouseButton:
		# if Godot return true and this is mouse button event we check more carefully
		for action_event in InputMap.action_get_events(action_name):
			if action_event is InputEventMouseButton:
				if action_event.button_index == action_event.button_index and \
					action_event.ctrl_pressed == action_event.ctrl_pressed and \
					action_event.shift_pressed == event.shift_pressed and \
					action_event.meta_pressed == event.meta_pressed:
						# if we found the same event we return double_click comparison
						return action_event.double_click == event.double_click
		printerr("Can't find event in ", action_name, " matched to ", event)
		return false
	
	return result


#
# JSON
#

static func load_from_json_file(path : String) -> Variant:
	var save_info_file = FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(save_info_file.get_as_text())

static func write_to_json_file(path : String, data : Variant) -> void:
	var save_info_file = FileAccess.open(path, FileAccess.WRITE)
	save_info_file.store_string(JSON.stringify(data, "  "))

static func Vector3_from_JSON(data : Variant) -> Vector3:
	if data is Vector3:
		return data
	if data is not String or data[0] != '(':
		printerr("Invalid data ", data, " passed to Vector3_from_JSON")
		return Vector3.ZERO
	
	var data_splited = data.substr(1, data.length()-2).split(",")
	return Vector3(
		data_splited[0].to_float(),
		data_splited[1].to_float(),
		data_splited[2].to_float()
	)

static func Vector2_from_JSON(data : Variant) -> Vector2:
	if data is Vector2:
		return data
	if data is not String or data[0] != '(':
		printerr("Invalid data ", data, " passed to Vector2_from_JSON")
		return Vector2.ZERO
	
	var data_splited = data.substr(1, data.length()-2).split(",")
	return Vector2(
		data_splited[0].to_float(),
		data_splited[1].to_float()
	)


#
# paths, files and directories
#

static func globalize_path(path : String) -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path(path)
	else:
		if path.begins_with("res://"):
			return OS.get_executable_path().get_base_dir().path_join(path.substr(6))
		elif path.begins_with("user://"):
			return ProjectSettings.globalize_path(path)
		else:
			return OS.get_executable_path().get_base_dir().path_join(path)

static func get_system_path_to_script_dir(caller : Variant) -> String:
	return globalize_path( caller.get_script().resource_path.get_base_dir() )

static func copy_dir_absolute(src: String, dst: String) -> void:
	var src_dir = DirAccess.open(src)
	if not src_dir:
		return
	
	DirAccess.make_dir_recursive_absolute(dst)
	
	for filename in src_dir.get_files():
		src_dir.copy(src + "/" + filename, dst + "/" + filename)
	for dir in src_dir.get_directories():
		copy_dir_absolute(src + "/" + dir, dst + "/" + dir)

static func remove_dir_recursive(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return
	
	for filename in dir.get_files():
		dir.remove(filename)
	for subdir in dir.get_directories():
		remove_dir_recursive(path + "/" + subdir)
	
	DirAccess.remove_absolute(path)

static func copy_sparse(src: String, dst: String) -> void:
	# try rsync with -S option
	if 0 == OS.execute("rsync", ["-S", globalize_path(src), globalize_path(dst)]):
		return
	if OS.get_name() in ["Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD", "macOS"]:
		# Linux (GNU Coreutils) and maybe some other posix-like OS `cp` support sparse
		if 0 == OS.execute("cp", [globalize_path(src), globalize_path(dst)]):
			return
	# use Godot copy as fallback
	DirAccess.copy_absolute(src, dst)


#
# misc
#

static func get_with_fallback(values : Dictionary, key : String, fallback_key : String) -> Variant:
	var val = values.get(key, null)
	if not val:
		val = values.get(fallback_key, null)
	return val

static func get_locale_version(values : Dictionary) -> Variant:
	return get_with_fallback(
		values,
		TranslationServer.get_locale(),
		ProjectSettings.get("internationalization/locale/fallback")
	)

static func find_item_in_item_list(item_list : ItemList, text : String) -> int:
	for i in range(0, item_list.item_count):
		if item_list.get_item_text(i) == text:
			return i
	return -1

static func check_elements_count_default(element_type : String, element_type_count : int, max_element: Dictionary, button : Button) -> bool:
	var editor_need_reset = false
	if element_type in max_element:
		if element_type_count >= max_element[element_type]:
			button.disabled = true
			editor_need_reset = true
		else:
			button.disabled = false
	return editor_need_reset

static func real_time_wait(time : float, parent : Node = null) -> void:
	if parent:
		await parent.get_tree().create_timer(time, true, false, true).timeout
	else:
		await Engine.get_main_loop().create_timer(time, true, false, true).timeout
