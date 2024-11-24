# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node2D


## Current value to trigger over current protection (0 to disable current checking)
@export var current_limit = 0

## Voltage value to trigger over voltage protection (0 to disable voltage checking)
@export var voltage_limit = 0

signal overcurrent_protection(fuse : String, value : float)
signal overvoltage_protection(net : String, value : float)
signal simulation_error()


@onready var gdspice := %"GdSpice+UI"
@onready var grid_editor := %"GridEditor"
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

## Init circuit for simulation, but not start simulation
##
## Takes arguments:
##  - external_nets_input_to_circuit_from_factory:
##     List of external (not defined in grid editor) strong (power, logic outputs, ...) nets
##     as 2 or 3 or 4 element arrays: [code]["voltage_source_name", "net_name", "voltage source specification", "internal resistance value"][/code]
##
##     If "voltage source specification" is omitted or null then "external" is used.
##
##     If you use "external" type voltage/current sources then you can set it value during simulation via
##     [code]gdspice.set_voltages_currents(element_name : String, value : double)[/code].[br][br]
##
##     [b]NOTE:[/b] ngspice will be used lowercase element name (not net name) while ask for
##                  voltage/current value, so use lowercase element name in
##                  [code]set_voltages_currents()[/code] calls also.
##  - external_nets_outputs_from_circuit_to_factory
##     List of external (not defined in grid editor) input nets (output for grid editor circuit)
##     as 1 or 2 elements arrays: [code]["net_name", "resistor specification"][/code]
##     if [code]"resistor specification"[/code] is not specified then connected via high resistance to GND
##  - external_circuit_entries
##     List of other external (not shown in editor) circuit elements
##  - simulation_time_step
##     Time step used (default 10us, ~100kHz)
##  - simulation_max_time
##     Simulation maximum time length (default 600s)
func init_circuit(
		external_nets_input_to_circuit_from_factory := [],
		external_nets_outputs_from_circuit_to_factory := [],
		external_circuit_entries := []
	) -> Array:
		if gdspice.get_simulation_state() != GdSpice.NOT_STARTED:
			gdspice.reset()
			gdspice.stop()
		
		print("Init circuit simulation")
		grid_editor.ui.set_editor_enabled(false)
		for element in grid_editor.grid.gElements.main_node.get_children():
			for ui in element.get_child(0).get_children():
				if ui is LineEdit:
					ui.editable = false
				elif ui is OptionButton:
					ui.disabled = true
		
		var netlist_info = gdspice.get_ngspice_netlist(
			grid_editor.grid,
			external_nets_input_to_circuit_from_factory,
			external_nets_outputs_from_circuit_to_factory,
			external_circuit_entries
		)
		gdspice.load(netlist_info[0])
		return netlist_info[1]

func start(simulation_time_step := "10us", simulation_max_time := "600s") -> void:
	gdspice.start(simulation_time_step, simulation_max_time)

func try_step(time : float) -> bool:
	if gdspice.try_step(time):
		gdspice.update_measurements()
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
		return true
	else:
		if gdspice.get_simulation_state() == GdSpice.ERROR:
			simulation_error.emit()
		return false

func stop() -> void:
	print("Stop circuit simulation")
	gdspice.stop()
	gdspice.reset()
	grid_editor.ui.set_editor_enabled(true)
	for element in grid_editor.grid.gElements.main_node.get_children():
		for ui in element.get_child(0).get_children():
			if ui is LineEdit:
				ui.editable = true
			elif ui is OptionButton:
				ui.disabled = false

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
	gdspice.verbose = 2

func _on_element_click(element, _long):
	var base_element = Grid2D_BaseElement.get_from_element(element)
	if base_element.type == "Meter":
		gdspice.on_measurer_click(base_element)
