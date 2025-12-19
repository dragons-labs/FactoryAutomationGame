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
	# "Diode", "PNP", "NPN",
	# "AND", "OR", "XOR", "NOT",
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
]
var _max_blocks := {
	"ElectronicControlBlock": 1,
}
func circuit_element_count_updated(component_subtype : String, _component: Node2D, component_subtype_count : int, button : Button) -> bool:
	return FAG_Utils.check_elements_count_default(component_subtype, component_subtype_count, _max_components, button)

## list of guide topic paths used by this level / unlocked by accessing this level
## first element will be used as default guide topic for this level
var guide_topic_paths := [
    "electronics",
    "electronics/passive_component",
    "factory/electronics_control",
    "factory/producer",
]

## level task info
var task_info := {
"pl": """
Twoim zadaniem jest zbudowanie fabryki, która będzie malowała produkty. Malowanie jest procesem wymagającym trochę czasu, jednak standardowe jednokrotne przejście przez bloczek malujący jest wystarczające. Problemem z którym nie poradzili sobie poprzednicy jest fakt iż (aby zapewnić wymagane pokrycie farbą) taśmociąg w bloczku malującym działa wolniej niż taśmociągi dystrybucyjne. W związku z tym bez zapewnienia dodatkowej kontroli nad przesyłem produktów fabrykę szybko ogarnia chaos.

Wskazówka: jedynym elementem działanie którego możemy kontrolować jest dystrybutor produktów. Wykorzystaj to!
""",
"en" : """
Your task is to build a factory that will paint products. Painting is a time-consuming process, but a standard one-time pass through the painting block is sufficient. The problem that the predecessors did not cope with is the fact that (to provide the required paint coverage) the conveyor belt in the painting block works slower than the distribution conveyors. Therefore, without additional control over the transfer of products, the factory quickly descends into chaos.

Hint: the only element we can control is the product distributor. Use it!
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

func _on_factory_stop() -> void:
	print("STOP")
