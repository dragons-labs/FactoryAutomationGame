# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node3D

### FactoryBlock logic

@export var product : RigidBody3D
@export var timer_period := 1.0
@onready var _timer := $Timer
@onready var _factory_root := get_tree().current_scene.get_node("%FactoryRoot")

var _product_is_ready := false

func _ready() -> void:
	_factory_root.factory_stop.connect(_on_factory_stop)
	_factory_root.factory_start.connect(_on_factory_start)

func _on_timer_timeout() -> void:
	if _factory_root.get_signal_value("control_enabled") > 2:
		if _product_is_ready:
			if _factory_root.get_signal_value("release_product") > 2:
				_release_product()
		else:
			_product_is_ready = true
			_factory_root.set_signal_value("product_ready", 3.3)
			_timer.start(0.1)
	else:
		_release_product()

func _release_product() -> void:
	_factory_root.set_signal_value("product_ready", 0)
	var element : Node3D = product.duplicate()
	_factory_root.products_root.add_child(element)
	element.global_position = global_position
	element.visible = true
	_product_is_ready = false
	_timer.start(timer_period)

func _on_factory_stop() -> void:
	_timer.stop()

func _on_factory_start() -> void:
	_release_product()
