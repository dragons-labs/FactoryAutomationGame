# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

## NOTE about components / products:
##  - component should be hidden RigidBody3D scene node (not packed scene)
##    (see ComponentProducer.gd for details)
##  - component / product root node should be a RigidBody3D, with only one collision shape, without any transforms on this shape
##    (see FactoryBlocksUtils.gd for details)
##  - component / product script should provide is_valid() method returned:
##    - false if product is not finished (is component, half-product or bad product)
##    - true if product is meets game level requirements

extends RigidBody3D

func is_valid():
	return _paint_level >= 5

func start_painting():
	print(self, " start painting")
	_is_painting = true
	var material = StandardMaterial3D.new() # TODO this should be done in better way ... but it's for test only
	$FactoryElementVisual.set_surface_override_material(0, material)
	material.albedo_color = Color(1.0-0.2*_paint_level,1, 1)
	while _is_painting:
		await get_tree().create_timer(0.4, false).timeout
		if _is_painting:
			_paint_level += 1
			material.albedo_color = Color(1.0-0.2*_paint_level,1, 1)
			print(self, " paint ", _paint_level)

func end_painting():
	print(self, " stop painting")
	_is_painting = false

var _paint_level = 0
var _is_painting = false
