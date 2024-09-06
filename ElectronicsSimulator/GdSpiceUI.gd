# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends GdSpice


### netlists and measurer list preparation

var measurers := {}
var fuses := []
var used_nets := []
var floating_nets := []
enum Errors {NO_GND, NOT_ACCESSIBLE_NETS}

func reset():
	measurers.clear()
	fuses.clear()
	used_nets.clear()
	floating_nets.clear()
	
	for base_element in oscilloscopes:
		base_element.get_node("Label").text = ""
		oscilloscopes[base_element][0].get_parent().get_parent().queue_free()
	oscilloscopes.clear()
	_last_oscilloscope = null
	_last_on_process_time = -1

func get_ngspice_netlist(
		grid : Grid2D_World,
		external_nets_input_to_circuit_from_factory : Array,
		external_nets_outputs_from_circuit_to_factory : Array,
		external_circuit_entries : Array
	) -> Array:
	
	var circuit := ["factory control"]
	var errors := []
	var netlist := grid.get_netlist()
	var gnd_net := netlist.find_net_by_one_of_names("GND")
	var strong_nets := ["GND"]
	var all_elements := grid.gElements.get_all_elements()
	
	reset()
	
	# create missing GND
	if not gnd_net:
		errors.append(Errors.NO_GND)
		printerr("Warning: No GND net!")
		gnd_net = netlist.new_net()
	
	# fix GND net name
	gnd_net.name = "GND"
	
	# create strong nets (voltage sources) / external outputs
	for ext_output in external_nets_input_to_circuit_from_factory:
		var source_definition = "external" if (len(ext_output) < 3 or ext_output[2] == null) else ext_output[2]
		var internal_resistance = "0.001" if (len(ext_output) < 4 or ext_output[3] == null) else ext_output[3]
		circuit.append("%s __RAW_%s_ 0 %s" % [ext_output[1], ext_output[0], source_definition])
		circuit.append("R_%s_INTERNAL_ __RAW_%s_ %s %s" % [ext_output[1], ext_output[0], ext_output[0], internal_resistance])
		fuses.append(ext_output[1] + "#branch")
		strong_nets.append(ext_output[0])
	
	# create external inputs
	for ext_intput in external_nets_outputs_from_circuit_to_factory:
		if len(ext_intput) == 1 or ext_intput[1] == null:
			circuit.append("R_%s %s GND 10G" % [ext_intput[0], ext_intput[0]])
		else:
			circuit.append("R_%s %s %s" % [ext_intput[0], ext_intput[0], ext_intput[1]])
	
	# create rest of external circuit
	circuit.append_array(external_circuit_entries)
	
	# join nets connected by name with 0V voltage sources
	for i in range(len(netlist._nets)):
		var netname = netlist._nets[i].name
		for j in range(0, len(netlist._nets[i].names)):
			var conn_netname = netlist._nets[i].names[j]
			if netname != conn_netname:
				circuit.append("V_net_connector_%s_%d %s %s dc 0" % [netname, j, netname, conn_netname])
	
	# find all not connected to source or GND (floating) nets
	var nets = netlist.find_floating_nets(strong_nets)
	
	# connect (floating) nets via high impedance to GND
	var rzgnd_number = 0
	for x in nets:
		if x.terminals: # TODO use settings to enable / disable this feature
			circuit.append("RZGND%d %s %s 10G" % [rzgnd_number, x.name, gnd_net.name])
			floating_nets.append_array(x.names)
			rzgnd_number += 1
	
	# generate warning if we have floating nets
	if len(floating_nets) > 0:
		printerr("Warning: No accessible net(s) detected! ", floating_nets)
		errors.append(Errors.NOT_ACCESSIBLE_NETS)

	# create array with names of used (not floating) nets
	for i in range(len(netlist._nets)):
		if not netlist._nets[i].name in floating_nets:
			used_nets.append_array(netlist._nets[i].names)
	
	# add elements from grid editor and create models list
	var models = {}
	for j in range(len(all_elements)):
		var base_element = Grid2D_BaseElement.get_from_element(all_elements[j])
		if "models" in base_element.params:
			models.merge(base_element.params.models)
		var entry = base_element.get_netlist_entry(netlist, j)
		if entry:
			if "circuit" in entry:
				circuit.append_array(entry.circuit)
			if "meters" in entry:
				measurers[base_element] = entry.meters[0]
			if "fuses" in entry:
				fuses.append_array(entry.fuses)
			if "not_connected" in entry: # TODO use settings to enable / disable this feature
				for netname in entry.not_connected:
					circuit.append("RZGND%d %s %s 10G" % [rzgnd_number, netname, gnd_net.name])
					rzgnd_number += 1
	
	# add models to circuit
	for model in models:
		circuit.append(models[model])
	
	circuit.append(".end")
	
	# debug print
	netlist.print()
	print("circuit ", circuit)
	print("fuses ", fuses)
	
	return [circuit, errors]


### measurer graphs (oscilloscopes) system

@onready var _chart_properties := _create_chart_properties()
const _chart_window_packed_scene := preload("res://ElectronicsSimulator/ChartWindow.tscn")
const _colors := [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.CYAN, Color.MAGENTA, Color.WHITE, Color.BLACK]

func _create_chart_properties() -> ChartProperties:
	var chart_properties := ChartProperties.new()
	chart_properties.colors.frame = Color.TRANSPARENT
	chart_properties.colors.background = Color.TRANSPARENT
	chart_properties.colors.grid = Color.DIM_GRAY
	chart_properties.colors.ticks = Color.DIM_GRAY
	chart_properties.colors.text = Color.WHITE
	chart_properties.x_scale = 5
	chart_properties.y_scale = 4
	chart_properties.show_title = false
	chart_properties.show_y_label = false
	chart_properties.show_x_label = false
	chart_properties.show_legend = true
	chart_properties.interactive = true
	chart_properties.max_samples = 300
	return chart_properties

var oscilloscopes = {}
var _oscilloscope_id = 0
var _last_oscilloscope = null

func _create_graph_function(win : Window, win_chart : Chart, base_element : Grid2D_BaseElement) -> Function:
	var value = [0]
	var time = [0]
	if get_simulation_state() in [GdSpice.RUNNING, GdSpice.PAUSED]:
		var data = get_latest_timed_values([measurers[base_element]], _chart_properties.max_samples, 0.01666)
		time = data[0]
		value = data[1]
		# var index = get_last_index()
		# var data_step = 1666 # = (1s/60) / 10us number of simulation step in single game frame
		# time = get_values("time", _chart_properties.max_samples, data_step, index)
		# value = get_values(measurers[base_element], _chart_properties.max_samples, data_step, index)
	
	var title
	if base_element.subtype == "Ammeter":
		for i in range(len(value)):
			value[i] *= 1000
		title = tr("ELECTRONIC_SIMULATION_CURRENT_%dID_WITH_UNIT") % _oscilloscope_id
	else:
		title = tr("ELECTRONIC_SIMULATION_VOLTAGE_%dID_WITH_UNIT") % _oscilloscope_id
	var color = _colors[_oscilloscope_id % len(_colors)]
	
	var win_chart_func := Function.new(
		time, value, title,
		{
			color = color,
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE,
			line_width = 1.3,
			point_size = 2.0
		}
	)
	win_chart_func.set_meta("vector", measurers[base_element])
	if base_element.subtype == "Ammeter":
		win_chart_func.set_meta("ammeter", "mA")
	base_element.get_node("Label").text = "#%d" % _oscilloscope_id
	base_element.get_node("Label").add_theme_color_override("font_color", color)
	_oscilloscope_id+=1
	
	oscilloscopes[base_element] = [win_chart, win_chart_func]
	var base_elements = win.get_meta("base_elements", [])
	base_elements.append(base_element)
	win.set_meta("base_elements", base_elements)
	
	return win_chart_func

func create_oscilloscope(base_element : Grid2D_BaseElement):
	if not base_element in measurers:
		return
	
	var win := _chart_window_packed_scene.instantiate()
	win.position = Vector2i(200, 100)
	win.size = Vector2i(600, 300)
	win.close_requested.connect(_on_win_close.bind(win))
	var win_chart := win.get_node("%Chart")
	win_chart.y_labels_function = func (value):
		return "%.6f" % value
	win_chart.x_labels_function = func (value):
		return "%.4f" % value
	win.get_node("%ApplyButton").connect("pressed", _on_chart_time_range_changed.bind(win, win_chart))
	add_child(win)
	
	if not oscilloscopes:
		_oscilloscope_id = 0
	
	var win_chart_func = _create_graph_function(win, win_chart, base_element)
	win_chart.plot([win_chart_func] as Array[Function], _chart_properties)
	
	return win

func add_graph_to_oscilloscope(win : Window, base_element : Grid2D_BaseElement):
	if not base_element in measurers:
		return
	
	var win_chart = win.get_node("%Chart")
	var win_chart_func := _create_graph_function(win, win_chart, base_element)
	
	var func_arr : Array[Function] = win_chart.functions
	func_arr.append(win_chart_func)
	win_chart.plot(func_arr, _chart_properties)
	# some tricks to fix after reusing plot()
	win_chart._draw()
	await get_tree().create_timer(0.02, true, false, true).timeout
	win_chart._canvas._legend.hide()
	win_chart._canvas._legend.show()

func _on_win_close(win : Window):
	if win == _last_oscilloscope:
		_last_oscilloscope = null
	for base_element in win.get_meta("base_elements"):
		base_element.get_node("Label").text = ""
		oscilloscopes.erase(base_element)
	win.get_parent().remove_child(win)
	win.queue_free()

func on_measurer_click(base_element : Grid2D_BaseElement):
	if base_element in oscilloscopes:
		oscilloscopes[base_element][0].get_parent().get_parent().grab_focus()
	elif _last_oscilloscope and not Input.is_key_pressed(KEY_SHIFT):
		add_graph_to_oscilloscope(_last_oscilloscope, base_element)
		oscilloscopes[base_element][0].get_parent().get_parent().grab_focus()
	else:
		_last_oscilloscope = create_oscilloscope(base_element)


### update oscilloscopes and measurers

var _last_on_process_time = -1

func update_measurers():
	if measurers and get_simulation_state() == GdSpice.RUNNING:
		var time = get_time_simulation()
		if time == _last_on_process_time:
			return
		_last_on_process_time = time
		for base_element in measurers:
			var value = get_last_value(measurers[base_element])
			if base_element.subtype == "Ammeter":
				value *= 1000
			base_element.get_node("Value").text = str(value)
			if base_element in oscilloscopes and not oscilloscopes[base_element][0].get_node("%ManualTimeEnabledButton").button_pressed:
				oscilloscopes[base_element][1].add_point(time, value)
				oscilloscopes[base_element][0].queue_redraw()

func _on_chart_time_range_changed(win : Window, win_chart : Chart):
	var start_time = win.get_node("%StartTime/Slider").value
	var end_time = win.get_node("%EndTime/Slider").value
	var vectors = []
	for function in win_chart.functions:
		vectors.append(function.get_meta("vector"))
	
	var data = get_timed_values_for_time_range(vectors, _chart_properties.max_samples, start_time, end_time)
	if not data:
		printerr("No data for chart. Simulation state: %x" % get_simulation_state())
		_on_win_close(win)
		return
	
	var time = data[0]
	data.remove_at(0)
	
	for i in range(0, len(data)):
		if win_chart.functions[i].has_meta("ammeter"):
			for j in range(len(data[i])):
				data[i][j] *= 1000
		win_chart.functions[i].__x = time
		win_chart.functions[i].__y = data[i]
	
	# some tricks to fix after replace values
	win_chart.x_domain = { lb = time[0], ub = time[len(time)-1], has_decimals = true, fixed = true }
	var y_domain = win_chart.calculate_domain(data)
	y_domain["fixed"] = true
	win_chart.y_domain = y_domain
	
	win_chart.queue_redraw()
