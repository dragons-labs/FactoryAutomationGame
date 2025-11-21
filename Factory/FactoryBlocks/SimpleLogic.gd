# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_FactoryBlock

enum GateType {AND, OR, NOT}

@export var gate_type : GateType
@onready var _gui = $Gui3DNode.gui

func init(factory_root, name = null) -> void:
	_factory_control = factory_root.factory_control
	_factory_builder = factory_root.factory_builder
	if gate_type == GateType.AND:
		_factory_control.factory_tick.connect(_on_factory_process_and)
	elif gate_type == GateType.OR:
		_factory_control.factory_tick.connect(_on_factory_process_or)
	elif gate_type == GateType.NOT:
		_factory_control.factory_tick.connect(_on_factory_process_not)
		_gui.min_number_of_inputs = 1
		_gui.number_of_inputs = 1
	
	_block_config = get_block_config()
	_inputs = _block_config.get("inputs", [])
	_outputs = _block_config.get("outputs", [])
	
	var input_count = mini(len(_inputs), _gui.max_number_of_inputs)
	var output_count = mini(len(_outputs), input_count if gate_type == GateType.NOT else 1)
	
	_gui.init(
		factory_root,
		maxi(1 if gate_type == GateType.NOT else 2, input_count),
		gate_type == GateType.NOT
	)
	
	for i in range(input_count):
		_gui.inputs[i].editbbox.text = _inputs[i]
	for i in range(output_count):
		_gui.outputs[i].editbbox.text = _outputs[i]
	
	_gui.ok_button.pressed.connect(_on_ui_accepted)
	_on_ui_accepted()
	
	# UI focus control
	$Gui3DNode.focus_inside.connect(_on_gui_3d_focus_change.unbind(2))
	_gui.focus_on_popup.connect(_on_gui_3d_focus_change)

func deinit() -> void:
	if gate_type == GateType.AND:
		_factory_control.factory_tick.disconnect(_on_factory_process_and)
	elif gate_type == GateType.OR:
		_factory_control.factory_tick.disconnect(_on_factory_process_or)
	elif gate_type == GateType.NOT:
		_factory_control.factory_tick.disconnect(_on_factory_process_not)
	

func _on_ui_accepted() -> void:
	_outputs = range(0, _gui.number_of_outputs)
	for i in _outputs:
		_outputs[i] = _gui.outputs[i].editbbox.text
	
	_inputs = range(0, _gui.number_of_inputs)
	for i in _inputs:
		_inputs[i] = _gui.inputs[i].editbbox.text
	
	_block_config["outputs"] = _outputs
	_block_config["inputs"] = _inputs
	
	_gui.not_applied_warning.hide()


var _inputs
var _outputs
var _block_config
var _factory_control

func _on_factory_process_and(_time : float, _delta_time : float) -> void:
	var out_val := 3.3
	if not _outputs[0]:
		return
	for signal_name in _inputs:
		if not signal_name or _factory_control.get_signal_value(signal_name) < 2.5:
			out_val = 0
			break
	_factory_control.set_signal_value(_outputs[0], out_val)

func _on_factory_process_or(_time : float, _delta_time : float) -> void:
	var out_val := 0.0
	if not _outputs[0]:
		return
	for signal_name in _inputs:
		if not signal_name or _factory_control.get_signal_value(signal_name) > 2.5:
			out_val = 3.3
			break
	_factory_control.set_signal_value(_outputs[0], out_val)

func _on_factory_process_not(_time : float, _delta_time : float) -> void:
	for i in range(0, len(_inputs)):
		if not _inputs[i] or not _outputs[i]:
			continue
		var input = _factory_control.get_signal_value(_inputs[i])
		_factory_control.set_signal_value(_outputs[i], 0 if input > 2.5 else 3.3)


var _factory_builder
var _last_focus = false
func _on_gui_3d_focus_change(focus: bool) -> void:
	if _last_focus == focus:
		return
	_last_focus = focus
	if focus:
		print("INPUT→3D")
		_factory_builder.disable_input()
		_factory_builder.ui.reset_editor()
	else:
		print("INPUT→GUI")
		_factory_builder.enable_input()
