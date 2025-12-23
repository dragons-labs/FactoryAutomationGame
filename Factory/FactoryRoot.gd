# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT


extends Node

@onready var game_speed := %GameSpeed
@onready var factory_builder := $FactoryBuilder
@onready var factory_control := $FactoryControl
@onready var objects_root := $ObjectsRoot
@onready var user_blocks_root := $UserBlocksRoot
@onready var ui := $FactoryUI

## start signal for factory blocks
signal factory_start()

## stop signal for factory blocks
signal factory_stop()

## start signal emitted after started factory block just before switch UI to working state
signal factory_started()

## stop signal emitted after stopped factory block just before switch UI to working state
signal factory_stopped()

## pause signal emitted after emergency stop occurred, just before switch UI to pause state and show message
signal emergency_stopped()

## close signal emitted at end of close() function
signal factory_closed()

## load signal emitted after level is loaded
signal level_loaded()

## load signal emitted after save is restored
signal save_loaded()


var level_scene_node : Node3D

const LEVELS_DIR := "res://Levels/"
const GAME_PROGRESS_SAVE := "user://game_progress.json"
const SAVE_INFO_FILE := "/save_info.json"


### load / save / restore

func load_level(level_id : String, save_dir := "") -> void:
	print_rich("[color=cyan][b]Loading level " + level_id + " ...[/b][/color]")
	
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
	
	level_scene_node.init(self, level_id, save_dir != "")
	add_child(level_scene_node)
	
	# run register_factory_signals on static blocks
	for element in level_scene_node.get_node("FactoryBlocks").get_children():
		if "init" in element:
			element.init(self)
	
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
	
	_factory_state = FactoryState.STOP
	_start_stop_hud_ui()
	
	print_rich("[color=cyan][b]Level loaded.[/b][/color]")
	level_loaded.emit()

func async_save(save_dir : String) -> void:
	print_rich("[color=cyan][b]Writing save file " + save_dir + " ...[/b][/color]")
	
	var result = DirAccess.make_dir_recursive_absolute(save_dir)
	if result != OK and result != ERR_ALREADY_EXISTS:
		print("Error while creating save directory: ", result)
	
	FAG_Utils.write_to_json_file(
		save_dir + SAVE_INFO_FILE,
		{
			"level" : level_scene_node.level_id,
			"camera": factory_builder.camera.serialise(),
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
	
	print_rich("[color=cyan][b]Save file written.[/b][/color]")

func restore(save_dir : String) -> void:
	var save_info = FAG_Utils.load_from_json_file(save_dir + SAVE_INFO_FILE)
	load_level(save_info['level'], save_dir)
	
	print_rich("[color=cyan][b]Restoring save file " + save_dir + " ...[/b][/color]")
	
	factory_builder.restore(FAG_Utils.load_from_json_file(save_dir + "/Factory.json"))
	factory_control.circuit_simulator.restore(FAG_Utils.load_from_json_file(save_dir + "/Circuit.json"))
	if 'camera' in save_info:
		factory_builder.camera.restore(save_info['camera'])
	
	print_rich("[color=cyan][b]Save file restored.[/b][/color]")
	save_loaded.emit()

func async_close() -> void:
	print_rich("[color=cyan][b]Closing factory ...[/b][/color]")
	_start_canceled = true	
	
	print("Pausing tree ...")
	get_tree().paused = true
	
	await factory_control.async_close()
	
	print("Closing 3D world ...")
	factory_builder.close()
	if level_scene_node:
		_factory_state = FactoryState.STOP | FactoryState.ON_CHANGE
		remove_child(level_scene_node)
		level_scene_node.queue_free()
		level_scene_node = null
	for node in objects_root.get_children():
		node.queue_free()
	
	_reset_stats()
	%Message.hide()
	
	print_rich("[color=cyan][b]Factory is closed.[/b][/color]")
	factory_closed.emit()

func is_loaded() -> bool:
	return level_scene_node != null


### start / stop / pause / visibility

func run_factory() -> void:
	if _factory_state & FactoryState.RUNNING:
		printerr("Factory already started")
		return
	
	print_rich("[color=cyan][b]Starting factory ...[/b][/color]")
	_factory_state = FactoryState.RUNNING | FactoryState.STARTING
	_start_canceled = false
	_factory_paused = false
	_factory_start_allowed = get_tree().paused
	_factory_speed = game_speed.get_value()
	Engine.call_deferred("set_time_scale", _factory_speed)
	factory_builder.ui.set_editor_enabled(false)
	_start_stop_hud_ui()
	
	@warning_ignore("missing_await") factory_control.async_start(
		_stats.block_count_per_type.get("ElectronicControlBlock", 0) > 0,
		level_scene_node.circuit_simulation_time_step,
		level_scene_node.circuit_simulation_max_time
	)
	# continue (after control is started) in _async_on_control_running()

func _async_on_control_running() -> void:
	if _start_canceled: return

	_factory_state |= FactoryState.CONTROL_IS_RUNNING
	_factory_state |= FactoryState.ON_CHANGE
	_start_stop_hud_ui()
	
	while not _factory_start_allowed:
		# wait for _factory_start_allowed
		await FAG_Utils.real_time_wait(0.1)
	if _start_canceled: return
	
	print("Unpausing tree ...")
	get_tree().paused = false
	
	await FAG_Utils.real_time_wait(0.1) # some time to process control circuit signals before emit start ... important for control enabled signals
	if _start_canceled: return
	
	print("Sending start signal to factory block ...")
	factory_start.emit()
	
	await FAG_Utils.real_time_wait(0.2)
	if _start_canceled: return

	_factory_state &= ~FactoryState.STARTING
	_factory_state &= ~FactoryState.ON_CHANGE
	
	print_rich("[color=cyan][b]Factory is running.[/b][/color]")
	factory_started.emit()
	_start_stop_hud_ui()

func _physics_process(delta):
	if not _factory_state & FactoryState.RUNNING or _factory_state & FactoryState.EMERGENCY_STOP:
		return
	
	factory_control.tick(delta, _factory_paused)

func async_stop_factory() -> void:
	if not (_factory_state & FactoryState.RUNNING):
		printerr("Factory is not started")
		return
	if _factory_state & FactoryState.STARTING and _factory_state & FactoryState.ON_CHANGE:
		printerr("Using stop while factory is started ... this may cause undefined behavior")
		
	print_rich("[color=cyan][b]Stopping factory ...[/b][/color]")
	_start_canceled = true
	_factory_state = FactoryState.STOP | FactoryState.ON_CHANGE
	_start_stop_hud_ui()
	
	print("Pausing tree ...")
	get_tree().paused = true
	
	await factory_control.async_stop()
	
	print("Removing products ...")
	for node in objects_root.get_children():
		node.queue_free()
	
	print("Sending stop signal to factory block ...")
	factory_stop.emit()
	
	factory_builder.ui.set_editor_enabled(true)
	Engine.call_deferred("set_time_scale", 1.0)
	
	await FAG_Utils.real_time_wait(0.2)
	_factory_state &= ~FactoryState.ON_CHANGE
	
	print_rich("[color=cyan][b]Factory is stopped.[/b][/color]")
	factory_stopped.emit()
	_start_stop_hud_ui()

func pause_factory():
	_factory_start_allowed = false
	
	if not _factory_state & FactoryState.RUNNING or _factory_state & FactoryState.EMERGENCY_STOP or _factory_state & FactoryState.STARTING:
		return
	
	_factory_paused = true
	get_tree().call_deferred("set_pause", _factory_paused)
	# NOTE: we do not pause circuit simulation here ... it will be "paused" in sync function (via sleep)

func unpause_factory():
	_factory_start_allowed = true
	
	if not _factory_state & FactoryState.RUNNING or _factory_state & FactoryState.EMERGENCY_STOP or _factory_state & FactoryState.STARTING:
		return
	
	_factory_paused = false
	if factory_control.simulation_on_time:
		get_tree().call_deferred("set_pause", _factory_paused)

func is_factory_paused():
	return _factory_paused

var _input_is_off := false

func input_off():
	if _input_is_off:
		return
	_input_is_off = true
	factory_builder.disable_input()

func input_on(force := false):
	factory_builder.enable_input(force)
	_input_is_off = false

func set_visibility(value : bool) -> void:
	factory_builder.call_deferred("set_visibility", value)
	ui.visible = value


### factory speed control

func _on_game_speed_value_changed(value: float) -> void:
	if not _factory_state & FactoryState.RUNNING:
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

func _async_on_start_stop_pressed() -> void:
	if _factory_state == FactoryState.STOP:
		run_factory()
	else:
		@warning_ignore("missing_await") async_stop_factory()

func _on_pause_pressed() -> void:
	if _factory_paused:
		unpause_factory()
	else:
		pause_factory()
	_start_stop_hud_ui()

enum FactoryState { RUNNING = (1 << 0) , STOP = (1 << 1), ON_CHANGE = (1 << 2), EMERGENCY_STOP = (1 << 3), STARTING = (1 << 4), CONTROL_IS_RUNNING = (1 << 5)}

func _start_stop_hud_ui():
	print("_start_stop_hud_ui _factory_state=%x" % _factory_state)
	if _factory_state & FactoryState.STOP:
		%StartStop.text = tr("FACTORY_START")
		%StartStop.disabled = true
	if _factory_state & FactoryState.RUNNING:
		%StartStop.text = tr("FACTORY_STOP")
		%StartStop.disabled = true
	
	if _factory_state & FactoryState.ON_CHANGE:
		%StartStop.disabled = true
		%Pause.disabled = true
	else:
		%StartStop.disabled = false
		%Pause.disabled = not (_factory_state & FactoryState.RUNNING and not _factory_state & FactoryState.STARTING)
	
	if _factory_state & FactoryState.EMERGENCY_STOP :
		%Pause.disabled = true
	
	if _factory_paused:
		%Pause.text = "FACTORY_UNPAUSE"
	else:
		%Pause.text = "FACTORY_PAUSE"

var _factory_state
var _factory_speed
var _factory_paused: bool
var _factory_start_allowed: bool
var _start_canceled: bool

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

func _on_simulation_error(message: String) -> void:
	printerr("_on_simulation_error: ", message)
	emergency_stop(
		"FACTORY_ERROR_TITLE",
		"FACTORY_ERROR_TEXT"
	)

func _on_conflict_error(info : Array) -> void:
	if len(info) == 6:
		printerr("computer system #" + str(info[5]) + " / computer system #" + str(info[2]) + " conflict: "  + str(info[3]) + " vs " + str(info[4]) + " in get_signal_value")
	else:
		printerr("electronic circuit / computer system #" + str(info[2]) + " conflict: "  + str(info[3]) + " vs " + str(info[4]) + " in get_signal_value")
	emergency_stop(
		"FACTORY_CIRCUT_COMPUTER_CONFLICT_ERROR_TITLE",
		"FACTORY_CIRCUT_COMPUTER_CONFLICT_ERROR_TEXT"
	)

func emergency_stop(title : String, message : String):
	if _factory_state & FactoryState.EMERGENCY_STOP:
		return
	_factory_state = FactoryState.RUNNING | FactoryState.EMERGENCY_STOP
	_factory_paused = true
	_start_canceled = true
	get_tree().paused = true
	factory_control.circuit_simulator.gdspice.emergency_stop()
	
	emergency_stopped.emit()
	
	_start_stop_hud_ui()
	FAG_WindowManager.hide_all_windows()
	%Message_Title.text = tr(title)
	%Message_Text.text = tr(message)
	%Message.show()

func _on_errormsg_ok_pressed() -> void:
	%Message.hide()
	FAG_WindowManager.restore_hidden_windows()


### win / loss conditions

var check_win_loss_conditions = true

func production_timeout():
	if check_win_loss_conditions:
		emergency_stop(
			"FACTORY_PRODUCT_FAILURE_TITLE",
			"FACTORY_PRODUCT_TIMEOUT_TEXT"
		)
	
func validate_product(node : RigidBody3D):
	if not check_win_loss_conditions or not _factory_state & FactoryState.RUNNING:
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
	
	if "object_type" in block:
		var object_type = block.object_type
		_stats.block_count_per_type[object_type] = _stats.block_count_per_type.get(object_type, 0) + val
		
		if level_scene_node.block_count_updated(
			object_type, block,
			_stats.block_count_per_type[object_type],
			factory_builder.ui._elements_dict[object_type][1]
		):
			factory_builder.ui.reset_editor()
	
	_stats.status = "not started"

func _update_circuit_element_count(element: Node2D, val: int) -> void:
	if not element.type in ["NET", "Meter"]:
		_stats.circuit_element_count += val
	elif element.subtype == "NetConnector":
		element.get_node("NetNames").netnames = factory_control.netnames
	
	var element_subtype = element.subtype
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
	process_physics_priority = -5 # NOTE: should be negative (processed factory control before world physics), but grater than ComputerSystemSimulator.process_physics_priority
	
	set_visibility(false)
	_factory_state = FactoryState.STOP
	_factory_paused = true
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
	factory_control.simulation_error.connect(_on_simulation_error)
	factory_control.conflict_error.connect(_on_conflict_error)
	factory_control.running.connect(_async_on_control_running)
	
	_reset_stats()
	
	_console_read_set = FAG_Utils.ConsoleReadSet.new(self, "factory", ["check_win_loss_conditions"])
	
	LimboConsole.register_command(_factory_producer, "factory producer", "Perform operation on all (default) or selected (last argument) producers.")
	LimboConsole.add_argument_autocomplete_source("factory producer", 0, func(): return ["start", "stop", "step", "set_time"])
	
	LimboConsole.register_command(_factory_clear, "factory clear", "Remove all products")
	
	LimboConsole.register_command(pause_factory, "pause", "Pause")
	LimboConsole.register_command(unpause_factory, "unpause", "Unpause")


### console commands

var _console_read_set # to keep console read/set variable interface

func _factory_producer(operation : String, arg = null, producer_name = null):
	if operation in ["start", "stop", "step"]:
		producer_name = arg
	if producer_name != null:
		producer_name = str(producer_name)
	
	for node in get_tree().get_nodes_in_group("FactoryProducers"):
		if producer_name == null or producer_name == node.get_block_control().get_block_name():
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

func show_task_info(grab_escape := false) -> void:
	show_manual.emit(level_scene_node, GAME_PROGRESS_SAVE, grab_escape)

signal show_manual(object : Object, progress_save_path : String, grab_escape : bool)
