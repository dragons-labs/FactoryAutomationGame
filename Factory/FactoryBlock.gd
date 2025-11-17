# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

class_name FAG_FactoryBlock extends Node3D

### FactoryBlock external info

# for WorldEditorUI:
@export var ui_name : String
@export var ui_icon : Texture2D

# for Builder3D:
# NOTE: root node name will be used as block identifier in UI
#       (as button name) AND should be equal to `object_subtype` value
#       for the correct operation of the block number limiter
@export var object_type := "FactoryBlock"
@export var object_subtype : String
@onready var physics_rids := get_rids()

func get_rids() -> Array:
	if has_node("FactoryElementPhysics"):
		return [get_node("FactoryElementPhysics").get_rid()]
	return []

# definition of input / output signal for this block
#
# this variable is optional, it can be defined in derivered class or script
# (it is used only for for player addable blocks with input/output signal)
#
# value of `in_game_name` meta (if set and not empty) with `_`
# will be used as prefix for signals names
#
# see FactoryControl.register_factory_signals for details
#
# const factory_signals = [
# 	# block outputs (to control system)
# 	{},
# 	# block inputs (from control system)
# 	{},
# 	# extra circuit elements for this block
# 	[]
# ]

# optional callback from FactoryBuilder to block
# used by block which requires updating their internal state
# after performing 3D transformations (rotation, mirror) on block
#
# func on_transform_update():


static func handle_name_prefix(object : Object, label: Label3D = null) -> String:
	var name_prefix = object.get_meta("in_game_name", "")
	if label:
		label.text = name_prefix
	if name_prefix:
		name_prefix += "_"
	return name_prefix
