# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_FactoryBlockConveyor

@export var _area : Area3D
@export var _root : FAG_FactoryBlockConveyor

var _area1
var _area2
var _area3

func _ready():
	_area.body_entered.connect(FAG_FactoryBlockConveyor.on_object_enter_block__instant_interaction.bind(self))
	_area.body_exited.connect(FAG_FactoryBlockConveyor.on_object_leave_block.bind(self))
	
	if has_node("Area3D"):
		_area1 = $Area3D
		_area2 = $Area3D_2
		_area3 = $Area3D_3
	
	on_block_transform_updated(_area, _root)

func on_transform_update():
	_root.on_block_transform_updated(_area1, _root)
	_area2.on_block_transform_updated(_area2, _root)
	_area3.on_block_transform_updated(_area3, _root)

func transfer_object_to_factory_block(node : RigidBody3D):
	FAG_FactoryBlockConveyor.accept_object_on_block(node, self, exclusive_owner)
