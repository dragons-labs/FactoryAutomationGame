# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

@tool
extends Node2D
class_name Grid2D_BaseElement

@export_group("Grid Element Settings")

@export var connections : PackedVector2Array :
	set(value):
		connections = value
		if connections_node:
			_update_connections()
@export var image_texture : Texture2D :
	set(value):
		image_texture = value
		if image:
			image.texture = image_texture
@export var image_position : Vector2 :
	set(value):
		image_position = value
		if image:
			image.position = image_position
@export var connection_color = Color.WHITE :
	set(value):
		connection_color = value
		if connections_node:
			_update_connections()
@export var connection_radius = 5 :
	set(value):
		connection_radius = value
		if connections_node:
			_update_connections()

@export_group("Grid Editor UI Settings")

@export var ui_name : String
@export var ui_icon : Texture2D

@export_group("Element Attributes")

@export var type : String
@export var subtype : String
@export var params : Dictionary[String, Variant]


### get from terminal / from element

static func get_from_terminal(terminal : Node2D) -> Grid2D_BaseElement:
	return terminal.get_parent().get_parent()

static func get_from_element(element : Node2D) -> Grid2D_BaseElement:
	return element.get_child(0) # child(0) should be Grid2D_BaseElement ...
	# we do not use Grid2D_BaseElement directly as element to hide element configuration


### get value / get netname

func get_value(value_name := "Value") -> String:
	var value_node = get_node(value_name)
	if value_node:
		if value_node.text:
			return value_node.text
		if value_node.placeholder_text:
			return value_node.placeholder_text
	return ""

func get_netname() -> String:
	if type == "NET":
		var value = get_value()
		if value:
			return value
		return params.get("NetName", "")
	return ""

func get_terminals_nets(netlist) -> Array:
	var ret = []
	for terminal in connections_node.get_children():
		var net = netlist.find_net_by_terminal(terminal)
		if net:
			ret.append(net)
		else:
			ret.append(null)
	return ret

func get_terminals_nets_names(netlist) -> Array:
	var ret = []
	var not_connected = []
	var count = 0
	for terminal in connections_node.get_children():
		var net = netlist.find_net_by_terminal(terminal)
		if net:
			ret.append(net.name)
			count += 1
		else:
			var nc_net = "__unused_%s_" % terminal.get_instance_id()
			ret.append(nc_net)
			not_connected.append(nc_net)
	return [count, ret, not_connected]

func get_netlist_entry(netlist, id, value_name := "Value"):
	var nets_on_element = get_terminals_nets_names(netlist)
	var value_node = get_node(value_name)
	if nets_on_element[0] > 0 and value_node and "get_netlist_entry" in value_node:
		var ret = value_node.get_netlist_entry(nets_on_element[1], id)
		ret["not_connected"] = nets_on_element[2]
		return ret
	return null


### process connections list and image

var connections_node : Node2D = null
var image : Sprite2D = null

func _update_connections() -> void:
	for n in connections_node.get_children():
		connections_node.remove_child(n)
		n.queue_free()
	var i = 0
	for point in connections:
		i += 1
		var new_node = Grid2D_ConnectionMarker.new()
		new_node.name = "T" + str(i)
		new_node.color = connection_color
		new_node.radius = connection_radius
		new_node.position = point
		connections_node.add_child(new_node) 

func _ready() -> void:
	if not subtype:
		subtype = type
	
	if has_node("Connections"):
		connections_node = get_node("Connections")
	else:
		connections_node = Node2D.new()
		connections_node.name = "Connections"
		add_child(connections_node)
	
	if has_node("Image"):
		image = get_node("Image")
	else:
		image = Sprite2D.new()
		image.name = "Image"
		add_child(image)
	
	if image_texture:
		image.texture = image_texture
		image.position = image_position
	
	_update_connections()
	on_transform_updated()


# support for temporary disable editing values while placing element

func set_active(val : bool):
	var filter = Control.MOUSE_FILTER_STOP if val else Control.MOUSE_FILTER_IGNORE
	for node in get_children():
		if node is LineEdit:
			node.mouse_filter = filter


### support for prevent text mirror and 180° rotation

var _was_mirrored := false
var _was_180_deg_rotated := false

func on_transform_updated() -> void:
	var element_is_mirrored := (global_scale.y == -1)
	var element_is_180_deg_rorared := (global_rotation > 3 or global_rotation < -3)
	# using compare versus 3 because we use only PI/2 rotation
	# and rotation radian value are wrap on -PI <-> PI
	
	if _was_mirrored != element_is_mirrored or _was_180_deg_rotated != element_is_180_deg_rorared:
		for node in get_children():
			if node is LineEdit or node is OptionButton:
				# clear old fixes
				if _was_180_deg_rotated:
					node.rotation -= PI
					node.position.x -= node.size.x
					if not _was_mirrored:
						node.position.y -= node.size.y
					else:
						node.position.y += node.size.y
				if _was_mirrored:
					node.scale.y *= -1
					node.position.y -= node.size.y
				
				# set new fixes
				if element_is_mirrored:
					node.scale.y *= -1
					node.position.y += node.size.y
				if element_is_180_deg_rorared:
					node.rotation += PI
					node.position.x += node.size.x
					if not element_is_mirrored:
						node.position.y += node.size.y
					else:
						node.position.y -= node.size.y
		_was_mirrored = element_is_mirrored
		_was_180_deg_rotated = element_is_180_deg_rorared
