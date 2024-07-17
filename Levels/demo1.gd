# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node3D

## control blocks input signals (from factory) with mapping to circuit element name (not net name)
## (NOTE: circuit element name should be lowercase, because ngspice using lowercase element name to ask for voltage value)
var control_block_input_signals := {
	"product_ready"   : "v_product_ready",
}

## control blocks output signals (to factory) with mapping to circuit net name (not element name)
var control_block_output_signals := {
	"control_enabled" : "control_enabled_[out]",
	"release_product" : "release_product_[out]",
}

## factory strong (power, logic outputs, ...) nets
## as 3 element arrays: `[voltage_source_name, net_name, voltage_source_specification]`
var circuit_factory_output_nets := [
	["Vcc", "Vcc", "dc 3.3"],
	["v_product_ready", "product_ready_[in]", "external"],
]

## factory input nets (output from circuit to factory)
## as 1 or 2 elements arrays: [net_name, resistor_specification]
## when resistor_specification is not specified then connected via high resistance to GND
var circuit_factory_input_nets := [
	["release_product_[out]"],
	["control_enabled_[out]"],
	# ["sink_input_sample", "Vcc 10k"]
	# ["source_input_sample", "GND 10k"]
]

## other factory circuit elements
var circuit_factory_extra_entries := [
	# "Rsample1 factory_signal1 factory_signal2 10k",
]

## factory simulation time and limits parameters
var circuit_simulation_time_step := "10us"
var circuit_simulation_max_time := "600s"
var circuit_simulation_current_limit = 5
var circuit_simulation_voltage_limit = 0

## circuit components settings
var supported_circuit_components := [
	"Line",
	"Voltmeter", "Ammeter",
	"GND", "NetConnector",
	"Resistor", "Capacitor", "Inductor",
	# "Diode", "PNP", "NPN",
	# "AND", "OR", "XOR", "NOT",
]
var _max_components := {
	"Resistor": 2,
}
func block_count_updated(block_subtype : String, _block: Node3D, block_subtype_count : int, button : Button) -> bool:
	return FAG_Utils.check_elements_count_default(block_subtype, block_subtype_count, _max_blocks, button)


## computer system simulator configration
var computer_systems_configuration := {
	0: {
		"virtfs" : {
			"common_fs": "user://common_fs",
			"private_fs": "user://workdir/private_fs",
		},
		"writable_disk_image": true,
		# "rootfs_image_path" : "res://some_path/"
		# "kernel_image_path" : "res://some_path/"
		# "memory_size" : "192M"
		"input_names":  control_block_input_signals.keys(),
		"output_names": control_block_output_signals.keys(),
	}
}

## factory block settings
var supported_blocks := [
	"SimpleFactoryBlock",
	"ConveyorBelt",
	"ComputerControlBlock",
	"ElectronicControlBlock",
	"Painter",
]
var _max_blocks := {
	"ComputerControlBlock": 3,
	"ElectronicControlBlock": 1,
}
func circuit_element_count_updated(component_subtype : String, _component: Node2D, component_subtype_count : int, button : Button) -> bool:
	return FAG_Utils.check_elements_count_default(component_subtype, component_subtype_count, _max_components, button)

## level task info
var guide_topic_path := "electronics/basic"

var task_info := {
"en" : """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent volutpat, massa id interdum placerat, urna sem faucibus neque, sit amet aliquet elit mi in felis. Aenean fermentum tellus mattis aliquam volutpat. Integer justo diam, condimentum at lobortis ac, commodo eget felis.

Nullam molestie tincidunt lectus, a molestie diam imperdiet non. Nunc finibus felis eget consequat tristique. Proin a tincidunt magna. Quisque fermentum eros vel ex ultrices auctor. Mauris et enim pharetra nibh convallis pellentesque sed et felis.

Integer ullamcorper maximus faucibus. Fusce cursus, lacus placerat varius lacinia, tortor nisi laoreet odio, et placerat purus est vel lectus. Vestibulum ac tristique sapien. Donec lacus lectus, consequat at justo et, hendrerit lacinia nulla. Aliquam nulla purus, condimentum sit amet rhoncus non, condimentum vitae lectus. In hac habitasse platea dictumst.
""",
}

## level id, set in `init` call
var level_id : String

## list of id of levels unlocked by finished this level
## externally set just **after** level is loaded
var unlocks_levels : Array

## level init (call after instantiate of level and before add it to scene tree)
func init(factory_root : Node3D, id : String, from_save : bool) -> void:
	level_id = id
	_factory_root = factory_root
	_factory_root.factory_start.connect(_on_factory_start)
	_factory_root.factory_stop.connect(_on_factory_stop)
	if not from_save:
		_factory_root.circuit_simulator.restore(
			FAG_Utils.load_from_json_file(
				get_script().resource_path.get_base_dir() + "/demo1.circuit"
			)
		)

## level gameplay logic - function is call when product is consumed and should return:
## negative value if game should be ended with failure
## zero if game should be continue
## positive value if game should be ended with success
func validate_product(node : RigidBody3D):
	print ("validate_product", node.is_valid())
	if node.is_valid():
		_valid_product_counter += 1
		if _valid_product_counter > 5:
			return 1
	else:
		return -1
	return 0


## all stuff below is optional (not used externally) ##

var _factory_root : Node3D
var _valid_product_counter = 0

func _on_factory_start() -> void:
	_valid_product_counter = 0
	print("START")

func _on_factory_stop() -> void:
	print("STOP")
