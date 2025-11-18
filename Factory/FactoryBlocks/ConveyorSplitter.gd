# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_FactoryBlockConveyor

const _block_signals_outputs := {
	"splitter_object_inside"   : ["splitter_object_inside_@in", "v_splitter_object_inside"],
}
const _block_signals_inputs := {
	"splitter_redirect_forward" : ["splitter_redirect_forward_@out"],
	"splitter_redirect_to_left" : ["splitter_redirect_to_left_@out"],
	"splitter_redirect_to_right" : ["splitter_redirect_to_right_@out"],
}
var _factory_root
var _factory_control
var _name_prefix

func init(factory_root):
	_factory_root = factory_root
	_factory_control = _factory_root.factory_control
	
	_name_prefix = handle_name_prefix(self, $Label3D)
	
	_factory_root.factory_stop.connect(_on_factory_start_stop)
	_factory_root.factory_start.connect(_on_factory_start_stop)
	
	_factory_control.factory_tick.connect(_on_factory_process)
	_factory_control.register_factory_signals(
		_block_signals_outputs, _block_signals_inputs, [],
		get_meta("in_game_name", ""), get_meta("using_computer_id", ""),
	)
	
	_area.body_entered.connect(_on_object_enter_block)
	_area.body_exited.connect(_on_object_exit_block)
	
	on_transform_update()

func deinit():
	_factory_control.unregister_factory_signals(
		_block_signals_outputs, _block_signals_inputs, [],
		get_meta("in_game_name", ""), get_meta("using_computer_id", ""),
	)

func on_transform_update():
	on_block_transform_updated(_area)


@onready var _area := $Area3D

var _object = null
var _waiting_object = null
var _new_accepted_object := false

func _on_factory_start_stop() -> void:
	if not is_inside_tree():
		return
	
	_object = null
	
	_waiting_object = null
	_new_accepted_object = false
	
	_factory_control.set_signal_value(_name_prefix + "splitter_object_inside", 0)

func _on_object_enter_block(node : Node3D) -> void:
	if node is RigidBody3D:
		print(node, " splitter pre enter", _object)
		node.set_meta("next_belt", self)
		
		# if object is inside splitter then stop incoming object before really enter to splitter
		if _object:
			FAG_FactoryBlockConveyor.set_object_speed(node, Vector3.ZERO)
			_waiting_object = node

func transfer_object_to_factory_block(node : RigidBody3D):
	print(node, " splitter enter")
	node.custom_integrator = true
	FAG_FactoryBlockConveyor.set_object_speed(node, Vector3.ZERO)
	_object = node
	_new_accepted_object = true
	_factory_control.set_signal_value(_name_prefix + "splitter_object_inside", 3.3)

func _on_factory_process(_time : float, _delta_time : float):
	if _new_accepted_object:
		var direction = 0
		if _factory_control.get_signal_value(_name_prefix + "splitter_redirect_forward") > 2:
			direction += 1
		elif _factory_control.get_signal_value(_name_prefix + "splitter_redirect_to_left") > 2:
			direction += 2
		elif _factory_control.get_signal_value(_name_prefix + "splitter_redirect_to_right") > 2:
			direction += 4
		
		if direction in [1, 2, 4]:
			var obj_speed = belt_speed_vector # == get_parent().quaternion * Vector3(speed, 0, 0)
			if direction == 2:
				obj_speed = get_parent().quaternion * Vector3(0, 0, -speed)
			elif direction == 4:
				obj_speed = get_parent().quaternion * Vector3(0, 0, speed)
			_new_accepted_object = false
			FAG_FactoryBlockConveyor.accept_object_on_block(_object, self, true, obj_speed)
		elif direction != 0:
			print("error in control signal")

func _on_object_exit_block(node : Node3D) -> void:
	if node != _object:
		return
	
	print(_object, " splitter exit")
	_factory_control.set_signal_value(_name_prefix + "splitter_object_inside", 0)
	
	# transfer object to next conveyor
	FAG_FactoryBlockConveyor.on_object_leave_block(_object, self)
	
	# allow get next object
	_object = null
	
	# allow enter for next (waiting) object
	if _waiting_object:
		FAG_FactoryBlockConveyor.set_object_speed(
			_waiting_object,
			FAG_FactoryBlockConveyor.calculate_object_speed(_waiting_object.get_meta("belts_list", []))
		)
		_waiting_object = null
