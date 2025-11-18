# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

class_name FAG_FactoryBlock extends Node3D

#region  External info for WorldEditorUI

## Name to show in UI tooltip (will be translated if translations is available).
@export var ui_name : String

## Icon to show in UI.
@export var ui_icon : Texture2D

#endregion

#region  External info for FactoryBuilder

## Block type id string.
## NOTE: root node name will be used as block identifier in UI
##       (as button name) AND should be equal to `object_type` value
##       for the correct operation of the block number limiter
@export var object_type : String

#endregion

#region  Function called by FactoryBuilder

## Return physics RIDs, by default get from "FactoryElementPhysics" subnode.
## Used to eliminate self collision in FactoryBuilder raycasting.
##
## NOTE: Can be called before init() and should return correct value.
func get_physics_rids() -> Array:
	if has_node("FactoryElementPhysics"):
		return [get_node("FactoryElementPhysics").get_rid()]
	return []

## Return block FAG_FactoryBlockControl object if block is nameable or null otherwise.
##
## NOTE: Can be called before init() and should return correct value.
func get_block_control():
	return get("_block_control")

## Called after placing the block in the factory, after [code]_ready()[/code],
## but (unlike [code]_ready()[/code]) only when it has been placed (added to factory).
##
## NOTE: Called with [code]name == null[/code] when name is not changed or not set.
##       In this case an object that has a name should NOT change it.
func init(factory_root, name = null):
	pass

## Called when block is removing from factory, after removed from scene tree.
func deinit():
	# if named block (with signals) then call deinit() on FAG_FactoryBlockControl to unregister signals
	if "_block_control" in self:
		get("_block_control")._deinit_factory_signals()

# Called when 3D transform was updated (after rotate and mirror).
# Used by block which requires updating their internal state in this situation.
##
# NOTE: Not called as a result of block initial placement.
#       So should be called via [code]_ready()[/code] or [code]init()[/code] also.
func on_transform_update():
	pass

#endregion

#region  Utils functions

func get_block_config(default = {}):
	if not has_meta("block_config"):
		set_meta("block_config", default)
	return get_meta("block_config")
	# we return reference to dictionary in meta
	# (and this way it will be kept in the results variable)
	# so we don't need call set_meta() after update dictionary value

#endregion
