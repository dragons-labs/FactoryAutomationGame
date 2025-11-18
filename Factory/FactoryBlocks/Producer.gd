# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_FactoryBlock

const _block_signals_outputs := {
	"producer_object_ready"   : ["producer_object_ready_@in", "v_producer_object_ready"],
}
const _block_signals_inputs := {
	"producer_control_enabled" : ["producer_control_enabled_@out"],
	"producer_release_object" : ["producer_release_object_@out"],
}
var _factory_root
var _factory_control
var _name_prefix

func init(factory_root):
	_factory_root = factory_root
	_factory_control = _factory_root.factory_control
	
	_name_prefix = handle_name_prefix(self, $Label3D)
	
	_factory_root.factory_stop.connect(_on_factory_stop)
	_factory_root.factory_start.connect(_on_factory_start)
	
	_factory_control.register_factory_signals(
		_block_signals_outputs, _block_signals_inputs, [],
		get_meta("in_game_name", ""), get_meta("using_computer_id", ""),
	)

func deinit():
	_factory_control.unregister_factory_signals(
		_block_signals_outputs, _block_signals_inputs, [],
		get_meta("in_game_name", ""), get_meta("using_computer_id", ""),
	)


@export var object : RigidBody3D
@export var timer_period := 1.0

var _object_is_ready := false
var _timer = null

func _on_timer_timeout(delay : float) -> void:
	if _factory_control.get_signal_value(_name_prefix + "producer_control_enabled") > 2:
		if _object_is_ready:
			if _factory_control.get_signal_value(_name_prefix + "producer_release_object") > 2:
				_release_object()
		else:
			_object_is_ready = true
			_factory_control.set_signal_value(_name_prefix + "producer_object_ready", 3.3)
			_timer.reset(0.1)
	else:
		_release_object(delay)

func _release_object(delay := 0.0) -> void:
	_factory_control.set_signal_value(_name_prefix + "producer_object_ready", 0)
	var element : Node3D = object.duplicate()
	_factory_root.objects_root.add_child(element)
	element.global_position = global_position
	element.visible = true
	_object_is_ready = false
	_timer.reset(timer_period + delay)

func _on_factory_stop() -> void:
	if not is_inside_tree():
		return

func _on_factory_start() -> void:
	if not is_inside_tree():
		return
	_timer = _factory_control.create_timer(timer_period, false)
	_timer.timeout.connect(_on_timer_timeout)
	_on_timer_timeout(0.0)
