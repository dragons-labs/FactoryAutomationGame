# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Control

## ui objects for all inputs
@onready var inputs := [$VBoxContainer/VBoxContainer/Input]

## number of active (visible) inputs
@export var number_of_inputs := 2

## ui objects for output
@onready var outputs := [$VBoxContainer/Output/EditableOptionButton]

## number of active (visible) output
var number_of_outputs := 1

## changes acceptance button
@onready var ok_button := %OK

@export var min_number_of_inputs := 2
@export var max_number_of_inputs := 8
@export var all_signals : Array[String]

## emited when popup menu visibility/focus was changed
signal focus_on_popup(focus: bool)

@onready var not_applied_warning := %NotAppliedWarning

func _ready():
	var ui_size = get_viewport().size
	offset_right = ui_size.x
	offset_bottom = ui_size.y
	not_applied_warning.hide()

var _factory_control
var _use_multiple_output

func init(factory_root : Node, inputs_count, use_multiple_output : bool):
	_use_multiple_output = use_multiple_output
	if _use_multiple_output:
		outputs[0].visible = false
		outputs[0] = $VBoxContainer/VBoxContainer/HBoxContainer/Output
		outputs[0].visible = true
	else:
		$VBoxContainer/VBoxContainer/HBoxContainer.visible = false
	
	# the content of `all_signals` array is generated dynamically (via `_on_popup_active`)
	# so we can use the same one for input and output
	outputs[0].items = all_signals
	inputs[0].items = all_signals
	
	if factory_root:
		_factory_control = factory_root.factory_control
		outputs[0].popup_active.connect(_on_popup_active.bind(false))
		inputs[0].popup_active.connect(_on_popup_active)
	outputs[0].value_changed.connect(_on_changed.unbind(1))
	inputs[0].value_changed.connect(_on_changed.unbind(1))
	
	var container := $VBoxContainer/VBoxContainer
	for i in range(1, max_number_of_inputs):
		_duplicate(inputs, container, factory_root)
		if _use_multiple_output:
			_duplicate(outputs, container, factory_root, "Output")
	
	var spin_box = $VBoxContainer/NumberOfInputs/SpinBox
	spin_box.min_value = min_number_of_inputs
	spin_box.max_value = max_number_of_inputs
	spin_box.value = inputs_count
	_update_inputs_number(inputs_count)

func _duplicate(array, parent, factory_root, child = null):
	var dup
	if child:
		dup  = array[0].get_parent().duplicate()
		child = dup.get_node(child)
	else:
		dup = array[0].duplicate()
		child = dup
	child.items = all_signals
	if factory_root:
		child.popup_active.connect(_on_popup_active)
	child.value_changed.connect(_on_changed.unbind(1))
		
	dup.visible = false
	array.append(child)
	parent.add_child(dup)

func _on_popup_active(gui_active: bool, is_input := true) -> void:
	if gui_active:
		focus_on_popup.emit(true)
		all_signals.clear()
		if is_input:
			# we can set "factory output -> circuit input" signals here to avoid
			# (these signals are controlled by other factory blocks)
			# if we want set signal for control circuit we should use GPIOExpander
			# and use its _in signal as output
			for val in _factory_control.input_to_circuit_from_factory:
				all_signals.append(val)
		for val in _factory_control.outputs_from_circuit_to_factory:
			all_signals.append(val)
		for val in _factory_control.internal_signals_values:
			if not val in all_signals:
				all_signals.append(val)
	else:
		focus_on_popup.emit(false)

func _update_inputs_number(new_number_of_inputs: float) -> void:
	number_of_inputs = new_number_of_inputs
	for i in range(0, max_number_of_inputs):
		_set_visible(i, i < number_of_inputs)

func _set_visible(index: int, value: bool):
	inputs[index].visible = value
	if _use_multiple_output:
		outputs[index].get_parent().visible = value

func _on_changed() -> void:
	not_applied_warning.show()
