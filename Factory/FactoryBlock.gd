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

# optional function called by FactoryBuilder:
# 
# func init(factory_root):
#   # called after placing the block in the factory
#   #  after `_read()`, but (unlike `_read()`) only when it has been placed
#   # used to init internal state and register signals
#
# func deinit():
#   # called when block is removing from factory
#   #  after removed from scene tree
#   # used to unregister signals
#
# func on_transform_update():
#   # called when 3D transform was updated (after rotate and mirror)
#   # used by block which requires updating their internal state in this situation
#   # not called placement (so should be called via `_read()` or `init()` also)


static func handle_name_prefix(object : Object, label: Label3D = null) -> String:
	var name_prefix = object.get_meta("in_game_name", "")
	if label:
		label.text = name_prefix
	if name_prefix:
		name_prefix += "_"
	return name_prefix
