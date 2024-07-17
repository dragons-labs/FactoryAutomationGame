# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node2D



## List of external (not defined in grid editor) strong (power, logic outputs, ...) nets
## as 3 element arrays: [code]["voltage_source_name", "net_name", "voltage source specification"][/code]
##
## If you use "external" type voltage/current sources then you can set it value during simulation via
## [code]gdspice.set_voltages_currents(element_name : String, value : double)[/code].[br][br]
##
## [b]NOTE:[/b] ngspice will be used lowercase element name (not net name) while ask for
##              voltage/current value, so use lowercase element name in
##              [code]set_voltages_currents()[/code] calls also.
@export var external_output_nets := []

## List of external (not defined in grid editor) input nets (output for grid editor circuit)
## as 1 or 2 elements arrays: [code]["net_name", "resistor specification"][/code]
## if [code]"resistor specification"[/code] is not specified then connected via high resistance to GND
@export var external_input_nets := []

## List of other external (not shown in editor) circuit elements
@export var external_circuit_entries := []

## Time step used (default 10us, ~100kHz)
@export var simulation_time_step := "10us"

## Simulation maximum length (default 600s)
@export var simulation_max_time := "600s"

## Current value to trigger over current protection (0 to disable current checking)
@export var current_limit = 0

## Voltage value to trigger over voltage protection (0 to disable voltage checking)
@export var voltage_limit = 0

signal overcurrent_protection(fuse : String, value : float)
signal overvoltage_protection(net : String, value : float)
signal simulation_error()


@onready var gdspice := %"GdSpice+UI"
@onready var grid_editor := %"GridEditor"
var error_was_reported = false

func serialise() -> Dictionary:
	return grid_editor.grid.serialise()

func restore(data : Dictionary) -> void:
	grid_editor.grid.restore(data, grid_editor.ui._elements_dict)

func save_tscn(save_file : String) -> void:
	grid_editor.grid.save_tscn(save_file)

func restore_tscn(save_file : String) -> void:
	grid_editor.grid.restore_tscn(save_file)

func close() -> void:
	if gdspice.get_simulation_state() != GdSpice.NOT_STARTED:
		stop()
	grid_editor.grid.close()
	grid_editor.ui.reset_editor()

func init_circuit() -> Array:
	error_was_reported = false
	
	if gdspice.get_simulation_state() != GdSpice.NOT_STARTED:
		gdspice.reset()
		gdspice.stop()
	
	print("Init circuit simulation")
	grid_editor.ui.set_editor_enabled(false)
	
	var netlist_info = gdspice.get_ngspice_netlist(grid_editor.grid, external_output_nets, external_input_nets, external_circuit_entries, simulation_time_step, simulation_max_time)
	gdspice.load(netlist_info[0])
	return netlist_info[1]

func start(real_start : bool) -> void:
	if not real_start:
		gdspice.start(false)
		return
	if gdspice.get_simulation_state() == GdSpice.READY:
		print("Start circuit simulation")
		gdspice.start()
	else:
		printerr("Can't start, current state = %x" % gdspice.get_simulation_state())

func stop() -> void:
	print("Stop circuit simulation")
	gdspice.reset()
	gdspice.stop()
	grid_editor.ui.set_editor_enabled(true)

# do not expose here gdspice.pause() and gdspice.resume()
# because they are for special cases when nothing happens and we can pause
# the simulation itself (without pausing the game) to save resources,
# but we don't know the full internal state of the circuit so it's risky
#
# for normal pause/resume simulation use Engine.time_scale value

func set_input_allowed(value):
	print("Input allowed into circuit simulator: ", value)
	grid_editor.set_input_allowed(value)

func set_visibility(value : bool) -> void:
	visible = value
	grid_editor.call_deferred("set_visibility", value)


func _ready():
	grid_editor.on_element_click.connect(_on_element_click)
	grid_editor.ui.get_node("%Actions/Import").tooltip_text = "ELECTRONIC_EDITOR_IMPORT_TOOLTIP"
	grid_editor.ui.get_node("%Actions/Save").tooltip_text = "ELECTRONIC_EDITOR_SAVE_TOOLTIP"
	
	gdspice.init()
	gdspice.verbose = 1

func _process(_delta):
	match gdspice.get_simulation_state():
		GdSpice.RUNNING:
			gdspice.update_measurers()
			if current_limit:
				for fuse in gdspice.fuses:
					var value = gdspice.get_last_value(fuse)
					if value > current_limit or value < -current_limit:
						overcurrent_protection.emit(fuse, value)
			elif voltage_limit:
				for net in gdspice.used_nets:
					var value = gdspice.get_last_value(net)
					if value > voltage_limit or value < -voltage_limit:
						overvoltage_protection.emit(net, value)
		GdSpice.ERROR:
			if not error_was_reported:
				error_was_reported = true
				simulation_error.emit()

func _on_element_click(element, _long):
	var base_element = Grid2D_BaseElement.get_from_element(element)
	if base_element.type == "Meter":
		gdspice.on_measurer_click(base_element)
