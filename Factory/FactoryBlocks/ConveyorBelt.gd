# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Area3D

## if `true` blocks the new influence of other conveyors until the object is on this conveyor
@export var exclusive_owner := false

## conveyor belt linear speed [m/s]
@export var speed := 1.0

var belt_speed_vector # used by FAG_FactoryBlocksUtils
var y_top_minus_offset # used by FAG_FactoryBlocksUtils

func _ready():
	body_entered.connect(FAG_FactoryBlocksUtils.on_object_enter_block__instant_interaction.bind(self))
	body_exited.connect(FAG_FactoryBlocksUtils.on_object_leave_block.bind(self))
	
	FAG_FactoryBlocksUtils.on_block_transform_updated(self)

func transfer_element_to_factory_block(node : RigidBody3D):
	FAG_FactoryBlocksUtils.accept_object_on_block(node, self, exclusive_owner)
