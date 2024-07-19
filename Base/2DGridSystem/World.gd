# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

class_name Grid2D_World


### Constructor and requires read-only properties values

var gParent : Node2D = null
var gLines : Grid2D_Lines = null
var gElements : Grid2D_Elements = null

func _init(base_node_, undo_redo_, grid_size_) -> void:
	gParent = base_node_
	
	# init Grid2D_Lines
	var lines_node = Node2D.new()
	lines_node.name = "Lines"
	gParent.add_child(lines_node)
	lines_node.owner = gParent
	gLines = Grid2D_Lines.new(lines_node, gParent, undo_redo_, grid_size_)
	
	# init Grid2D_Elements
	var elements_node = Node2D.new()
	elements_node.name = "Elements"
	gParent.add_child(elements_node)
	elements_node.owner = gParent
	gElements = Grid2D_Elements.new(elements_node, gParent, undo_redo_, grid_size_)


### Save / Restore system

func serialise() -> Dictionary:
	return {
		"Lines": gLines.serialise(),
		"Elements": gElements.serialise()
	}

func restore(data : Dictionary, elements : Dictionary, offset := Vector2(0, 0)) -> void:
	gLines.restore(data.Lines, offset)
	gElements.restore(data.Elements, elements, offset)

func save_tscn(save_file : String) -> bool:
	gElements.store_infos()
	var scene = PackedScene.new()
	var result = scene.pack(gParent)
	if result == OK:
		result = ResourceSaver.save(scene, save_file)
		if result == OK:
			print("Grid 2D saved successfully")
			return true
	return false

func restore_tscn(save_file : String, offset := Vector2(0, 0), ui = null) -> void:
	var saved_data = load(save_file).instantiate()
	
	# restore gLines
	_restore_subnodes(saved_data.get_node("Lines"), gLines.main_node, gParent, offset)
	gLines.update_connections()
	
	# restore gElements
	_restore_subnodes(saved_data.get_node("Elements"), gElements.main_node, gParent, offset, ui)
	
	saved_data.free() # this delete all child of saved_data also
	# (https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#memory-management)

func _restore_subnodes(source : Node2D, destination : Node2D, owner : Node2D, offset := Vector2(0, 0), ui = null) -> void:
	for n in source.get_children():
		if ui:
			var subtype = Grid2D_BaseElement.get_from_element(n).subtype
			if subtype:
				var button = ui._elements_dict[subtype][1]
				if button.visible == false or button.disabled == true:
					# skip (on import operation) elements not currently available
					# (not available on level or quantity limit exceeded)
					continue
		
		var element = n.duplicate()
		if element is Line2D:
			var new_points = []
			new_points.resize(len(element.points))
			for i in range(len(element.points)):
				new_points[i] = element.points[i] + offset
			element.points = new_points
		else:
			element.position += offset
		destination.add_child(element)
		element.owner = owner
		
		if destination == gElements.main_node:
			gElements.restore_infos_and_emit_element_add(element)

func close() -> void:
	_remove_subnodes(gLines.main_node)
	_remove_subnodes(gElements.main_node)
	gLines.update_connections()

func _remove_subnodes(destination : Node2D) -> void:
	for n in destination.get_children():
		destination.remove_child(n)
		n.queue_free()


### Netlists system

class Net:
	var name = ""
	var names = []
	var lines = []
	var terminals = []
	
	func merge(net : Net) -> void:
		for x in net.names:
			if not x in names:
				names.append(x)
		for x in net.lines:
			if not x in lines:
				lines.append(x)
		for x in net.terminals:
			if not x in terminals:
				terminals.append(x)

class NetList:
	var _nets = []
	
	func new_net() -> Net:
		var net = Net.new()
		_nets.append(net)
		return net
	
	func find_net_by_line(line : Line2D) -> Net:
		for net in _nets:
			if line in net.lines:
				return net
		return null
	
	func find_net_by_terminal(terminal : Node2D) -> Net:
		for net in _nets:
			if terminal in net.terminals:
				return net
		return null
	
	func find_net_by_one_of_names(name : String) -> Net:
		for net in _nets:
			if name in net.names:
				return net
		return null
	
	func find_net_by_name(name : String) -> Net:
		for net in _nets:
			if name == net.name:
				return net
		return null
	
	func find_connected_nets(net, nets = []):
		for terminal in net.terminals:
			for net2 in Grid2D_BaseElement.get_from_terminal(terminal).get_terminals_nets(self):
				if net2 and not net2 in nets:
					nets.append(net2)
					find_connected_nets(net2, nets)
		return nets
		
	func find_floating_nets(in_nets):
		var connected_nets = []
		for net in in_nets:
			if net is String:
				net = find_net_by_one_of_names(net)
			if net:
				connected_nets.append_array(find_connected_nets(net))
		var not_connected_nets = []
		for net in _nets:
			if not net in connected_nets:
				not_connected_nets.append(net)
		return not_connected_nets
	
	func recursive_add_line_to_net(net : Net, line : Line2D, all_lines : Grid2D_Lines) -> void:
		net.lines.append(line)
		var squared_radius = line.width * line.width * all_lines.marker_radius_multipler * all_lines.marker_radius_multipler
		# line can connect to other line only on own endpoints, so check both endpoints
		for i in [0, line.get_point_count() - 1]:
			# in non-orthogonal mode can connect to more that one line so "find all" 
			for nextline in all_lines.find_all_lines_by_point(line.get_point_position(i), squared_radius):
				var nextlinenet = find_net_by_line(nextline)
				if not nextlinenet:
					recursive_add_line_to_net(net, nextline, all_lines)
				elif nextlinenet != net:
					net.merge(nextlinenet)
					_nets.erase(nextlinenet)
	
	func get_merged_net_by_lines(lines : Array[Line2D]) -> Net:
		var first_net = find_net_by_line(lines[0])
		if not first_net:
			printerr("Line " + str(lines[0]) + " not in netlist")
			return null
		for i in range(1, len(lines)):
			var next_net = find_net_by_line(lines[i])
			if next_net != first_net:
				first_net.merge(next_net)
				_nets.erase(next_net)
		return first_net
	
	func _merge_nets_by_names() -> void:
		var i = 0
		while i < len(_nets):
			if _nets[i].names:
				for n in _nets[i].names:
					var j = i+1
					while j < len(_nets):
						if n in _nets[j].names:
							_nets[i].merge(_nets[j])
							_nets.erase(_nets[j])
						else:
							j += 1
			i += 1
	
	func _set_net_names() -> void:
		for i in range(len(_nets)):
			var netname : String
			if len(_nets[i].names) == 0:
				netname = "__unnamed_net_%d_" % i
			else:
				netname = _nets[i].names[0]
				netname = netname.replace(" ", "_")
				netname = netname.replace("	", "_")
			
			if find_net_by_name(netname):
				netname = "%s__%d_" % [netname, i]
				var netname2 : String
				var j = 0
				while find_net_by_name(netname2):
					netname2 = "%s__%d_" % [netname, j]
					j += 1
				netname = netname2
			_nets[i].name = netname
	
	func print() -> void:
		for net in _nets:
			print("NET:")
			print("  - name: ", net.name)
			print("  - names: ", net.names)
			print("  - lines: ", net.lines)
			print("  - terminals: ", net.terminals)

func get_netlist() -> NetList:
	var netlist := NetList.new()
	
	# create nets from lines
	for line in gLines.main_node.get_children():
		if netlist.find_net_by_line(line):
			continue
		
		var net = netlist.new_net()
		
		# add to net all other connected lines
		netlist.recursive_add_line_to_net(net, line, gLines)
	
	# add terminals and names to the previously created nets and create terminal-terminal (no lines) nets
	for element in gElements.main_node.get_children():
		var base_element = Grid2D_BaseElement.get_from_element(element)
		var squared_radius = base_element.connection_radius * base_element.connection_radius
		var netname = base_element.get_netname()
		
		for terminal in base_element.get_node("Connections").get_children():
			# find lines connected to terminal
			# in non-orthogonal mode can connect to more that one line (and connect these lines and nets) so "find all" 
			var conn_lines = gLines.find_all_lines_by_point(terminal.global_position, squared_radius)
			if len(conn_lines) > 0:
				var net := netlist.get_merged_net_by_lines(conn_lines)
				net.terminals.append(terminal)
				if netname and not netname in net.names:
					net.names.append(netname) 
			
			# find elements connected directly to terminal (if not found from other element yet)
			elif not netlist.find_net_by_terminal(terminal):
				var conn_terminals = gElements.find_all_terminals_by_point(terminal.global_position, squared_radius, element)
				if len(conn_terminals) > 0:
					# get or create new net (using name if provided)
					var net = null
					if netname:
						net = netlist.find_net_by_one_of_names(netname)
					if not net:
						net = netlist.new_net()
						if netname:
							net.names.append(netname) 
					
					# add names from all directly connected elements
					# (we do not repeat this if/elif branch for other elements)
					for conn_terminal in conn_terminals:
						var conn_netname = Grid2D_BaseElement.get_from_terminal(conn_terminal).get_netname()
						if conn_netname and not conn_netname in net.names:
							net.names.append(conn_netname)
					
					# add terminals to this net
					net.terminals = conn_terminals
					net.terminals.append(terminal)
	
	# merge nets based on names
	netlist._merge_nets_by_names()
	
	netlist._set_net_names()
	
	return netlist
