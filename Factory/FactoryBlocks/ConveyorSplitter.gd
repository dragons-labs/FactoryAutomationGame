# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Area3D

## if `true` blocks the new influence of other conveyors until the object is on this conveyor
@export var exclusive_owner := false

## conveyor belt linear speed [m/s]
@export var speed := 1.0

@onready var _factory_root := get_tree().current_scene.get_node("%FactoryRoot")

var belt_speed_vector # used by FAG_FactoryBlocksUtils
var y_top_minus_offset # used by FAG_FactoryBlocksUtils

var _object = null
var _waiting_object = null
var _new_accepted_object := false
var _name_prefix := ""

func _ready():
	body_entered.connect(_on_object_enter_block)
	body_exited.connect(_on_object_exit_block)
	_factory_root.factory_start.connect(_on_factory_start)
	FAG_FactoryBlocksUtils.on_block_transform_updated(self)
	
	_name_prefix = get_parent().get_meta("in_game_name", "")
	$"../Label3D".text = _name_prefix
	if _name_prefix:
		_name_prefix += "_"

func _on_factory_start() -> void:
	_object = null
	
	_waiting_object = null
	_new_accepted_object = false
	
	_factory_root.set_signal_value(_name_prefix + "splitter_object_inside", 0)

func _on_object_enter_block(node : Node3D) -> void:
	if node is RigidBody3D:
		print(node, " splitter pre enter", _object)
		node.set_meta("next_belt", self)
		
		# if object is inside splitter then stop incoming object before really enter to splitter
		if _object:
			FAG_FactoryBlocksUtils.set_object_speed(node, Vector3.ZERO)
			_waiting_object = node

func transfer_object_to_factory_block(node : RigidBody3D):
	print(node, " splitter enter")
	node.custom_integrator = true
	FAG_FactoryBlocksUtils.set_object_speed(node, Vector3.ZERO)
	_object = node
	_new_accepted_object = true
	_factory_root.set_signal_value(_name_prefix + "splitter_object_inside", 3.3)

func _process(_delta : float):
	if _new_accepted_object:
		var direction = 0
		if _factory_root.get_signal_value(_name_prefix + "splitter_redirect_forward") > 2:
			direction += 1
		elif _factory_root.get_signal_value(_name_prefix + "splitter_redirect_to_left") > 2:
			direction += 2
		elif _factory_root.get_signal_value(_name_prefix + "splitter_redirect_to_right") > 2:
			direction += 4
		
		if direction in [1, 2, 4]:
			var obj_speed = belt_speed_vector # == get_parent().quaternion * Vector3(speed, 0, 0)
			if direction == 2:
				obj_speed = get_parent().quaternion * Vector3(0, 0, -speed)
			elif direction == 4:
				obj_speed = get_parent().quaternion * Vector3(0, 0, speed)
			_new_accepted_object = false
			FAG_FactoryBlocksUtils.accept_object_on_block(_object, self, true, obj_speed)
		elif direction != 0:
			print("error in control signal")

func _on_object_exit_block(node : Node3D) -> void:
	if node != _object:
		return
	
	print(_object, " splitter exit")
	
	# transfer object to next conveyor
	FAG_FactoryBlocksUtils.on_object_leave_block(_object, self)
	
	# allow get next object
	_object = null
	
	# allow enter for next (waiting) object
	if _waiting_object:
		FAG_FactoryBlocksUtils.set_object_speed(
			_waiting_object,
			FAG_FactoryBlocksUtils.calculate_object_speed(_waiting_object.get_meta("belts_list", []))
		)
		_waiting_object = null
