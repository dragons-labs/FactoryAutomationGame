# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Area3D

## if `true` blocks the new influence of other conveyors until the object is on this conveyor
@export var exclusive_owner := false

## conveyor belt linear speed [m/s]
@export var speed := 1.0

@onready var _factory_root := get_tree().current_scene.get_node("%FactoryRoot")
@onready var _second_input := $"../Area3DIn2"

var belt_speed_vector # used by FAG_FactoryBlocksUtils
var y_top_minus_offset # used by FAG_FactoryBlocksUtils

var _object = [null, null]
var _object_to_get = [null, null]
var _waiting_object = [null, null]
var _new_accepted_object := false

func _ready():
	body_entered.connect(_on_object_enter_block.bind(0))
	_second_input.body_entered.connect(_on_object_enter_block.bind(1))
	body_exited.connect(_on_object_exit_block)
	_factory_root.factory_start.connect(_on_factory_start)
	FAG_FactoryBlocksUtils.on_block_transform_updated(self)

func _on_factory_start() -> void:
	_object = [null, null]
	_object_to_get = [null, null]
	_waiting_object = [null, null]
	_new_accepted_object = false

func _on_object_enter_block(node : Node3D, index) -> void:
	if node is RigidBody3D:
		print(node, " welder pre enter", _object[index])
		
		_object_to_get[index] = node
		node.set_meta("next_belt", self)
		
		# if object is inside splitter then stop incoming object before really enter to splitter
		if _object[index]:
			FAG_FactoryBlocksUtils.set_object_speed(node, Vector3.ZERO)
			_waiting_object[index] = node

func transfer_object_to_factory_block(node : RigidBody3D):
	if node == _object_to_get[0]:
		_object[0] = node
	elif node == _object_to_get[1]:
		_object[1] = node
	else:
		print("unknown object ", node, " enter to welder")
		return
	
	print(node, " welder enter")
	node.custom_integrator = true
	FAG_FactoryBlocksUtils.set_object_speed(node, Vector3.ZERO)
	_new_accepted_object = true
	_factory_root.set_signal_value(get_meta("in_game_name", "") + "object_inside", 1)

func _process(_delta : float):
	if _new_accepted_object and _object[0] and _object[1]:
		_new_accepted_object = false
		
		_object[0].factory_object_info = {
			"type": "weld",
			"lower": _object[0].factory_object_info,
			"upper": _object[1].factory_object_info,
		}
		_object[1].factory_object_info = null
		
		if "weld" in _object[0]:
			_object[0].weld(_object[1])
		else:
			var visual_object1 = _object[1].get_node("FactoryElementVisual")
			if visual_object1:
				_object[1].remove_child(visual_object1)
				_object[0].add_child(visual_object1)
				visual_object1.owner = _object[0]
				visual_object1.position = Vector3(0, 0.5, 0)
			_object[1].queue_free()
		
		FAG_FactoryBlocksUtils.accept_object_on_block(_object[0], self, true, belt_speed_vector)

func _on_object_exit_block(node : Node3D) -> void:
	if node != _object[0]:
		return
	
	print(_object[0], " welder exit")
	
	# transfer object to next conveyor
	FAG_FactoryBlocksUtils.on_object_leave_block(_object[0], self)
	
	# allow get next objects
	_object = [null, null]
	
	# allow enter for next (waiting) objects
	for i in range(2):
		if _waiting_object[i]:
			FAG_FactoryBlocksUtils.set_object_speed(
				_waiting_object[i],
				FAG_FactoryBlocksUtils.calculate_object_speed(_waiting_object[i].get_meta("belts_list", []))
			)
			_object_to_get[i] = _waiting_object[i]
			_waiting_object[i] = null
