# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_FactoryBlock

@onready var _area := $Area3D
@onready var _factory_root := FAG_Settings.get_root_subnode("%FactoryRoot")

func _ready() -> void:
	_area.body_entered.connect(FAG_FactoryBlockConveyor.on_object_enter_block__delayed_interaction.bind(self))

func transfer_object_to_factory_block(node : RigidBody3D):
	_factory_root.validate_product(node)
	node.queue_free()
