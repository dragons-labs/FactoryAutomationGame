# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

## NOTE about factory objects (components / products):
##  - factory object root node should be a RigidBody3D, with only one collision shape, without any transforms on this shape
##    (see FactoryBlocksUtils.gd for details)
##  - factory object must be (hidden) RigidBody3D scene node (not packed scene)
##    (see FactoryBlocks/Producer.gd for details)
##  - factory object must provide factory_object_info public variable (see bellow) on own root node

extends RigidBody3D

var factory_object_info = {
	"type": "box",
	"color": Color(1, 1, 1)
}

func start_painting():
	_is_painted = true
	var material = StandardMaterial3D.new() # TODO this should be done in better way ... but it's for test only
	$FactoryElementVisual.set_surface_override_material(0, material)
	material.albedo_color = factory_object_info.color
	while _is_painted:
		await get_tree().create_timer(0.4, false).timeout
		if _is_painted and factory_object_info.color.r >= 0.2:
			factory_object_info.color.r -= 0.2
			material.albedo_color = factory_object_info.color

func end_painting():
	_is_painted = false

var _is_painted = false
