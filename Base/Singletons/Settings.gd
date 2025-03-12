# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node

signal keymap_update()

const SETTING_FILE := "user://settings.json"

static func register_action(action_name : StringName, events_keys_info : Array, override_existed := false) -> bool:
	if InputMap.has_action(action_name):
		if override_existed:
			InputMap.action_erase_events(action_name)
		else:
			return false
	else:
		InputMap.add_action(action_name)
	
	for key in events_keys_info:
		var event
		if key and "key" in key:
			event = InputEventKey.new()
			event.keycode = key["key"]
		elif key and "button" in key:
			event = InputEventMouseButton.new()
			event.button_index = key["button"]
			event.double_click = key.get("double_click", false)
		else:
			continue
		event.pressed = not key.get("released", false)
		event.alt_pressed = key.get("alt", false)
		event.ctrl_pressed = key.get("ctrl", false)
		event.shift_pressed = key.get("shift", false)
		event.meta_pressed = key.get("meta", false)
		InputMap.action_add_event(action_name, event)
	return true

static func _get_prop_info(property_list : Array, prop_name : String) -> Dictionary:
	for prop_info in property_list:
		if prop_info.name == prop_name:
			return prop_info
	return {}

static func set_default_setting_from_object(object : Object, tr_prefix : String, setting_list : Array) -> Dictionary:
	var settings = {}
	var props_info = object.get_property_list()
	for setting_name in setting_list:
		var setting_info = {}
		if setting_name is Array:
			setting_info = setting_name[1]
			setting_name = setting_name[0]
		setting_info["default_value"] = object.get(setting_name)
		setting_info["ui_name"] = tr_prefix + setting_name
		if not "possible_values" in setting_info:
			var prop_info = _get_prop_info(props_info, setting_name)
			if prop_info.hint == PROPERTY_HINT_ENUM:
				setting_info["possible_values"] = prop_info.hint_string.split(",")
		settings[setting_name] = setting_info
	return settings
	
static func set_default_controls_and_create_actions(tr_prefix : String, actions_list : Dictionary) -> Dictionary:
	var actions = {}
	for action_name in actions_list:
		register_action(action_name, actions_list[action_name])
		actions[action_name] = [actions_list[action_name], tr_prefix + action_name]
	return actions


var _all_settings := {}
var _custom_values := {}
var _custom_actions := {}

func register_settings(object : Object, group_name : String, settings : Dictionary, actions : Dictionary) -> void:
	if group_name in _all_settings:
		_all_settings[group_name].objects.append(object)
		_all_settings[group_name].settings.merge(settings)
		_all_settings[group_name].actions.merge(actions)
	else:
		_all_settings[group_name] = {
			"objects": [object],
			"settings": settings,
				# Dictionary:
				#   key → setting name
				#   value → Dictionary:
				#     default_value → default value
				#     ui_name → UI name (for translate)
				#     possible_values → (optional) list of possible values for this setting
			"actions": actions,
				# Dictionary:
				#   key → action name (used in InputMap)
				#   value[0] → default action events info – events_keys_info (Array of Dictionaries, argument of `register_action`)
				#   value[1] → UI name
		}

func reset_to_default(group_name : String) -> void:
	_custom_values.clear()
	_custom_actions.clear()
	for setting_name in _all_settings[group_name].settings:
		var def_value = _all_settings[group_name].settings[setting_name].default_value
		for obj in _all_settings[group_name].objects:
			if setting_name in obj:
				obj.set(setting_name, def_value)
	for action_name in _all_settings[group_name].actions:
		register_action(action_name, _all_settings[group_name].actions[action_name][0], true)

func reset_to_default_all() -> void:
	for group_name in _all_settings:
		reset_to_default(group_name)

func apply_custom(group_name : String) -> void:
	if group_name in _custom_values:
		for setting_name in _custom_values[group_name]:
			var value = _custom_values[group_name][setting_name]
			for obj in _all_settings[group_name].objects:
				if setting_name in obj:
					obj.set(setting_name, value)
	if group_name in _custom_actions:
		for action_name in _custom_actions[group_name]:
			register_action(action_name, _custom_actions[group_name][action_name], true)

func apply_custom_all() -> void:
	for group_name in _all_settings:
		
		apply_custom(group_name)


func generate_settings_ui(group_name : String, ui_parent : Control, ui_remap_info : Control) -> void:
	var setting_ui_template = ui_parent.get_node("Setting")
	var action_ui_template = ui_parent.get_node("Action")
	var group_ui_template = ui_parent.get_node("Group")
	# WARNING: all above chidren of ui_parent must be hidden when calling reset_settings_ui()
	#          before calls generate_settings_ui() / generate_settings_ui_all()
	#          (e.g. hidden via scene editor setting)
	#          otherwise may be deleted and caused crash in this function
	if group_name in _all_settings:
		if _all_settings[group_name].settings or _all_settings[group_name].actions:
			var group_info = _all_settings[group_name]
			# add group title
			var setting_group_label = group_ui_template.duplicate()
			setting_group_label.setup_and_show(group_name, ui_parent)
			# add actions
			for action_name in group_info.actions:
				var action_info = group_info.actions[action_name]
				var events = InputMap.action_get_events(action_name)
				var action_ui = action_ui_template.duplicate()
				action_ui.setup_and_show(action_info[1], group_name, action_name, events, _on_action_remap_start, ui_parent, ui_remap_info)
				
			# add settings
			for setting_name in group_info.settings:
				var current_value
				for obj in group_info.objects:
					if setting_name in obj:
						current_value = obj.get(setting_name)
						break
				var setting_info = group_info.settings[setting_name]
				var setting_ui = setting_ui_template.duplicate()
				setting_ui.setup_and_show(group_name, setting_name, setting_info, current_value, _on_setting_value_changed, ui_parent)

func reset_settings_ui(ui_parent : Control) -> void:
	for c in ui_parent.get_children():
		if c.visible:
			ui_parent.remove_child(c)
			c.queue_free()

func generate_settings_ui_all(ui_parent : Control, ui_remap_info : Control, skip := []) -> void:
	for group_name in _all_settings:
		if not group_name in skip:
			generate_settings_ui(group_name, ui_parent, ui_remap_info)

var action_rempaing = []

func _on_action_remap_start(args : Array) -> void:
	action_rempaing = args
	
	var group_name = action_rempaing[0]
	var action_name = action_rempaing[1]
	var ui_setting_info_widget = action_rempaing[4]
	var old_event = action_rempaing[5]
	
	ui_setting_info_widget.setup_and_show(_all_settings[group_name].actions[action_name][1], old_event)

func _on_action_remap_finish(event : Variant) -> void:
	var group_name = action_rempaing[0]
	var action_name = action_rempaing[1]
	var event_index = action_rempaing[2]
	var ui_setting_button = action_rempaing[3]
	var ui_setting_info_widget = action_rempaing[4]
	var old_event = action_rempaing[5]
	
	print("Remap action ", action_name, " index=", event_index, " to ", event)
	
	var old_events_info = _all_settings[group_name].actions[action_name][0]
	var new_event_info = {}
	if event:
		if event is InputEventKey:
			new_event_info["key"] = event.keycode
		elif event is InputEventMouseButton:
			new_event_info["button"] = event.button_index
			new_event_info["double_click"] = event.double_click
		new_event_info["released"] = not event.pressed
		new_event_info["alt"] = event.alt_pressed
		new_event_info["ctrl"] = event.ctrl_pressed
		new_event_info["shift"] = event.shift_pressed
		new_event_info["meta"] = event.meta_pressed
	
	if not group_name in _custom_actions:
		_custom_actions[group_name] = {}
	if event_index == 0:
		if len(old_events_info) > 1:
			_custom_actions[group_name][action_name] = [ new_event_info,  old_events_info[1] ]
		else:
			_custom_actions[group_name][action_name] = [ new_event_info ]
	if event_index == 1:
		_custom_actions[group_name][action_name] = [ old_events_info[0], new_event_info ]
	
	if old_event:
		print("rem")
		InputMap.action_erase_event(action_name, old_event)
	if event:
		print("add")
		InputMap.action_add_event(action_name, event)
		ui_setting_button.text = event.as_text()
	else:
		ui_setting_button.text = "..."
	
	action_rempaing = []
	ui_setting_info_widget.hide()

func _on_setting_value_changed(value : Variant, group_name : String, setting_name : String) -> void:
	if not group_name in _custom_values:
		_custom_values[group_name] = {}
	_custom_values[group_name][setting_name] = value
	
	for obj in _all_settings[group_name].objects:
		if setting_name in obj:
			obj.set(setting_name, value)

func _ready() -> void:
	load_from_file_and_apply()

func cancel_settings_changes() -> void:
	reset_to_default_all()
	load_from_file_and_apply()
	
func accept_settings_changes() -> void:
	FAG_Utils.write_to_json_file(SETTING_FILE, [_custom_values, _custom_actions])
	keymap_update.emit()

func load_from_file_and_apply() -> void:
	if FileAccess.file_exists(SETTING_FILE):
		var saved_settings = FAG_Utils.load_from_json_file(SETTING_FILE)
		_custom_values = saved_settings[0]
		_custom_actions = saved_settings[1]
		apply_custom_all()
