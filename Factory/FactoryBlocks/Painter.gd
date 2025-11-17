# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_FactoryBlockConveyor

@onready var _area := $Area3D

func _ready():
	_area.body_entered.connect(FAG_FactoryBlockConveyor.on_object_enter_block__delayed_interaction.bind(self))
	_area.body_exited.connect(_on_leave_painter)
	on_transform_update()

func on_transform_update():
	on_block_transform_updated(_area)

func transfer_object_to_factory_block(node : RigidBody3D):
	FAG_FactoryBlockConveyor.accept_object_on_block(node, self, exclusive_owner, belt_speed_vector)
	if node.has_method("start_painting"):
		node.start_painting()

func _on_leave_painter(node : Node3D):
	if node.has_method("end_painting"):
		node.end_painting()
	FAG_FactoryBlockConveyor.on_object_leave_block(node, self)
