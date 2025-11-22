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

@onready var _block_control = FAG_FactoryBlockControl.new(self)

func init(factory_root, block_name = null):
	_block_control.init(factory_root, block_name, $Label3D, _block_signals_outputs, _block_signals_inputs, [])
	
	factory_root.factory_stop.connect(_on_factory_stop)
	factory_root.factory_start.connect(_on_factory_start)
	
	_objects_root = factory_root.objects_root


@export var object : RigidBody3D
@export var timer_period := 1.0

var _objects_root
var _object_is_ready := false
var _timer = null

func _on_timer_timeout(delay : float) -> void:
	if _block_control.get_signal_value("producer_control_enabled") > 2:
		if _object_is_ready:
			if _block_control.get_signal_value("producer_release_object") > 2:
				_release_object()
		else:
			_object_is_ready = true
			_block_control.set_signal_value("producer_object_ready", 3.3)
			_timer.reset(0.1)
	else:
		_release_object(delay)

func _release_object(delay := 0.0) -> void:
	_block_control.set_signal_value("producer_object_ready", 0)
	var element : Node3D = object.duplicate()
	_objects_root.add_child(element)
	element.global_position = global_position
	element.visible = true
	_object_is_ready = false
	_timer.reset(timer_period - delay)

func _on_factory_stop() -> void:
	if not is_inside_tree():
		return

func _on_factory_start() -> void:
	if not is_inside_tree():
		return
	_object_is_ready = false
	_timer = _block_control._factory_control.create_timer(timer_period, false)
	_timer.timeout.connect(_on_timer_timeout)
	_on_timer_timeout(0.0)
