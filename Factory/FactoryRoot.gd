# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT


extends Node

@onready var game_speed := %GameSpeed
@onready var factory_builder := $FactoryBuilder
@onready var factory_control := $FactoryControl
@onready var objects_root := $ObjectsRoot
@onready var user_blocks_root := $UserBlocksRoot
@onready var ui := $FactoryUI

signal factory_start()
signal factory_stop()

var level_scene_node : Node3D

const LEVELS_DIR := "res://Levels/"
const GAME_PROGRESS_SAVE := "user://game_progress.json"
const SAVE_INFO_FILE := "/save_info.json"


### load / save / restore

func load_level(level_id : String, save_dir := "") -> void:
	level_scene_node = load(LEVELS_DIR + level_id + ".tscn").instantiate()
	level_scene_node.name = "FactoryLevel"
	level_scene_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# set circuit_simulator parameters (other parameters are set via factory_control.start()
	factory_control.circuit_simulator.current_limit = level_scene_node.circuit_simulation_current_limit
	factory_control.circuit_simulator.voltage_limit = level_scene_node.circuit_simulation_voltage_limit
	
	# set computer system simulator parameters
	var computer_config = level_scene_node.computer_systems_configuration
	if computer_config:
		DirAccess.make_dir_recursive_absolute("user://common_fs")
		FAG_Utils.remove_dir_recursive("user://workdir/private_fs")
		var private_fs_created = false
		for id in computer_config:
			if computer_config[id].get("writable_disk_image", false):
				var disk_path = "user://workdir/disk_%d.img" % id
				computer_config[id]["writable_disk_image"] = disk_path
				var saved_img = save_dir + "/disk_%d.img" % id
				if save_dir and FileAccess.file_exists(saved_img):
					# copy disk from save
					FAG_Utils.copy_sparse(saved_img, disk_path)
				else:
					# create new disk image
					FAG_Utils.copy_sparse("res://qemu_img/empty_100MB.img", disk_path)
			
			if not private_fs_created and "virtfs" in computer_config[id] and "private_fs" in computer_config[id]["virtfs"]:
				private_fs_created = true
				var saved_fs = save_dir + "/private_fs"
				if save_dir and DirAccess.dir_exists_absolute(saved_fs):
					FAG_Utils.copy_dir_absolute(saved_fs,  "user://workdir/private_fs")
				else:
					DirAccess.make_dir_recursive_absolute("user://workdir/private_fs")
			
			if not "computer_input_names" in computer_config[id]:
				computer_config[id]["computer_input_names"] = []
			
			if not "computer_output_names" in computer_config:
				computer_config[id]["computer_output_names"] = []
			
		$FactoryControl.computer_systems_configuration = computer_config
	factory_builder.defualt_computer_system_id = level_scene_node.defualt_computer_system_id
	
	# run register_factory_signals on static blocks
	for element in level_scene_node.get_node("FactoryBlocks").get_children():
		var info_obj = factory_builder.get_info_from_block(element)
		if "factory_signals" in info_obj:
			factory_control.register_factory_signals(
				info_obj.factory_signals[0],
				info_obj.factory_signals[1],
				info_obj.factory_signals[2],
				element.get_meta("in_game_name", ""),
				element.get_meta("using_computer_id", factory_builder.defualt_computer_system_id),
			)
	
	level_scene_node.init(self, level_id, save_dir != "")
	add_child(level_scene_node)
	
	# hide unsupported blocks in builder UI
	for button in factory_builder.ui._ui_add_elements_container.get_children():
		if button.name in level_scene_node.supported_blocks:
			button.visible = true
			button.disabled = false
		else:
			button.visible = false
	
	# hide unsupported elements in circuit simulation UI
	for button in factory_control.circuit_simulator.grid_editor.ui._ui_add_elements_container.get_children():
		if button.name in level_scene_node.supported_circuit_components:
			button.visible = true
			button.disabled = false
		else:
			button.visible = false
	
	var max_blocks = level_scene_node.get_meta("max_blocks", {})
	if max_blocks.get("ElectronicControlBlock", 0) > 0:
		max_blocks["ElectronicControlBlock"] = 1
	else:
		max_blocks["ElectronicControlBlock"] = 0
	if not "ComputerControlBlock" in max_blocks:
		max_blocks["ComputerControlBlock"] = 0
	
	# update unlocked manuals ... need be done in load to to ensure correct operation of the manual for this level
	var game_progress = FAG_Utils.load_from_json_file(GAME_PROGRESS_SAVE)
	for topic_path in level_scene_node.guide_topic_paths:
		if not topic_path in game_progress.unlocked_manuals:
			var guide_topic_path_splited = topic_path.split("/")
			var added_path = ""
			for node_id in guide_topic_path_splited:
				added_path += node_id
				if not added_path in game_progress.unlocked_manuals:
					game_progress.unlocked_manuals.append(added_path)
				added_path += "/"
			FAG_Utils.write_to_json_file(GAME_PROGRESS_SAVE, game_progress)
	
	_factory_state = FACTORY_STOP
	_start_stop_hud_ui()

func save(save_dir : String) -> void:
	var result = DirAccess.make_dir_recursive_absolute(save_dir)
	if result != OK and result != ERR_ALREADY_EXISTS:
		print("Error while creating save directory: ", result)
	
	FAG_Utils.write_to_json_file(
		save_dir + SAVE_INFO_FILE,
		{
			"level" : level_scene_node.level_id,
			"stats" : _stats,
		}
	)
	
	FAG_Utils.write_to_json_file(save_dir + "/Factory.json", factory_builder.serialise())
	FAG_Utils.write_to_json_file(save_dir + "/Circuit.json", factory_control.circuit_simulator.serialise())
	
	if factory_control.computer_control_blocks:
		FAG_Utils.remove_dir_recursive(save_dir + "/private_fs")
		FAG_Utils.copy_dir_absolute("user://workdir/private_fs", save_dir + "/private_fs")
		for id in factory_control.computer_control_blocks:
			factory_control.computer_control_blocks[id].get_child(0).send_message_via_msg_bus("request_sync") # TODO request also pause ???
			await FAG_Utils.real_time_wait(0.3)  # TODO wait for sync not for timer
			DirAccess.copy_absolute("user://workdir/disk_%d.img" % id, save_dir + "/disk_%d.img" % id)

func restore(save_dir : String) -> void:
	var save_info = FAG_Utils.load_from_json_file(save_dir + SAVE_INFO_FILE)
	load_level(save_info['level'], save_dir)
	
	factory_builder.restore(FAG_Utils.load_from_json_file(save_dir + "/Factory.json"))
	factory_control.circuit_simulator.restore(FAG_Utils.load_from_json_file(save_dir + "/Circuit.json"))

func close() -> void:
	get_tree().paused = true
	await factory_control.close()
	factory_builder.close()
	if level_scene_node:
		_factory_state = FACTORY_STOP | ON_CHANGE
		remove_child(level_scene_node)
		level_scene_node.queue_free()
		level_scene_node = null
	for node in objects_root.get_children():
		node.queue_free()
	_reset_stats()

func is_loaded() -> bool:
	return level_scene_node != null


### start / stop / pause / visibility

func run_factory() -> void:
	if _factory_state & FACTORY_RUNNING:
		printerr("Factory already started")
		return
	
	_factory_state = FACTORY_RUNNING | ON_CHANGE
	_factory_paused = false
	_factory_speed = game_speed.get_value()
	Engine.call_deferred("set_time_scale", _factory_speed)
	factory_builder.ui.set_editor_enabled(false)
	_start_stop_hud_ui()
	
	factory_control.start(
		_stats.block_count_per_type.get("ElectronicControlBlock", 0) > 0,
		level_scene_node.circuit_simulation_time_step,
		level_scene_node.circuit_simulation_max_time
	)
	
	# continue (after control is started) in _on_control_running()

func _on_control_running() -> void:
	print(" starting")
	unpause_factory()
	factory_start.emit()
	await FAG_Utils.real_time_wait(0.2)
	_factory_state &= ~ON_CHANGE
	_start_stop_hud_ui()

func _physics_process(delta):
	if not _factory_state & FACTORY_RUNNING or _factory_state & EMERGENCY_STOP:
		return
	
	factory_control.tick(delta, _factory_paused)

func stop_factory() -> void:
	if not (_factory_state & FACTORY_RUNNING):
		printerr("Factory is not started")
		return
	
	_factory_state = FACTORY_STOP | ON_CHANGE
	_start_stop_hud_ui()
	get_tree().paused = true
	factory_control.stop()
	for node in objects_root.get_children():
		node.queue_free()
	factory_stop.emit()
	
	factory_builder.ui.set_editor_enabled(true)
	Engine.call_deferred("set_time_scale", 1.0)
	
	await FAG_Utils.real_time_wait(0.2)
	_factory_state &= ~ON_CHANGE
	_start_stop_hud_ui()

func pause_factory():
	if not _factory_state & FACTORY_RUNNING:
		return
	
	_factory_paused = true
	get_tree().call_deferred("set_pause", _factory_paused)
	# NOTE: we do not pause circuit simulation here ... it will be "paused" in sync function (via sleep)

func unpause_factory():
	if not _factory_state & FACTORY_RUNNING or _factory_state & EMERGENCY_STOP:
		return
	
	_factory_paused = false
	if factory_control.simulation_on_time:
		get_tree().call_deferred("set_pause", _factory_paused)

var _pre_input_off_ui_input_allowed := true
var _input_is_off := false

func input_off():
	prints("input_on", _pre_input_off_ui_input_allowed, _input_is_off)
	if _input_is_off:
		return
	_input_is_off = true
	_pre_input_off_ui_input_allowed = factory_builder.ui.input_allowed
	factory_builder.ui.input_allowed = false
	factory_builder.camera.disable_input()
	factory_builder.ui.update_cursor(false, true)

func input_on(force := false):
	prints("input_on", _pre_input_off_ui_input_allowed, _input_is_off, force)
	factory_builder.ui.input_allowed = force or _pre_input_off_ui_input_allowed
	factory_builder.ui.update_cursor(true, true)
	factory_builder.camera.enable_input()
	_input_is_off = false

func set_visibility(value : bool) -> void:
	factory_builder.call_deferred("set_visibility", value)
	ui.visible = value


### factory speed control

func _on_game_speed_value_changed(value: float) -> void:
	if not _factory_state & FACTORY_RUNNING:
		_factory_speed = value
		return
	
	if is_equal_approx(value, _factory_speed):
		return
	
	if is_zero_approx(value):
		pause_factory()
	
	if is_zero_approx(_factory_speed):
		unpause_factory()
	
	_factory_speed = value
	Engine.call_deferred("set_time_scale", _factory_speed)

func _on_start_stop_pressed() -> void:
	if _factory_state == FACTORY_STOP:
		run_factory()
	else:
		stop_factory()

func _on_pause_pressed() -> void:
	if _factory_paused:
		unpause_factory()
	else:
		pause_factory()
	_start_stop_hud_ui()

enum { FACTORY_RUNNING = 0b00001 , FACTORY_STOP = 0b00010, ON_CHANGE = 0b00100, EMERGENCY_STOP = 0b01000}

func _start_stop_hud_ui():
	print("_start_stop_hud_ui _factory_state=%x" % _factory_state)
	if _factory_state & FACTORY_STOP:
		%StartStop.text = tr("FACTORY_START")
		%StartStop.disabled = true
	if _factory_state & FACTORY_RUNNING:
		%StartStop.text = tr("FACTORY_STOP")
		%StartStop.disabled = true
	
	if _factory_state & ON_CHANGE:
		%StartStop.disabled = true
		%Pause.disabled = true
	else:
		%StartStop.disabled = false
		%Pause.disabled = not (_factory_state & FACTORY_RUNNING)
	
	if _factory_state & EMERGENCY_STOP :
		%Pause.disabled = true
	
	if _factory_paused:
		%Pause.text = "FACTORY_UNPAUSE"
	else:
		%Pause.text = "FACTORY_PAUSE"

var _factory_state
var _factory_paused
var _factory_speed


### factory errors handling

func _on_circuit_simulation_overcurrent(fuse : String, value : float) -> void:
	printerr("_on_circuit_simulation_overcurrent ", fuse, " ", value)
	emergency_stop(
		"FACTORY_OVERCURRENT_ERROR_TITLE",
		"FACTORY_OVERCURERNT_ERROR_TEXT"
	)

func _on_circuit_simulation_overvoltage(net : String, value : float) -> void:
	printerr("_on_circuit_simulation_overvoltage ", net, " ", value)
	emergency_stop(
		"FACTORY_OVERVOLTAGE_ERROR_TITLE",
		"FACTORY_OVERVOLTAGE_ERROR_TEXT"
	)

func _on_simulation_error() -> void:
	printerr("_on_simulation_error")
	emergency_stop(
		"FACTORY_ERROR_TITLE",
		"FACTORY_ERROR_TEXT"
	)

func _on_conflict_error(info : Array) -> void:
	printerr("electronic circuit / computer system #" + str(info[2]) + " conflict: "  + str(info[3]) + " vs " + str(info[4]) + " in get_signal_value")
	emergency_stop(
		"FACTORY_CIRCUT_COMPUTER_CONFLICT_ERROR_TITLE",
		"FACTORY_CIRCUT_COMPUTER_CONFLICT_ERROR_TEXT"
	)

func emergency_stop(title : String, message : String):
	if _factory_state & EMERGENCY_STOP:
		return
	_factory_state = FACTORY_RUNNING | EMERGENCY_STOP
	_factory_paused = true
	get_tree().paused = true
	factory_control.circuit_simulator.gdspice.emergency_stop()
	_start_stop_hud_ui()
	FAG_WindowManager.hide_by_escape_all_windows(self)
	%Message_Title.text = tr(title)
	%Message_Text.text = tr(message)
	%Message.show()

func _on_errormsg_ok_pressed() -> void:
	%Message.hide()
	FAG_WindowManager.restore_hideen_by_escape()


### win / loss conditions

var check_win_loss_conditions = true

func production_timeout():
	if check_win_loss_conditions:
		emergency_stop(
			"FACTORY_PRODUCT_FAILURE_TITLE",
			"FACTORY_PRODUCT_TIMEOUT_TEXT"
		)
	
func validate_product(node : RigidBody3D):
	if not check_win_loss_conditions or not _factory_state & FACTORY_RUNNING:
		return
	
	var status = level_scene_node.validate_product(node)
	if status < 0:
		_stats.time = factory_control.simulation_time
		_stats.status = "fail"
		emergency_stop(
			"FACTORY_PRODUCT_FAILURE_TITLE",
			"FACTORY_PRODUCT_FAILURE_TEXT"
		)
	elif status > 0:
		_stats.time = factory_control.simulation_time
		_stats.status = "success"
		var game_progress = FAG_Utils.load_from_json_file(GAME_PROGRESS_SAVE)
		game_progress.finished_levels[level_scene_node.level_id] = _stats
		FAG_Utils.write_to_json_file(GAME_PROGRESS_SAVE, game_progress)
		emergency_stop(
			"FACTORY_PRODUCT_SUCCESS_TITLE",
			tr("FACTORY_PRODUCT_SUCCESS_TEXT_%fTIME") % _stats.time
		)


### blocks and circuit elements counts and statistics

func stats2string(stats : Dictionary) -> String:
	return str(stats) # TODO do this better ... not str()

var _stats = {}

func _reset_stats() -> void:
	_stats = {
		"status": "not started",
		"block_count": 0,
		"block_count_per_type" : {},
		"circuit_element_count": 0,
		"circuit_element_count_per_type": {},
	}

func _update_block_count(block: Node3D, val: int) -> void:
	_stats.block_count += val
	
	var info_obj = factory_builder.get_info_from_block(block)
	if "object_subtype" in info_obj:
		var object_subtype = info_obj.object_subtype
		_stats.block_count_per_type[object_subtype] = _stats.block_count_per_type.get(object_subtype, 0) + val
		
		if level_scene_node.block_count_updated(
			object_subtype, block,
			_stats.block_count_per_type[object_subtype],
			factory_builder.ui._elements_dict[object_subtype][1]
		):
			factory_builder.ui.reset_editor()
	
	_stats.status = "not started"

func _update_circuit_element_count(element: Node2D, val: int) -> void:
	var base_element = FAG_2DGrid_BaseElement.get_from_element(element)
	
	if not base_element.type in ["NET", "Meter"]:
		_stats.circuit_element_count += val
	elif base_element.subtype == "NetConnector":
		base_element.get_node("NetNames").netnames = factory_control.netnames
	
	var element_subtype = base_element.subtype
	_stats.circuit_element_count_per_type[element_subtype] = _stats.circuit_element_count_per_type.get(element_subtype, 0) + val
	
	if level_scene_node.circuit_element_count_updated(
		element_subtype, element,
		_stats.circuit_element_count_per_type[element_subtype],
		factory_control.circuit_simulator.grid_editor.ui._elements_dict[element_subtype][1]
	):
		factory_control.circuit_simulator.grid_editor.ui.reset_editor()
	
	_stats.status = "not started"


### init

func _ready() -> void:
	set_visibility(false)
	_factory_state = FACTORY_STOP
	_start_stop_hud_ui()
	factory_builder.on_block_add.connect(_update_block_count.bind(1))
	factory_builder.on_block_remove.connect(_update_block_count.bind(-1))
	factory_builder.factory_blocks_main_node = user_blocks_root
	factory_builder.ui.set_editor_enabled(true)
	
	factory_control.circuit_simulator.grid_editor.ui.import_export_path = "user://circuits/"
	DirAccess.make_dir_recursive_absolute(factory_control.circuit_simulator.grid_editor.ui.import_export_path)
	
	factory_control.circuit_simulator.grid_editor.grid.gElements.on_element_add.connect(_update_circuit_element_count.bind(1))
	factory_control.circuit_simulator.grid_editor.grid.gElements.on_element_remove.connect(_update_circuit_element_count.bind(-1))
	factory_control.circuit_simulator.overcurrent_protection.connect(_on_circuit_simulation_overcurrent)
	factory_control.circuit_simulator.overvoltage_protection.connect(_on_circuit_simulation_overvoltage)
	factory_control.circuit_simulator.simulation_error.connect(_on_simulation_error)
	factory_control.conflict_error.connect(_on_conflict_error)
	factory_control.running.connect(_on_control_running)
	
	_reset_stats()
	
	_console_read_set = FAG_ConsoleReadSet.new(self, "factory", ["check_win_loss_conditions"])
	
	LimboConsole.register_command(_factory_producer, "factory producer", "Perform operation on all (default) or selected (last argument) producers.")
	LimboConsole.add_argument_autocomplete_source("factory producer", 0, func(): return ["start", "stop", "step", "set_time"])
	
	LimboConsole.register_command(_factory_clear, "factory clear", "Remove all products")
	
	LimboConsole.register_command(pause_factory, "pause", "Pause")
	LimboConsole.register_command(unpause_factory, "unpause", "Unpause")


### console commands

var _console_read_set # to keep console read/set variable interface

func _factory_producer(operation : String, arg = null, in_game_name = null):
	if operation in ["start", "stop", "step"]:
		in_game_name = arg
	if in_game_name != null:
		in_game_name = str(in_game_name)
	
	for node in get_tree().get_nodes_in_group("FactoryProducers"):
		if in_game_name == null or in_game_name == node.get_meta("in_game_name", ""):
			match operation:
				"start":
					node._timer.paused = false
				"stop":
					node._timer.paused = true
				"step":
					node._release_object()
				"set_time":
					node.timer_period = float(arg)

func _factory_clear():
	for node in objects_root.get_children():
		node.queue_free()


### misc / utils

func _on_show_task_info() -> void:
	FAG_Settings.get_root_subnode("%Manual").show_info(level_scene_node, GAME_PROGRESS_SAVE)
