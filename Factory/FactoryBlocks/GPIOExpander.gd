# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_FactoryBlock

@onready var _block_control = FAG_FactoryBlockControl.new(self)
@onready var _gui = [$Gui3DNode.gui, $Gui3DNode.gui_scene.instantiate()]

func init(factory_root, block_name = null) -> void:
	show_block_ui(null)
	_gui[1].name_label.hide()
	
	_block_control.init(factory_root, block_name, [_gui[0].name_label, _gui[1].name_label])
	_block_control._factory_control.factory_tick.connect(_on_factory_process)
	
	for gui in _gui:
		gui.ok_button.pressed.connect(_on_ui_accepted.bind(gui))
		gui.spin_box.value_changed.connect(_on_spin_box_value_accepted)
	
	_block_config = get_block_config()
	_change_signal_number(_block_config.get("signal_number", 1))
	
	for gui in _gui:
		gui.not_applied_warning.visible = false

func _on_ui_accepted(gui_in : Control) -> void:
	_change_signal_number(gui_in.spin_box.value)
	for gui in _gui:
		gui.not_applied_warning.visible = false

func _on_spin_box_value_accepted(_value) -> void:
	for gui in _gui:
		gui.not_applied_warning.visible = true

var _signals = []
var _block_config

func _on_factory_process(_time : float, _delta_time : float) -> void:
	for sname in _signals:
		var val = _block_control.get_signal_value(sname[0])
		_block_control.set_signal_value(sname[1], val)

func _create_signal_description(i : int, block_signals_outputs : Dictionary, block_signals_inputs : Dictionary) -> void:
	var sname = "signal_" + str(i).pad_zeros(2)
	_signals[i] = [sname+"_in", sname+"_out"]
	block_signals_inputs[sname+"_in"] = [sname+"_@out"]
	block_signals_outputs[sname+"_out"] = [sname+"_@in", "v_"+sname]

func _change_signal_number(new_signal_number : int) -> void:
	for gui in _gui:
		gui.spin_box.value = new_signal_number
	_block_config["signal_number"] = new_signal_number
	var old_signal_number = len(_signals)
	var block_signals_outputs = {}
	var block_signals_inputs = {}
	if new_signal_number > old_signal_number:
		_signals.resize(new_signal_number)
		for i in range(old_signal_number, new_signal_number):
			_create_signal_description(i, block_signals_outputs, block_signals_inputs)
		_block_control.add_signals(block_signals_outputs, block_signals_inputs)
	elif new_signal_number < old_signal_number:
		for i in range(new_signal_number, old_signal_number):
			_create_signal_description(i, block_signals_outputs, block_signals_inputs)
		_block_control.remove_signals(block_signals_outputs, block_signals_inputs)
		_signals.resize(new_signal_number)
	
