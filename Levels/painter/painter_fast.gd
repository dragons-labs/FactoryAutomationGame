# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node3D


## circuit simulation time and limits parameters
var circuit_simulation_time_step := "50us"
var circuit_simulation_max_time := "600s"
var circuit_simulation_current_limit := 5
var circuit_simulation_voltage_limit := 0

## circuit components settings
var supported_circuit_components := [
	"Line",
	"Voltmeter", "Ammeter",
	"GND", "NetConnector",
	"Resistor", "Capacitor", "Inductor",
	"Diode", "PNP", "NPN",
	"AND", "OR", "XOR", "NOT",
]
var _max_components := {
	# "Resistor": 2,
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
		# "rootfs_image_path" : "res://qemu_img/some_path/"
		# "kernel_image_path" : "res://qemu_img/some_path/"
		# "memory_size" : "192M"
	}
}

## factory block settings
var supported_blocks := [
	"SimpleFactoryBlock",
	"ConveyorBelt",
	"ElectronicControlBlock",
	"Painter",
	"ConveyorFastSplitter",
]
var _max_blocks := {
	"ElectronicControlBlock": 1,
}
func circuit_element_count_updated(component_subtype : String, _component: Node2D, component_subtype_count : int, button : Button) -> bool:
	return FAG_Utils.check_elements_count_default(component_subtype, component_subtype_count, _max_components, button)

## list of guide topic paths used by this level / unlocked by accessing this level
## first element will be used as default guide topic for this level
var guide_topic_paths := [
    "electronics/digital/registers",
    "electronics/digital/digital_gates", # TODO should be introduced in separated level
    "electronics/diode", # TODO should be introduced in separated level
    "electronics/transistors", # TODO should be introduced in separated level
]

## level task info
var task_info := {
"pl": """
Inżynierowie opracowali nowy rodzaj bloku - przekierowanie taśmociągu, który pozwala na kierowanie produktu znajdującego się na taśmociągu w jednym z 3 kierunków. Spróbój wykorzystać go do zwiększenia wydajności fabryki malującej produkty.

Twój cel: 5 pomalowanych produktów w mniej niż 11 sekund.
""",
"en" : """
Engineers have developed a new type of block - conveyor belt redirection, which allows you to direct a product on the conveyor belt in one of 3 directions. Try to use it to increase the efficiency of a factory painting products.

Your goal: 5 painted products in less than 11 seconds.
""",
}

## level id, set in `init` call
var level_id : String

## level init, call
##  - after:
##    - instantiate of level
##    - set value of factory_builder.computer_systems_configuration based on level data
##  - before:
##    - add level to scene tree
## should call factory_root.factory_control.register_factory_signals() to register factory inputs and outputs signals
func init(factory_root : Node3D, id : String, from_save : bool) -> void:
	level_id = id
	
	factory_root.factory_control.register_factory_signals(
		# (global level) outputs to control blocks
		{
			"Vcc" : ["Vcc", "Vcc", "dc 3.3"],
			"PowerOnReset" : ["PowerOnReset", "V_PowerOnReset", "0 PULSE(3.3V 0 100ms)"],
		},
		# (global level) input from control blocks
		{},
		# (global level) extra circuit elements
		[],
		""
	)
	# NOTE register_factory_signals will be also (automatically) called on
	#      all children (having `factory_signals`) of `FactoryBlocks` child of main root of level scene
	#      so no need to define static blocks signals here
	
	_factory_root = factory_root
	_factory_root.factory_start.connect(_on_factory_start)
	_factory_root.factory_stop.connect(_on_factory_stop)
	if not from_save:
		_factory_root.factory_control.circuit_simulator.restore(
			FAG_Utils.load_from_json_file2(self, "painter_slow.circuit")
		)

## level gameplay logic - function is call when product is consumed and should return:
## negative value if game should be ended with failure
## zero if game should be continue
## positive value if game should be ended with success
func validate_product(node : RigidBody3D):
	if node.factory_object_info.color.r < 0.3:
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
	_factory_root.factory_control.create_timer(11).timeout.connect(_on_timer_timeout)

func _on_factory_stop() -> void:
	print("STOP")

func _on_timer_timeout(_val : float) -> void:
	_factory_root.production_timeout()
