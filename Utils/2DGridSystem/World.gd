# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT


### Constructor and requires read-only properties values

var gParent : Node2D = null
var gLines : Object = null
var gElements : Object = null

func _init(base_node_, undo_redo_, grid_size_) -> void:
	gParent = base_node_
	
	# init grid line collection
	var lines_node = Node2D.new()
	lines_node.name = "Lines"
	gParent.add_child(lines_node)
	lines_node.owner = gParent
	gLines = FAG_Utils.load(self, "Lines.gd").new(lines_node, gParent, undo_redo_, grid_size_)
	
	# init grid elements collection
	var elements_node = Node2D.new()
	elements_node.name = "Elements"
	gParent.add_child(elements_node)
	elements_node.owner = gParent
	gElements = FAG_Utils.load(self, "Elements.gd").new(elements_node, gParent, undo_redo_, grid_size_)


### save / restore and close

func serialise() -> Dictionary:
	return {
		"Lines": gLines.serialise(),
		"Elements": gElements.serialise()
	}

func restore(data : Dictionary, elements : Dictionary, offset := Vector2.ZERO, duplicate_mode := false) -> void:
	gLines.restore(data.Lines, offset, duplicate_mode)
	gElements.restore(data.Elements, elements, offset, duplicate_mode)

func close() -> void:
	for node in [gLines.main_node, gElements.main_node]:
		for child in node.get_children():
			node.remove_child(child)
			child.queue_free()
	gLines.update_connections()


### Nets system

func get_nets() -> Object:
	var nets : Object = FAG_Utils.load(self, "Nets.gd").new()
	
	# create nets from lines
	for line in gLines.main_node.get_children():
		if nets.find_net_by_line(line):
			continue
		
		var net = nets.new_net()
		
		# add to net all other connected lines
		nets.recursive_add_line_to_net(net, line, gLines)
	
	# add terminals and names to the previously created nets and create terminal-terminal (no lines) nets
	for element in gElements.main_node.get_children():
		var squared_radius = element.connection_radius * element.connection_radius
		var netname = element.get_netname()
		
		for terminal in element.get_node("Connections").get_children():
			# find lines connected to terminal
			# in non-orthogonal mode can connect to more that one line (and connect these lines and nets) so "find all" 
			var conn_lines = gLines.find_all_lines_by_point(terminal.global_position, squared_radius)
			if len(conn_lines) > 0:
				var net : Object = nets.get_merged_net_by_lines(conn_lines)
				net.terminals.append(terminal)
				if netname and not netname in net.names:
					net.names.append(netname) 
			
			# find elements connected directly to terminal (if not found from other element yet)
			elif not nets.find_net_by_terminal(terminal):
				var conn_terminals = gElements.find_all_terminals_by_point(terminal.global_position, squared_radius, element)
				if len(conn_terminals) > 0:
					# get or create new net (using name if provided)
					var net = null
					if netname:
						net = nets.find_net_by_one_of_names(netname)
					if not net:
						net = nets.new_net()
						if netname:
							net.names.append(netname) 
					
					# add names from all directly connected elements
					# (we do not repeat this if/elif branch for other elements)
					for conn_terminal in conn_terminals:
						var conn_netname = FAG_2DGrid_BaseElement.get_from_terminal(conn_terminal).get_netname()
						if conn_netname and not conn_netname in net.names:
							net.names.append(conn_netname)
					
					# add terminals to this net
					net.terminals = conn_terminals
					net.terminals.append(terminal)
	
	# merge nets based on names
	nets._merge_nets_by_names()
	
	nets._set_net_names()
	
	return nets
