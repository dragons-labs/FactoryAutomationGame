# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Area3D

## if `true` blocks the new influence of other conveyors until the object is on this conveyor
@export var exclusive_owner := false

## conveyor belt linear speed [m/s]
@export var speed := 1.0

@onready var _factory_root := FAG_Settings.get_root_subnode("%FactoryRoot")
@onready var _name_prefix := FAG_FactoryBlocksUtils.handle_name_prefix(self, $"../Label3D")

var belt_speed_vector # used by FAG_FactoryBlocksUtils
var y_top_minus_offset # used by FAG_FactoryBlocksUtils

var _pusher : Node3D
var _pusher_area_objects := []
var _pusher_is_active := false
var _factory_control = null

func _ready():
	body_entered.connect(FAG_FactoryBlocksUtils.on_object_enter_block__instant_interaction.bind(self))
	body_exited.connect(FAG_FactoryBlocksUtils.on_object_leave_block.bind(self))
	_factory_root.factory_start.connect(_on_factory_start_stop)
	_factory_root.factory_stop.connect(_on_factory_start_stop)
	_factory_control = _factory_root.factory_control
	_factory_control.factory_tick.connect(_on_factory_process)
	FAG_FactoryBlocksUtils.on_block_transform_updated(self)

func _on_factory_start_stop() -> void:
	if not is_inside_tree():
		return
	_pusher_is_active = false
	_pusher_area_objects.clear()
	_factory_control.set_signal_value(_name_prefix + "splitter_object_inside", 0)
	_pusher = %Pusher
	_pusher.visible = false
	_pusher.process_mode = PROCESS_MODE_DISABLED

func transfer_object_to_factory_block(node : RigidBody3D):
	# object entered into this block (but it may still be influenced by the previous one, if `belt_list` meta is not empty)
	FAG_FactoryBlocksUtils.accept_object_on_block(node, self, exclusive_owner)


func _on_pusher_area_3d_body_entered(body: Node3D) -> void:
	# object entered into pusher area
	print("object ", body, " inside pusher area")
	_factory_control.set_signal_value(_name_prefix + "splitter_object_inside", 3.3)
	_pusher_area_objects.append(body)

func _on_pusher_area_3d_body_exited(body: Node3D) -> void:
	# object exited pusher area
	print("object ", body, " outside pusher area")
	_pusher_area_objects.erase(body)
	if len(_pusher_area_objects) == 0:
		print("pusher area is empty")
		_factory_control.set_signal_value(_name_prefix + "splitter_object_inside", 0)
	pass # Replace with function body.


func _on_factory_process(_time : float, _delta_time : float):
	if not _pusher:
		return
	if _factory_control.get_signal_value(_name_prefix + "splitter_push") > 2:
		if not _pusher_is_active:
			print("pusher go to active")
			_pusher_is_active = true
			_pusher.visible = true
			_pusher.process_mode = PROCESS_MODE_INHERIT
			for obj in _pusher_area_objects:
				FAG_FactoryBlocksUtils.set_object_free(obj)
				FAG_FactoryBlocksUtils.set_object_speed(obj, Vector3.ZERO)
				FAG_FactoryBlocksUtils.translate_object(obj, get_parent().quaternion * Vector3(0, 0, -1))
			_pusher_area_objects.clear()
			_factory_control.set_signal_value(_name_prefix + "splitter_object_inside", 0)
	else:
		if _pusher_is_active:
			print("pusher go to inactive")
			_pusher_is_active = false
			_pusher.visible = false
			_pusher.process_mode = PROCESS_MODE_DISABLED
