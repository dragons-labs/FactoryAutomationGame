# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node

@onready var game_speed := %GameSpeed
@onready var factory_builder := $FactoryBuilder
@onready var circuit_simulator := factory_builder.get_node("%ElectronicsSimulator")
@onready var products_root := $ProductsRoot
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
	level_scene_node.init(self, level_id, save_dir != "")
	add_child(level_scene_node)
	
	# set circuit_simulator parameters
	circuit_simulator.external_output_nets = level_scene_node.circuit_factory_output_nets
	circuit_simulator.external_input_nets = level_scene_node.circuit_factory_input_nets
	circuit_simulator.external_circuit_entries = level_scene_node.circuit_factory_extra_entries
	circuit_simulator.simulation_time_step = level_scene_node.circuit_simulation_time_step
	circuit_simulator.simulation_max_time = level_scene_node.circuit_simulation_max_time
	circuit_simulator.current_limit = level_scene_node.circuit_simulation_current_limit
	circuit_simulator.voltage_limit = level_scene_node.circuit_simulation_voltage_limit
	
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
					FAG_Utils.copy_sparse("res://ComputerSimulator/OS/bin/empty_100MB.img", disk_path)
			
			if not private_fs_created and "virtfs" in computer_config[id] and "private_fs" in computer_config[id]["virtfs"]:
				private_fs_created = true
				var saved_fs = save_dir + "/private_fs"
				if save_dir and DirAccess.dir_exists_absolute(saved_fs):
					FAG_Utils.copy_dir_absolute(saved_fs,  "user://workdir/private_fs")
				else:
					DirAccess.make_dir_recursive_absolute("user://workdir/private_fs")
			
		factory_builder.computer_systems_configuration = computer_config
	 
	# hide unsupported blocks in builder UI
	for button in factory_builder.ui._ui_add_elements_container.get_children():
		if button.name in level_scene_node.supported_blocks:
			button.visible = true
			button.disabled = false
		else:
			button.visible = false
	
	# hide unsupported elements in circuit simulation UI
	for button in circuit_simulator.grid_editor.ui._ui_add_elements_container.get_children():
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
	if not level_scene_node.guide_topic_path in game_progress.unlocked_manuals:
		var guide_topic_path_splited = level_scene_node.guide_topic_path.split("/")
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
	FAG_Utils.write_to_json_file(save_dir + "/Circuit.json", circuit_simulator.serialise())
	
	if factory_builder.computer_control_blocks:
		FAG_Utils.remove_dir_recursive(save_dir + "/private_fs")
		FAG_Utils.copy_dir_absolute("user://workdir/private_fs", save_dir + "/private_fs")
		for id in factory_builder.computer_control_blocks:
			factory_builder.computer_control_blocks[id].get_child(0).send_message_via_msg_bus("request_sync") # TODO request also pause ???
			await get_tree().create_timer(0.3, true, false, true).timeout  # TODO wait for sync not for timer
			DirAccess.copy_absolute("user://workdir/disk_%d.img" % id, save_dir + "/disk_%d.img" % id)

func restore(save_dir : String) -> void:
	var save_info = FAG_Utils.load_from_json_file(save_dir + SAVE_INFO_FILE)
	load_level(save_info['level'], save_dir)
	
	factory_builder.restore(FAG_Utils.load_from_json_file(save_dir + "/Factory.json"))
	circuit_simulator.restore(FAG_Utils.load_from_json_file(save_dir + "/Circuit.json"))

func close() -> void:
	await stop_simulations()
	factory_builder.close()
	circuit_simulator.close()
	FAG_TCPEcho.stop()
	if level_scene_node:
		remove_child(level_scene_node)
		level_scene_node.queue_free()
		level_scene_node = null
	_reset_stats()

func stop_simulations() -> void:
	print("--- stop simulation ---")
	if _circuit_simulation_ready_state != UNUSED:
		circuit_simulator.stop()
	for element in factory_builder.computer_control_blocks.values():
		element.get_child(0).stop()
	for element in factory_builder.computer_control_blocks.values():
		await element.get_child(0).wait_for_stop()
	print("--- simulation stopped ---")

func is_loaded() -> bool:
	return level_scene_node != null


### factory input/output signals

func get_signal_value(signal_name : String) -> float:
	var value1 = null
	if circuit_simulator.gdspice.get_simulation_state() & circuit_simulator.gdspice.WORKING_TYPE_STATE_MASK:
		var electric_signal = level_scene_node.control_block_output_signals[signal_name]
		if electric_signal in circuit_simulator.gdspice.used_nets:
			# NOTE: due to method of construction `used_nets` and `floating_nets` this causes the inability
			#       to get values ​​for internal factory nodes (not explicitly used in player's circuit)
			#       and (due to filtering by net name) causes also inability to get current signals
			#       use `circuit_simulator.gdspice.get_last_value()` directly in these cases
			value1 = circuit_simulator.gdspice.get_last_value(electric_signal)
	
	var value2 = null
	var computer_id = null
	for element in factory_builder.computer_control_blocks.values():
		var computer_system = element.get_child(0)
		computer_id = computer_system.computer_system_id
		if computer_system.is_running_and_ready() and signal_name in computer_system.output_names:
			# NOTE controlling this same signal by multiple computer system is not supported here
			value2 = computer_system.get_signal_value(signal_name, null)
	
	if value1 != null and value2 != null and value2 != "":
		value2 = float(value2)
		if not is_equal_approx(value1, value2):
			printerr("get_signal_value: electronic circuit vs computer system #0 conflicted ",
				value1, " vs ", value2
			)
			emergency_stop(
				"FACTORY_CIRCUT_COMPUTER_CONFLICT_ERROR_TITLE",
				"FACTORY_CIRCUT_COMPUTER_CONFLICT_ERROR_TEXT"
			)
			return 0
		else:
			#print("get_signal_value (electronic circuit / computer system #0) ", signal_name, " → ", value2)
			return value2
	elif value1 != null:
		#print("get_signal_value (electronic circuit)", signal_name, " → ", value1)
		return value1
	elif value2 != null and value2 != "":
		#print("get_signal_value (computer system #", computer_id, ") ", signal_name, " → ", value2)
		return float(value2)
	else:
		#print("get_signal_value (default) ", signal_name, " → ", 0)
		return 0

func set_signal_value(signal_name : String, value : float) -> void:
	#print("set_signal_value ", signal_name, " → ", value)
	circuit_simulator.gdspice.set_voltages_currents(level_scene_node.control_block_input_signals[signal_name], value)
	for element in factory_builder.computer_control_blocks.values():
		var computer_system = element.get_child(0)
		if computer_system.is_running_and_ready() and signal_name in computer_system.input_names:
			computer_system.set_signal_value(signal_name, value)


### start / stop / pause / visibility

func run_factory() -> void:
	if _factory_state & FACTORY_RUNNING:
		printerr("Factory already started")
		return
	
	_factory_state = FACTORY_RUNNING | ON_CHANGE
	factory_builder.ui.set_editor_enabled(false)
	_start_stop_hud_ui()
	
	if _stats.block_count_per_type.get("ElectronicControlBlock", 0) > 0:
		_circuit_simulation_ready_state = NOT_READY
		circuit_simulator.init_circuit()
		# NOTE: we ignore value returned by init_circuit (error list) and do not show UI error here
		#       because NO_GND is not an issue if circuit connect only input/output signals
	else:
		_circuit_simulation_ready_state = UNUSED
	
	# NOTE: computer system simulations are running during work in editor
	# (are start/stop while adding/removing blocks) so no need to start/restart here
	# but need check ready (to avoid start factory when computers are booting)
	_update_computer_systems_simulation_ready_state()
	
	_try_run_factory()

func _try_run_factory() -> void:
	print("_try_run_factory")
	if _circuit_simulation_ready_state != NOT_READY and _computer_systems_simulation_ready_state != NOT_READY:
		print(" starting")
		circuit_simulator.start(_circuit_simulation_ready_state == READY)
		_last_sleep_time = 0
		game_speed.set_value(_speed_before_stop_pause)
		factory_start.emit()
		await get_tree().create_timer(0.2, true, false, true).timeout
		_factory_state &= ~ON_CHANGE
		_start_stop_hud_ui()

func stop_factory() -> void:
	if not (_factory_state & FACTORY_RUNNING):
		printerr("Factory is not started")
		return
	
	_factory_state = FACTORY_STOP | ON_CHANGE
	_start_stop_hud_ui()
	circuit_simulator.stop()
	factory_builder.ui.set_editor_enabled(true)
	for node in products_root.get_children():
		node.queue_free()
	factory_stop.emit()
	await get_tree().create_timer(0.2, true, false, true).timeout
	_factory_state &= ~ON_CHANGE
	_start_stop_hud_ui()

func pause_factory():
	_speed_before_stop_pause = game_speed.get_value()
	game_speed.set_value(0.0)

func unpause_factory():
	game_speed.set_value(_speed_before_stop_pause)

func set_visibility(value : bool) -> void:
	factory_builder.call_deferred("set_visibility", value)
	ui.visible = value

func input_off():
	factory_builder.ui.input_allowed = false
	factory_builder.camera.disable_input()
	factory_builder.ui.update_cursor(false, true)

func input_on():
	factory_builder.ui.input_allowed = true
	factory_builder.ui.update_cursor(true, true)
	factory_builder.camera.enable_input()


### factory speed control

var _last_sleep_time := 0
func _on_circuit_simulation_too_slow(time_diff, time_game, time_simulation):
	var game_time_diff = time_game - _last_sleep_time
	var delay_ratio = -time_diff / game_time_diff
	var new_speed = game_speed.get_value() * (1 - delay_ratio)
	if new_speed < 0:
		new_speed = 0
	
	_last_sleep_time = time_game
	game_speed.set_value(new_speed)
	printerr("_on_simulation_too_slow ", time_diff , " → delay_ratio=", delay_ratio, " new_speed=", new_speed)

func _on_circuit_simulation_go_sleep(time_diff, time_game, time_simulation, cumulative_sleep_time):
	_last_sleep_time = time_game
	# TODO use sleep value to control how much the game speed can be increased ... + allow only small step speed increase
	#prints("_on_simulation_go_sleep", time_diff, time_game, time_simulation, cumulative_sleep_time)

func _on_game_speed_value_changed(value: float) -> void:
	if is_zero_approx(value):
		get_tree().paused = true
		%Pause.text = "FACTORY_UNPAUSE"
	else:
		get_tree().paused = false
		%Pause.text = "FACTORY_PAUSE"
	Engine.time_scale = value

func _on_start_stop_pressed() -> void:
	if _factory_state == FACTORY_STOP:
		_speed_before_stop_pause = 0.3
		run_factory()
	else:
		stop_factory()

func _on_pause_pressed() -> void:
	var curr_speed = game_speed.get_value()
	if curr_speed > 0:
		_speed_before_stop_pause = curr_speed
		game_speed.set_value(0.0)
	else:
		game_speed.set_value(_speed_before_stop_pause)

enum { FACTORY_RUNNING = 0b00001 , FACTORY_STOP = 0b00010, ON_CHANGE = 0b00100, EMERGENCY_STOP = 0b01000}

func _start_stop_hud_ui():
	print("_start_stop_hud_ui _factory_state=%x" % _factory_state)
	if _factory_state & FACTORY_STOP:
		%StartStop.text = tr("FACTORY_START")
		_speed_before_stop_pause = game_speed.get_value()
		game_speed.set_value(0.0)
		%StartStop.disabled = true
	if _factory_state & FACTORY_RUNNING:
		%StartStop.text = tr("FACTORY_STOP")
		%StartStop.disabled = true
		game_speed.set_value(_speed_before_stop_pause)
	
	if _factory_state & ON_CHANGE:
		%StartStop.disabled = true
		%GameSpeed/Slider.editable = false
		%Pause.disabled = true
	else:
		%StartStop.disabled = false
		%GameSpeed/Slider.editable = (_factory_state & FACTORY_RUNNING)
		%Pause.disabled = not (_factory_state & FACTORY_RUNNING)
	
	if _factory_state & EMERGENCY_STOP :
		_speed_before_stop_pause = 0.0
		game_speed.set_value(0.0)
		%GameSpeed/Slider.editable = false


### running / ready flags

var _factory_state
var _speed_before_stop_pause = 0.0

enum { UNUSED, NOT_READY, READY }

var _circuit_simulation_ready_state := UNUSED
func _on_circuit_simulation_ready_state() -> void:
	print("circuit simulation is ready")
	_circuit_simulation_ready_state = READY
	_try_run_factory()

var _computer_systems_simulation_ready_state := UNUSED
func _on_computer_systems_simulation_ready_state() -> void:
	_update_computer_systems_simulation_ready_state()
	_try_run_factory()

func  _update_computer_systems_simulation_ready_state() -> void:
	if len(factory_builder.computer_control_blocks) == 0:
		_computer_systems_simulation_ready_state = UNUSED
	else:
		var new_state = READY
		for element in factory_builder.computer_control_blocks.values():
			var computer_system = element.get_child(0)
			if not computer_system.is_running_and_ready():
				new_state = NOT_READY
				if not computer_system.computer_system_is_run_and_ready.is_connected(_on_computer_systems_simulation_ready_state):
					computer_system.computer_system_is_run_and_ready.connect(_on_computer_systems_simulation_ready_state, CONNECT_ONE_SHOT)
		_computer_systems_simulation_ready_state = new_state
	print("computer systems simulation ready state: ", _computer_systems_simulation_ready_state)


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
	emergency_stop(
		"FACTORY_ERROR_TITLE",
		"FACTORY_ERROR_TEXT"
	)

func emergency_stop(title : String, message : String):
	_factory_state = FACTORY_RUNNING | EMERGENCY_STOP
	circuit_simulator.gdspice.emergency_stop()
	_start_stop_hud_ui()
	FAG_WindowManager.hide_by_escape_all_windows(self)
	%Message_Title.text = tr(title)
	%Message_Text.text = tr(message)
	%Message.show()

func _on_errormsg_ok_pressed() -> void:
	%Message.hide()
	FAG_WindowManager.restore_hideen_by_escape()


### blocks and circuit elements counts and statistics

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
	var base_element = Grid2D_BaseElement.get_from_element(element)
	
	if not base_element.type in ["NET", "Meter"]:
		_stats.circuit_element_count += val
	
	var element_subtype = base_element.subtype
	_stats.circuit_element_count_per_type[element_subtype] = _stats.circuit_element_count_per_type.get(element_subtype, 0) + val
	
	if level_scene_node.circuit_element_count_updated(
		element_subtype, element,
		_stats.circuit_element_count_per_type[element_subtype],
		circuit_simulator.grid_editor.ui._elements_dict[element_subtype][1]
	):
		circuit_simulator.grid_editor.ui.reset_editor()
	
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
	
	circuit_simulator.grid_editor.ui.import_export_path = "user://circuits/"
	DirAccess.make_dir_recursive_absolute(circuit_simulator.grid_editor.ui.import_export_path)
	circuit_simulator.grid_editor.grid.gElements.on_element_add.connect(_update_circuit_element_count.bind(1))
	circuit_simulator.grid_editor.grid.gElements.on_element_remove.connect(_update_circuit_element_count.bind(-1))
	circuit_simulator.gdspice.simulation_is_ready_to_run.connect(_on_circuit_simulation_ready_state)
	circuit_simulator.gdspice.simulation_too_slow.connect(_on_circuit_simulation_too_slow)
	circuit_simulator.gdspice.simulation_go_sleep.connect(_on_circuit_simulation_go_sleep)
	circuit_simulator.overcurrent_protection.connect(_on_circuit_simulation_overcurrent)
	circuit_simulator.overvoltage_protection.connect(_on_circuit_simulation_overvoltage)
	circuit_simulator.simulation_error.connect(_on_simulation_error)
	
	_reset_stats()


### misc / utils

func validate_product(node : RigidBody3D):
	var status = level_scene_node.validate_product(node)
	if status < 0:
		_stats.time = circuit_simulator.gdspice.get_raw_time_game()
		_stats.status = "fail"
		emergency_stop(
			"FACTORY_PRODUCT_FAILURE_TITLE",
			"FACTORY_PRODUCT_FAILURE_TEXT"
		)
	elif status > 0:
		_stats.time = circuit_simulator.gdspice.get_raw_time_game()
		_stats.status = "success"
		var game_progress = FAG_Utils.load_from_json_file(GAME_PROGRESS_SAVE)
		game_progress.unlocked_levels[level_scene_node.level_id] = _stats
		print(level_scene_node.unlocks_levels)
		for lid in level_scene_node.unlocks_levels:
			print(lid)
			if not lid in game_progress.unlocked_levels:
				game_progress.unlocked_levels[lid] = {}
		FAG_Utils.write_to_json_file(GAME_PROGRESS_SAVE, game_progress)
		emergency_stop(
			"FACTORY_PRODUCT_SUCCESS_TITLE",
			tr("FACTORY_PRODUCT_SUCCESS_TEXT_%fTIME") % _stats.time
		)

func _on_show_task_info() -> void:
	get_tree().current_scene.get_node("%Manual").show_info(level_scene_node, GAME_PROGRESS_SAVE)
