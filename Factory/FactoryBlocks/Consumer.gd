# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Area3D

@onready var _factory_root := get_tree().current_scene.get_node("%FactoryRoot")

func _ready() -> void:
	body_entered.connect(FAG_FactoryBlocksUtils.on_object_enter_block__delayed_interaction.bind(self))

func transfer_object_to_factory_block(node : RigidBody3D):
	_factory_root.validate_product(node)
	node.queue_free()
