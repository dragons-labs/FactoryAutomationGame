# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Area3D

## if `true` blocks the new influence of other conveyors until the object is on this conveyor
@export var exclusive_owner := true

## linear speed [m/s] ... it's externally used to calculate belt_speed_vector
@export var speed := 0.6

var belt_speed_vector # used by FAG_FactoryBlocksUtils
var y_top_minus_offset # used by FAG_FactoryBlocksUtils

func _ready():
	body_entered.connect(FAG_FactoryBlocksUtils.on_object_enter_block__delayed_interaction.bind(self))
	body_exited.connect(_on_leave_painter)
	
	FAG_FactoryBlocksUtils.on_block_transform_updated(self)

func transfer_object_to_factory_block(node : RigidBody3D):
	FAG_FactoryBlocksUtils.accept_object_on_block(node, self, exclusive_owner, belt_speed_vector)
	if node.has_method("start_painting"):
		node.start_painting()

func _on_leave_painter(node : Node3D):
	if node.has_method("end_painting"):
		node.end_painting()
	FAG_FactoryBlocksUtils.on_object_leave_block(node, self)
