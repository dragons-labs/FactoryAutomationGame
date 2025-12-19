# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

var _nets = []

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
		for net2 in FAG_2DGrid_BaseElement.get_from_terminal(terminal).get_terminals_nets(self):
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

func recursive_add_line_to_net(net : Net, line : Line2D, all_lines : Object) -> void:
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
