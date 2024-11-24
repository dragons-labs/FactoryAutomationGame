# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Area3D

@onready var _factory_root := get_tree().current_scene.get_node("%FactoryRoot")

var _object = null
var _name_prefix := ""

func _ready():
	body_entered.connect(_on_object_enter_block)
	body_exited.connect(_on_object_exit_block)
	_factory_root.factory_start.connect(_on_factory_start)
	
	_name_prefix = get_parent().get_meta("in_game_name", "")
	$"../Label3D".text = _name_prefix
	if _name_prefix:
		_name_prefix += "_"

func _on_factory_start() -> void:
	if not is_inside_tree():
		return
	_object = null
	_factory_root.set_signal_value(_name_prefix + "detector_object_inside", 0)
	_factory_root.set_signal_value(_name_prefix + "detector_pulse", 0)

func _on_object_enter_block(node : Node3D) -> void:
	if node is RigidBody3D:
		_object = node
		_factory_root.set_signal_value(_name_prefix + "detector_object_inside", 3.3)
		_factory_root.set_signal_value(_name_prefix + "detector_pulse", 3.3)
		await _factory_root.create_timer(0.1).timeout
		_factory_root.set_signal_value(_name_prefix + "detector_pulse", 0)

func _on_object_exit_block(node : Node3D) -> void:
	if node == _object:
		_factory_root.set_signal_value(_name_prefix + "detector_object_inside", 0)
