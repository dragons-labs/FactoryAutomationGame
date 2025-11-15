# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT


extends Node

@onready var game_speed := %GameSpeed
@onready var factory_builder := $FactoryBuilder
@onready var circuit_simulator = factory_builder.circuit_simulator
@onready var objects_root := $ObjectsRoot
@onready var user_blocks_root := $UserBlocksRoot
@onready var ui := $FactoryUI

signal factory_start()
signal factory_process(time : float, delta_time : float)
signal factory_stop()

var level_scene_node : Node3D

const LEVELS_DIR := "res://Levels/"
const GAME_PROGRESS_SAVE := "user://game_progress.json"
const SAVE_INFO_FILE := "/save_info.json"

var _pause_count = 0
func _physics_process(delta):
	if not _factory_state & FACTORY_RUNNING or _factory_state & EMERGENCY_STOP:
		return
	
	# if electronic circuit simulation is used then check if it's "on time" ... if it's delayed then pause 3d factory processing
	if _circuit_simulation_ready_state == READY:
		if circuit_simulator.try_step(_factory_time):
			if not _factory_simulation_on_time:
				_factory_simulation_on_time = true
				get_tree().paused = _factory_paused
				prints("unpause after emergency pause", _pause_count, _factory_time, circuit_simulator.gdspice.get_time_game(), circuit_simulator.gdspice.get_time_simulation())
			_pause_count = 0
		else:
			if _factory_simulation_on_time:
				_factory_simulation_on_time = false
				get_tree().paused = true
				prints("emergency pause", _pause_count, _factory_time, circuit_simulator.gdspice.get_time_game(), circuit_simulator.gdspice.get_time_simulation())
				# TODO show UI special-pause message like "Factory simulation in progress ... please wait."
			_pause_count += 1
			if _pause_count % 60 == 0:
				prints(_pause_count, _factory_time, circuit_simulator.gdspice.get_time_game(), circuit_simulator.gdspice.get_time_simulation())
			return
	
	# do not update time while game is pause
	# (the previous code must be processed also during pause - for unpausing)
	if get_tree().paused:
		return
	
	_factory_time = _factory_time + delta
	# NOTE: delta value is scaled by current Engine.time_scale (set from _factory_speed)
	#       but it does NOT reflect game pause state
	
	circuit_simulator.try_step(_factory_time) # electronic circuit simulation will be processing in background
	factory_process.emit(_factory_time, delta) # all factory_process signal's observers will be processed before this function exit
	for element in factory_builder.computer_control_blocks.values():
		element.get_child(0).time_step(_factory_time) # update factory time in computer simulation (this can cause finished some factory_sleep)
		# NOTE: updating computer outputs will be done via _physics_process in ComputerSystemSimulator, called before this function (negative process_physics_priority in ComputerSystemSimulator)
	
	for i in range(len(_factory_timers)):
		if _factory_timers[i] and _factory_timers[i].update(delta):
			_factory_timers[i] = null


### load / save / restore

func load_level(level_id : String, save_dir := "") -> void:
	level_scene_node = load(LEVELS_DIR + level_id + ".tscn").instantiate()
	level_scene_node.name = "FactoryLevel"
	level_scene_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# set circuit_simulator parameters (other parameters are set as arguments in circuit_simulator.init_circuit() call
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
			
		factory_builder.computer_systems_configuration = computer_config
	factory_builder.defualt_computer_system_id = level_scene_node.defualt_computer_system_id
	
	# run register_factory_signals on static blocks
	for element in level_scene_node.get_node("FactoryBlocks").get_children():
		var info_obj = factory_builder.get_info_from_block(element)
		if "factory_signals" in info_obj:
			factory_builder.register_factory_signals(
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
	FAG_Utils.write_to_json_file(save_dir + "/Circuit.json", circuit_simulator.serialise())
	
	if factory_builder.computer_control_blocks:
		FAG_Utils.remove_dir_recursive(save_dir + "/private_fs")
		FAG_Utils.copy_dir_absolute("user://workdir/private_fs", save_dir + "/private_fs")
		for id in factory_builder.computer_control_blocks:
			factory_builder.computer_control_blocks[id].get_child(0).send_message_via_msg_bus("request_sync") # TODO request also pause ???
			await FAG_Utils.real_time_wait(0.3)  # TODO wait for sync not for timer
			DirAccess.copy_absolute("user://workdir/disk_%d.img" % id, save_dir + "/disk_%d.img" % id)

func restore(save_dir : String) -> void:
	var save_info = FAG_Utils.load_from_json_file(save_dir + SAVE_INFO_FILE)
	load_level(save_info['level'], save_dir)
	
	factory_builder.restore(FAG_Utils.load_from_json_file(save_dir + "/Factory.json"))
	circuit_simulator.restore(FAG_Utils.load_from_json_file(save_dir + "/Circuit.json"))

func close() -> void:
	_factory_timers.clear()
	await stop_simulations()
	factory_builder.close()
	circuit_simulator.close()
	if level_scene_node:
		_factory_state = FACTORY_STOP | ON_CHANGE
		remove_child(level_scene_node)
		level_scene_node.queue_free()
		level_scene_node = null
	for node in objects_root.get_children():
		node.queue_free()
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
		var electric_signal = factory_builder.outputs_from_circuit_to_factory[signal_name][0]
		if electric_signal in circuit_simulator.gdspice.used_nets:
			# NOTE: due to method of construction `used_nets` and `floating_nets` this causes the inability
			#       to get values ​​for internal factory nodes (not explicitly used in player's circuit)
			#       and (due to filtering by net name) causes also inability to get current signals
			#       use `circuit_simulator.gdspice.get_last_value()` directly in these cases
			value1 = circuit_simulator.gdspice.get_last_value(electric_signal)
	
	var value2 = null
	for element in factory_builder.computer_control_blocks.values():
		var computer_system = element.get_child(0)
		if computer_system.is_running_and_ready() and signal_name in computer_system.computer_output_names:
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
		#print("get_signal_value (computer system #", computer_system.computer_system_id, ") ", signal_name, " → ", value2)
		return float(value2)
	else:
		#print("get_signal_value (default) ", signal_name, " → ", 0)
		return 0

func set_signal_value(signal_name : String, value : float) -> void:
	#print("set_signal_value ", signal_name, " → ", value)
	circuit_simulator.gdspice.set_voltages_currents(factory_builder.input_to_circuit_from_factory[signal_name][1], value)
	for element in factory_builder.computer_control_blocks.values():
		var computer_system = element.get_child(0)
		if computer_system.is_running_and_ready() and signal_name in computer_system.computer_input_names:
			computer_system.set_signal_value(signal_name, value)


### factory timers

class FactoryTimer:
	var paused := false
	var _period : float
	var _time_left : float
	
	signal timeout(_time_left: float)
	
	func _init(time : float, one_shot := true):
		_time_left = time
		if one_shot:
			_period = 0
		else:
			_period = time
	
	func reset(time : float) -> void:
		_time_left = time
		if _period:
			_period = time
	
	func update(delta : float) -> bool:
		if paused:
			return false
		_time_left -= delta
		if _time_left <= 0:
			timeout.emit(_time_left)
			if _period:
				_time_left += _period
			else:
				return true # timer to remove
		return false # timer to keep

func create_timer(time : float, one_shot := true):
	var timer = FactoryTimer.new(time, one_shot)
	for i in range(len(_factory_timers)):
		if not _factory_timers[i]:
			_factory_timers[i] = timer
			return timer
	_factory_timers.append(timer)
	return timer


### start / stop / pause / visibility

func run_factory() -> void:
	if _factory_state & FACTORY_RUNNING:
		printerr("Factory already started")
		return
	
	_factory_state = FACTORY_RUNNING | ON_CHANGE
	_factory_paused = false
	_factory_time = 0
	_factory_speed = game_speed.get_value()
	Engine.call_deferred("set_time_scale", _factory_speed)
	factory_builder.ui.set_editor_enabled(false)
	_start_stop_hud_ui()
	
	if _stats.block_count_per_type.get("ElectronicControlBlock", 0) > 0:
		_circuit_simulation_ready_state = NOT_READY
		circuit_simulator.init_circuit(
			factory_builder.input_to_circuit_from_factory.values(),
			factory_builder.outputs_from_circuit_to_factory.values(),
			factory_builder.external_circuit_entries
		)
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
		if _circuit_simulation_ready_state == READY:
			circuit_simulator.start(
				level_scene_node.circuit_simulation_time_step,
				level_scene_node.circuit_simulation_max_time
			)
		_factory_simulation_on_time = true
		unpause_factory()
		factory_start.emit()
		await FAG_Utils.real_time_wait(0.2)
		_factory_state &= ~ON_CHANGE
		_start_stop_hud_ui()

func stop_factory() -> void:
	if not (_factory_state & FACTORY_RUNNING):
		printerr("Factory is not started")
		return
	
	_factory_state = FACTORY_STOP | ON_CHANGE
	_start_stop_hud_ui()
	_factory_timers.clear()
	circuit_simulator.stop()
	for element in factory_builder.computer_control_blocks.values():
		element.get_child(0).time_step(-1)
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
	if _factory_simulation_on_time:
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


### running / ready flags

var _factory_state
var _factory_simulation_on_time
var _factory_time
var _factory_timers = []
var _factory_paused
var _factory_speed

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
	if _factory_state & EMERGENCY_STOP:
		return
	_factory_state = FACTORY_RUNNING | EMERGENCY_STOP
	_factory_paused = true
	get_tree().paused = true
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
		base_element.get_node("NetNames").netnames = factory_builder.netnames
	
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

var _console_read_set

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
	circuit_simulator.overcurrent_protection.connect(_on_circuit_simulation_overcurrent)
	circuit_simulator.overvoltage_protection.connect(_on_circuit_simulation_overvoltage)
	circuit_simulator.simulation_error.connect(_on_simulation_error)
	
	_reset_stats()
	
	_console_read_set = FAG_ConsoleReadSet.new(self, "factory", ["check_win_loss_conditions"])
	
	LimboConsole.register_command(_factory_producer, "factory producer", "Perform operation on all (default) or selected (last argument) producers.")
	LimboConsole.add_argument_autocomplete_source("factory producer", 0, func(): return ["start", "stop", "step", "set_time"])
	
	LimboConsole.register_command(_factory_clear, "factory clear", "Remove all products")
	
	LimboConsole.register_command(pause_factory, "pause", "Pause")
	LimboConsole.register_command(unpause_factory, "unpause", "Unpause")


### console commands

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
		_stats.time = _factory_time
		_stats.status = "fail"
		emergency_stop(
			"FACTORY_PRODUCT_FAILURE_TITLE",
			"FACTORY_PRODUCT_FAILURE_TEXT"
		)
	elif status > 0:
		_stats.time = _factory_time
		_stats.status = "success"
		var game_progress = FAG_Utils.load_from_json_file(GAME_PROGRESS_SAVE)
		game_progress.finished_levels[level_scene_node.level_id] = _stats
		FAG_Utils.write_to_json_file(GAME_PROGRESS_SAVE, game_progress)
		emergency_stop(
			"FACTORY_PRODUCT_SUCCESS_TITLE",
			tr("FACTORY_PRODUCT_SUCCESS_TEXT_%fTIME") % _stats.time
		)

func _on_show_task_info() -> void:
	FAG_Settings.get_root_subnode("%Manual").show_info(level_scene_node, GAME_PROGRESS_SAVE)
