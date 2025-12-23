# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node

#region   input/output signals processing (get/set value)

func get_signal_value(signal_name : String, default : Variant = 0) -> Variant: # return float or default (e.g. null)
	var info = _get_signal_value(signal_name, default)
	# print(_signal_value_with_info(signal_name, info))
	if info[1] == CONFLICT:
		conflict_error.emit(info)
	return info[0]

func _get_signal_value(signal_name : String, default : Variant = 0) -> Array:
	var value1 = null
	if signal_name in outputs_from_circuit_to_factory and circuit_simulator.gdspice.get_simulation_state() & circuit_simulator.gdspice.WORKING_TYPE_STATE_MASK:
		var electric_signal = outputs_from_circuit_to_factory[signal_name][0]
		if electric_signal in circuit_simulator.gdspice.used_nets:
			# NOTE: due to method of construction `used_nets` and `floating_nets` this causes the inability
			#       to get values ​​for internal factory nodes (added to gdspice, but not explicitly used in player's circuit)
			#       and (due to filtering by net name) causes also inability to get current signals
			#       use `circuit_simulator.gdspice.get_last_value()` directly in these cases
			value1 = circuit_simulator.gdspice.get_last_value(electric_signal)
	
	var value2 = null
	var value2_source_id = null
	for computer_id in computer_control_blocks:
		var computer_system = computer_control_blocks[computer_id].get_child(0)
		if computer_system.is_running_and_ready() and signal_name in computer_system.computer_output_names:
			# NOTE controlling this same signal by multiple computer system is not supported here
			var new_value = computer_system.get_signal_value(signal_name, null)
			if new_value != null:
				if value2 == null:
					value2 = float(new_value)
					value2_source_id = computer_id
				elif not is_equal_approx(float(new_value), value2):
					new_value = float(new_value)
					return [(value2+new_value)/2, CONFLICT, value2_source_id, new_value, value2, computer_id]
	
	if value2 == null:
		value2 = internal_signals_values.get(signal_name)
		value2_source_id = "internal"
	
	if value1 != null and value2 != null:
		if not is_equal_approx(value1, value2):
			return [(value1+value2)/2, CONFLICT, value2_source_id, value1, value2]
		else:
			return [value2, COMPUTER, value2_source_id]
	elif value1 != null:
		return [value1, CIRCUIT]
	elif value2 != null:
		return [value2, COMPUTER, value2_source_id]
	else:
		return [default, NONE]

func set_signal_value(signal_name : String, value : float) -> void:
	#print("set_signal_value ", signal_name, " → ", value)
	if signal_name in input_to_circuit_from_factory:
		circuit_simulator.gdspice.set_voltages_currents(input_to_circuit_from_factory[signal_name][1], value)
		# NOTE: new value will be used in the circuit simulation immediately, but due to the synchronization of circuit simulation and the game physics
		# NOTE: it will be approximately in the range from `simulation_time - 0.2 * current_frame_duration` to `simulation_time + 1.2 * current_frame_duration`
		# NOTE: this depends on the error in estimating the end time of the previous and current frame (`time_frame_estimation_multiplier` setting)
		# NOTE: and the circuit simulation step (`circuit_simulation_time_step` argument of `async_start`)
	for element in computer_control_blocks.values():
		var computer_system = element.get_child(0)
		if computer_system.is_running_and_ready() and signal_name in computer_system.computer_input_names:
			computer_system.set_signal_value(signal_name, value)
			# NOTE: new value will be used during the simulation of the current frame
			# NOTE: the delay with which it will be entered depends on the load of the computer system
			# NOTE: and the implementation of the user program reading these values
	internal_signals_values[signal_name] = value

#endregion


#region   start / tick / stop / close

func async_start(use_circuit_simulation, circuit_simulation_time_step, circuit_simulation_max_time) -> bool:
	if _running_state != NOT_RUNNING:
		printerr("Start aborted - running_state != NOT_RUNNING (running_state == ", _running_state, ")")
		return false
	_running_state = STARTING
	
	print_rich("[color=dark_cyan][b]Starting factory control system ...[/b][/color]")
	simulation_time = 0
	estimated_next_simulation_time = 0.15
	simulation_on_time = true
	internal_signals_values.clear()
	
	# all computer's systems need be in READY state (if used)
	if len(computer_control_blocks) != 0:
		# computers are start while adding blocks
		# but we need check if they are ready
		# (to avoid start factory when computers are booting)
		_update_computer_systems_simulation_ready_state()
		
		if not await _async_wait_for_ready(COMPUTER, "computer"): return false
	else:
		_system_state[COMPUTER] = UNUSED
	
	# if electronic circuit simulation is used need be init and in READY state
	if use_circuit_simulation:
		if _system_state[CIRCUIT] == INIT_FAIL:
			printerr("Start aborted - circuit simulation in INIT_FAIL state")
			_running_state = START_CANCELED_ACK
			return false
		
		_system_state[CIRCUIT] = NOT_READY
		circuit_simulator.init_circuit(
			input_to_circuit_from_factory.values(),
			outputs_from_circuit_to_factory.values(),
			external_circuit_entries
		)
		_circuit_simulation_time_step = circuit_simulation_time_step
		_circuit_simulation_max_time = circuit_simulation_max_time
		# NOTE: we ignore value returned by init_circuit (error list) and do not show UI error here
		#       because NO_GND is not an issue if circuit connect only input/output signals
		
		if not await _async_wait_for_ready(CIRCUIT, "circuit"): return false
	elif _system_state[CIRCUIT] != INIT_FAIL:
		_system_state[CIRCUIT] = UNUSED
	
	# check if start was not canceled while we were waiting for READY state
	if _running_state == START_CANCELED:
		_running_state = START_CANCELED_ACK
		return false
	
	# if electronic circuit simulation is used need be started
	if _system_state[CIRCUIT] == READY:
		circuit_simulator.start( _circuit_simulation_time_step, _circuit_simulation_max_time )
		circuit_simulator.gdspice.set_time_game(estimated_next_simulation_time)
	
	# NOTE: computer system simulations are running during work in editor
	# (are start/stop while adding/removing blocks) so no need to start/restart here
	
	print_rich("[color=dark_cyan][b]Factory control system is running.[/b][/color]")
	_running_state = RUNNING
	running.emit()
	return true

func tick(delta: float, paused : bool) -> void:
	# do not update time while game is paused
	if not get_tree().paused:
		simulation_time += delta
		# NOTE: delta value is scaled by current Engine.time_scale (set from _factory_speed)
		#       but it does NOT reflect game pause state
	
	# if electronic circuit simulation is used then check its state and check if it's "on time"
	if _system_state[CIRCUIT] == READY:
		# check simulation errors
		var circuit_simulation_state = circuit_simulator.check_state()
		
		if circuit_simulation_state == GdSpice.RUNNING:
			# if electronic circuit simulation is delayed then pause 3d factory processing
			var current_simulation_time = circuit_simulator.gdspice.get_time_simulation()
			if (current_simulation_time >= min(simulation_time, estimated_next_simulation_time)):
				# on time
				if not simulation_on_time:
					simulation_on_time = true
					get_tree().paused = paused
					# prints("unpause after emergency pause", _pause_count, simulation_time, circuit_simulator.gdspice.get_time_game(), current_simulation_time)
				_pause_count = 0
			else:
				# not on time
				if simulation_on_time:
					simulation_on_time = false
					get_tree().paused = true
					# prints("emergency pause", _pause_count, simulation_time, circuit_simulator.gdspice.get_time_game(), current_simulation_time)
					# TODO show UI special-pause message like "Factory simulation in progress ... please wait."
					circuit_simulator.gdspice.set_time_game(simulation_time)
				_pause_count += 1
				if _pause_count % 30 == 0:
					prints("on emergency pause", _pause_count, simulation_time, circuit_simulator.gdspice.get_time_game(), current_simulation_time)
				return
	
	# do not process factory control logic if game is paused
	# (the previous code must be processed also during pause - for unpausing)
	if get_tree().paused:
		return
	
	# update circuit simulator UI measurements
	# it called here to ensure calls with always a greater value of simulation_time and with relatively equal intervals in simulation_time
	circuit_simulator.gdspice.update_measurements(simulation_time)
	
	# set estimated frame end time as target for electronic circuit simulation
	estimated_next_simulation_time = simulation_time + delta * time_frame_estimation_multiplier
	circuit_simulator.gdspice.set_time_game(estimated_next_simulation_time)
	# electronic circuit simulation will be processing in background
	
	# emit `factory_tick` signal
	# NOTE: all factory_tick signal's observers will be called (and processed if they are not async) before this function exit
	factory_tick.emit(simulation_time, delta)
	
	# update factory time in computer simulation (this can cause finished some factory_sleep)
	# NOTE: updating computer outputs will be done via _physics_process in ComputerSystemSimulator, called before this function (negative process_physics_priority in ComputerSystemSimulator)
	for element in computer_control_blocks.values():
		element.get_child(0).time_step(simulation_time)
	
	for i in range(len(_timers)):
		if _timers[i] and _timers[i].update(delta):
			_timers[i] = null

func async_stop() -> void:
	print_rich("[color=dark_cyan][b]Stopping factory control system ...[/b][/color]")
	
	# if stop requested while starting then wait for break starting function before continue stopping
	if _running_state == STARTING or _running_state == START_CANCELED:
		_running_state = START_CANCELED
		print("Wait for starting canceled acknowledgement")
		while _running_state == START_CANCELED:
			await FAG_Utils.real_time_wait(0.025)
	
	_timers.clear()
	circuit_simulator.stop()
	for element in computer_control_blocks.values():
		element.get_child(0).time_step(-1)
	
	_running_state = NOT_RUNNING
	print_rich("[color=dark_cyan][b]Factory control system is stopped.[/b][/color]")

func async_close() -> void:
	await async_stop()
	
	print_rich("[color=dark_cyan][b]Closing factory control system ...[/b][/color]")
	for element in computer_control_blocks.values():
		@warning_ignore("missing_await") element.get_child(0).async_stop()
	for element in computer_control_blocks.values():
		await element.get_child(0).async_wait_for_stop()
	for echo_service in computer_networks.values():
		echo_service.stop()
	
	_timers.clear()
	computer_control_blocks.clear()
	input_to_circuit_from_factory.clear()
	outputs_from_circuit_to_factory.clear()
	external_circuit_entries.clear()
	netnames.clear()
	
	circuit_simulator.close()
	print_rich("[color=dark_cyan][b]Factory control system is closed.[/b][/color]")

#endregion


#region   input/output signals register / unregister

## Register signals for circuit and computer control blocks
##
## Takes arguments:
##  - inputs_from_factory:
##     control blocks inputs signals (from factory)
##     as 2 or 3 or 4 elements arrays: [net_name, voltage_source_name, constant, internal_resistance]
##     if constant is specified (and is not "external") then signal is used only for circuit simulation as constant voltage source
##     with constant string value as voltage source definition (e.g. "dc 3.3" -> 3.3 V DC)
##     NOTE: circuit element name (voltage_source_name) should be lowercase,
##           because ngspice using lowercase element name to ask for voltage value
##     example: {
##         "Vcc" : ["Vcc", "Vcc", "dc 3.3"],
##         "signal_from_factory" : ["signal_from_factory_@in", "v_signal_from_factory"],
##         "weak_signal_from_factory" : ["signal_from_factory_@in", "v_signal_from_factory", "external", "100k"],
##     }
##     NOTE: internal resistance (weak output) is used only for circuit simulation, for computer block outputs are always strong
##  - outputs_to_factory:
##     control blocks output signals (to factory)
##     as 1 or 2 elements arrays: [net_name, resistor_specification]
##     if resistor_specification is not specified (or is null) then connected via high resistance to GND
##     example: {
##         "high_z_input" : ["high_z_input@out"],
##         "sink_input_sample" :["sink_input_sample", "Vcc 10k"],
##         "source_input_sample": ["source_input_sample", "GND 10k"]
##     }
##     NOTE: resistor specification (sink/source inputs) is used only for circuit simulation, for computer block inputs are always high impedance
##  - circuit_entries:
##     other factory circuit elements
##     {0} will be replaced by "prefix for signal names" (see next argument)
##     example: [
##         "Rsample_{0}_1 block_{0}_internal_signal factory_signal 10k"
##     ]
##  - name_prefix:
##     prefix for signal names
##     will be added at begin of signals, nets and after `v_` (or `v`) in voltage_source_name
##     non-empty for per-block signals, empty for level-scope signals to avoid add it for nets like `Vcc`
##  - computer_id:
##     computer id to register signals
##     null (default) to register in all computers
func register_factory_signals(inputs_from_factory : Dictionary, outputs_to_factory : Dictionary, circuit_entries : Array, name_prefix : String, computer_id : Variant = null):
	if name_prefix:
		name_prefix += "_"
	
	# control blocks inputs (from factory)
	for signal_name in inputs_from_factory:
		var signal_name2 = name_prefix + signal_name
		# add signal to common dictionary using prefix
		input_to_circuit_from_factory[signal_name2] = inputs_from_factory[signal_name].duplicate()
		# add prefix to netname
		input_to_circuit_from_factory[signal_name2][0] = name_prefix + input_to_circuit_from_factory[signal_name2][0]
		# add netname to netnames list
		netnames.append(input_to_circuit_from_factory[signal_name2][0])
		# add prefix to voltage_source_name
		var voltage_source_name = input_to_circuit_from_factory[signal_name2][1]
		var split_position = 2 if voltage_source_name[1] == "_" else 1
		input_to_circuit_from_factory[signal_name2][1] = voltage_source_name.substr(0, split_position) + name_prefix + voltage_source_name.substr(split_position)
		# if signal is external controlled add it to computers system configuration
		if FAG_Utils.array_get(input_to_circuit_from_factory[signal_name2], 2) in [null, "external"]:
			for cid in computer_systems_configuration if computer_id == null else {computer_id: null}:
				computer_systems_configuration[cid].computer_input_names.append(signal_name2)
				# if computer is running register signal in it via message bus
				if cid in computer_control_blocks:
					computer_control_blocks[cid].get_child(0).set_signal_value(signal_name2, 0)
	
	# control blocks outputs (to factory)
	for signal_name in outputs_to_factory:
		var signal_name2 = name_prefix + signal_name
		# add signal to common dictionary and computer outputs list using prefix
		outputs_from_circuit_to_factory[signal_name2] = outputs_to_factory[signal_name].duplicate()
		# add prefix to netname
		outputs_from_circuit_to_factory[signal_name2][0] = name_prefix + outputs_from_circuit_to_factory[signal_name2][0]
		# add netname to netnames list
		netnames.append(outputs_from_circuit_to_factory[signal_name2][0])
		# add signal to computers system configuration
		for cid in computer_systems_configuration if computer_id == null else {computer_id: null}:
			computer_systems_configuration[cid].computer_output_names.append(signal_name2)
			# if computer is running register signal in it via message bus
			if cid in computer_control_blocks:
				computer_control_blocks[cid].get_child(0).add_computer_output(signal_name2)
	
	# extra circuit entries
	for circuit_entry in circuit_entries:
		external_circuit_entries.append(circuit_entry.format([name_prefix]))

func unregister_factory_signals(inputs_from_factory : Dictionary, outputs_to_factory : Dictionary, circuit_entries : Array, name_prefix : String, computer_id : Variant = null):
	if name_prefix:
		name_prefix += "_"
	
	for signal_name in inputs_from_factory:
		var signal_name2 = name_prefix + signal_name
		netnames.erase(input_to_circuit_from_factory[signal_name2][0])
		if signal_name2 in input_to_circuit_from_factory and FAG_Utils.array_get(input_to_circuit_from_factory[signal_name2], 2) in [null, "external"]:
			for cid in computer_systems_configuration if computer_id == null else {computer_id: null}:
				computer_systems_configuration[cid].computer_input_names.erase(signal_name2)
				if cid in computer_control_blocks:
					computer_control_blocks[cid].get_child(0).remove_computer_input(signal_name2)
		input_to_circuit_from_factory.erase(signal_name2)
	
	for signal_name in outputs_to_factory:
		var signal_name2 = name_prefix + signal_name
		netnames.erase(outputs_from_circuit_to_factory[signal_name2][0])
		outputs_from_circuit_to_factory.erase(signal_name2)
		for cid in computer_systems_configuration if computer_id == null else {computer_id: null}:
			computer_systems_configuration[cid].computer_output_names.erase(signal_name2)
			if cid in computer_control_blocks:
				computer_control_blocks[cid].get_child(0).remove_computer_output(signal_name2)
	
	for circuit_entry in circuit_entries:
		external_circuit_entries.erase(circuit_entry.format([name_prefix]))

#endregion


#region   setup / unsetup computers

func setup_computer_control_blocks(element : Node3D) -> void:
	# get computer_id
	var computer_id = null
	if  element.has_meta("computer_id"):
		computer_id = element.get_meta("computer_id")
		if computer_id in computer_control_blocks:
			printerr("Computer ID ", computer_id, " read from block meta already in use ... generating new one")
			computer_id = null
	if computer_id == null:
		computer_id = 0
		while computer_id in computer_control_blocks:
			computer_id += 1
	
	# get or create ui window for computer system with this id
	var computer_ui_window_name = "%%ComputerSystemSimulatorWindow_%d" % computer_id
	var computer_ui_window_node = get_node_or_null (computer_ui_window_name)
	if not computer_ui_window_node:
		print("Create window for computer_id=", computer_id)
		var template = %ComputerSystemSimulatorWindow
		computer_ui_window_node = template.duplicate()
		if computer_id is int:
			computer_ui_window_node.title = tr("COMPUTER_SYSTEM_%s_WINDOW_TITLE") % ("#" + str(computer_id))
		else:
			computer_ui_window_node.title = tr("COMPUTER_SYSTEM_%s_WINDOW_TITLE") % str(computer_id)
		template.get_parent().add_child(computer_ui_window_node)
		computer_ui_window_node.name = computer_ui_window_name
	
	# store id in meta, add ui window to computer simulation windows list
	element.set_meta("computer_id", computer_id)
	computer_control_blocks[computer_id] = computer_ui_window_node
	
	# and start computer simulation
	var computer_system_simulator = computer_ui_window_node.get_child(0)
	if computer_id in computer_systems_configuration:
		
		var nedwork_id = computer_systems_configuration[computer_id].get("nedwork_id", 0)
		if not nedwork_id in computer_networks:
			computer_networks[nedwork_id] = load("res://Utils/TCPEcho.gd").new()
			add_child(computer_networks[nedwork_id])
		computer_systems_configuration[computer_id].tcp_echo_service_port = computer_networks[nedwork_id].get_port()
		
		computer_system_simulator.configure(computer_id, computer_systems_configuration[computer_id])
		computer_system_simulator.start()
	else:
		printerr("WARNING: starting computer system ", computer_id, " without configuration info - this system will be stateless.")
		computer_system_simulator.computer_system_id = computer_id
		computer_system_simulator.start()
	
	_update_computer_systems_simulation_ready_state()

func remove_computer_control_blocks(element : Node3D) -> void:
	var computer_id = element.get_meta("computer_id")
	FAG_WindowManager.set_windows_visibility_recursive(computer_control_blocks[computer_id], false)
	computer_control_blocks[computer_id].get_child(0).async_stop()
	computer_control_blocks.erase(computer_id)

#endregion


#region   factory timers

class _Timer:
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
	var timer = _Timer.new(time, one_shot)
	for i in range(len(_timers)):
		if not _timers[i]:
			_timers[i] = timer
			return timer
	_timers.append(timer)
	return timer

#endregion


#region   ready check private callbacks and helpers

func _async_wait_for_ready(subsystem : int, name : String):
	while true:
		if _running_state == START_CANCELED:
			_running_state = START_CANCELED_ACK
			return false
		if _system_state[subsystem] == FAIL:
			printerr("Start aborted - " + name + " system simulation in FAIL state")
			_running_state = START_CANCELED_ACK
			return false
		if _system_state[subsystem] == READY:
			return true
		await FAG_Utils.real_time_wait(0.025)

func _on_electronics_simulator_init_error() -> void:
	_system_state[CIRCUIT] = INIT_FAIL
	simulation_error.emit("circuit simulation init error")

func _on_simulation_error() -> void:
	_system_state[CIRCUIT] = FAIL
	simulation_error.emit("circuit simulation runtime error")

func _on_circuit_simulation_ready_state() -> void:
	print("circuit simulation is ready")
	_system_state[CIRCUIT] = READY

func _on_computer_system_simulator_crash(computer_system_id: Variant, after_ready: bool) -> void:
	_system_state[COMPUTER] = FAIL
	simulation_error.emit("computer simulation crash error")

func  _update_computer_systems_simulation_ready_state() -> void:
	if len(computer_control_blocks) == 0:
		_system_state[COMPUTER] = UNUSED
	else:
		var new_state = READY
		for element in computer_control_blocks.values():
			var computer_system = element.get_child(0)
			if not computer_system.is_running():
				new_state = FAIL
				break
			if not computer_system.is_running_and_ready():
				new_state = NOT_READY
				if not computer_system.computer_system_is_run_and_ready.is_connected(_update_computer_systems_simulation_ready_state):
					computer_system.computer_system_is_run_and_ready.connect(_update_computer_systems_simulation_ready_state, CONNECT_ONE_SHOT)
		_system_state[COMPUTER] = new_state
	print("computer systems simulation ready state: ", _system_state[COMPUTER])

#endregion


#region   console commands

func _list_all_signals() -> void:
	LimboConsole.info("factory blocks → controls:")
	for signal_name in input_to_circuit_from_factory:
		if FAG_Utils.array_get(input_to_circuit_from_factory[signal_name], 2) in [null, "external"]:
			LimboConsole.info("  * " + signal_name + " → " + str(internal_signals_values.get(signal_name)))
			# can't get external via circuit_simulator.gdspice.get_last_value() ... so use internal_signals_values here
	
	LimboConsole.info("controls → factory blocks:")
	for signal_name in outputs_from_circuit_to_factory:
		LimboConsole.info("  * " + _signal_value_with_info(signal_name, _get_signal_value(signal_name)))
	
	LimboConsole.info("additional signals:")
	LimboConsole.info("  * factory:")
	for signal_name in internal_signals_values:
		if not signal_name in input_to_circuit_from_factory:
			LimboConsole.info("    " + signal_name + " → " + str(internal_signals_values[signal_name]))
	
	for computer_id in computer_control_blocks:
		var computer_system = computer_control_blocks[computer_id].get_child(0)
		LimboConsole.info("  * computer system #" + str(computer_id) +":")
		for signal_name in computer_system._output_values:
			if not signal_name in outputs_from_circuit_to_factory:
				LimboConsole.info("    * " + signal_name + " → " + str(computer_system._output_values[signal_name]))
	
	LimboConsole.info("factory internal signals for electronics systems:")
	for signal_name in input_to_circuit_from_factory:
		if not FAG_Utils.array_get(input_to_circuit_from_factory[signal_name], 2) in [null, "external"]:
			LimboConsole.info("  * " + signal_name + " → " + str(circuit_simulator.gdspice.get_last_value(signal_name)))

func _signal_value_with_info(signal_name : String, info : Array) -> String:
	var ret = signal_name + " → " + str(info[0])
	match info[1]:
		CIRCUIT:
			ret += " (from electronic circuit)"
		COMPUTER:
			ret += " (from computer system #" + str(info[2]) + ")"
		NONE:
			ret += " (default value)"
		CONFLICT:
			ret += " (electronic circuit / computer system #" + str(info[2]) + " conflict: "  + str(info[3]) + " vs " + str(info[4]) + ")"
	return ret

#endregion


#region   initialization, variables and signals

func _ready() -> void:
	circuit_simulator.gdspice.simulation_is_ready_to_run.connect(_on_circuit_simulation_ready_state)
	
	_console_read_set = FAG_Utils.ConsoleReadSet.new(self, "control", [])
	LimboConsole.register_command(_list_all_signals, "control list", "List all signals")
	LimboConsole.register_command(set_signal_value, "control set_signal", "Set signal value")

@onready var circuit_simulator := %ElectronicsSimulator
@onready var circuit_simulator_window := %ElectronicsSimulatorWindow

@export var time_frame_estimation_multiplier = 1.1

var computer_systems_configuration := {}
var computer_control_blocks := {}
var computer_networks := {}

var input_to_circuit_from_factory := {}
var outputs_from_circuit_to_factory := {}
var external_circuit_entries := []
var netnames := []

var internal_signals_values := {}

enum { NOT_RUNNING, STARTING, START_CANCELED, START_CANCELED_ACK, RUNNING } # RunningState
enum { UNUSED, NOT_READY, READY, INIT_FAIL, FAIL } # ReadyState
enum { CIRCUIT = 0, COMPUTER = 1, NONE = 65, CONFLICT = 66 } # SystemID / ValueSource
var _running_state := NOT_RUNNING
var _system_state := [ UNUSED, UNUSED ]

var _circuit_simulation_time_step
var _circuit_simulation_max_time

var simulation_on_time : bool
var simulation_time
var estimated_next_simulation_time
var _pause_count := 0

var _timers := []

var _console_read_set # to keep console read/set variable interface

signal factory_tick(time : float, delta_time : float)
signal conflict_error(info : Array)
signal simulation_error(message: String)
signal running()

#endregion
