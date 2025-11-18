# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_FactoryBlock

const _block_signals_outputs := {
	"detector_pulse"   : ["detector_pulse@in", "v_detector_pulse"],
	"detector_object_inside"   : ["detector_object_inside@in", "v_object_inside"],
}

@onready var _block_control = FAG_FactoryBlockControl.new(self)

func init(factory_root, name = null):
	_block_control.init(factory_root, name, $Label3D, _block_signals_outputs, {}, [])
	
	factory_root.factory_start.connect(_on_factory_start)
	
	$Area3D.body_entered.connect(_on_object_enter_block)
	$Area3D.body_exited.connect(_on_object_exit_block)


var _object = null

func _on_factory_start() -> void:
	if not is_inside_tree():
		return
	_object = null
	_block_control.set_signal_value("detector_object_inside", 0)
	_block_control.set_signal_value("detector_pulse", 0)

func _on_object_enter_block(node : Node3D) -> void:
	if node is RigidBody3D:
		_object = node
		_block_control.set_signal_value("detector_object_inside", 3.3)
		_block_control.set_signal_value("detector_pulse", 3.3)
		await _block_control._factory_control.create_timer(0.1).timeout
		_block_control.set_signal_value("detector_pulse", 0)

func _on_object_exit_block(node : Node3D) -> void:
	if node == _object:
		_block_control.set_signal_value("detector_object_inside", 0)
