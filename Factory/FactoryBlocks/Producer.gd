# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node3D

@export var object : RigidBody3D
@export var timer_period := 1.0
@onready var _timer := $Timer
@onready var _factory_root := get_tree().current_scene.get_node("%FactoryRoot")

var _object_is_ready := false
var _name_prefix := ""

func _ready() -> void:
	_factory_root.factory_stop.connect(_on_factory_stop)
	_factory_root.factory_start.connect(_on_factory_start)
	
	_name_prefix = get_meta("in_game_name", "")
	$Label3D.text = _name_prefix
	if _name_prefix:
		_name_prefix += "_"

func _on_timer_timeout() -> void:
	if _factory_root.get_signal_value(_name_prefix + "producer_control_enabled") > 2:
		if _object_is_ready:
			if _factory_root.get_signal_value(_name_prefix + "producer_release_object") > 2:
				_release_object()
		else:
			_object_is_ready = true
			_factory_root.set_signal_value(_name_prefix + "producer_object_ready", 3.3)
			_timer.start(0.1)
	else:
		_release_object()

func _release_object() -> void:
	_factory_root.set_signal_value(_name_prefix + "producer_object_ready", 0)
	var element : Node3D = object.duplicate()
	_factory_root.objects_root.add_child(element)
	element.global_position = global_position
	element.visible = true
	_object_is_ready = false
	_timer.start(timer_period)

func _on_factory_stop() -> void:
	_timer.stop()

func _on_factory_start() -> void:
	_release_object()
