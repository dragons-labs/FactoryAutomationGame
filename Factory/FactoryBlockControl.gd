# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

class_name FAG_FactoryBlockControl extends Resource

#region  Block name interface

# called by FactoryBuilder when block name is changed
# NOTE: Not called by FactoryBuilder as a result of block placement
#       In this case only [code]init()[/code] on owner object is called
func set_block_name(new_name):
	_deinit_factory_signals()
	
	if new_name != null:
		_in_game_name = new_name
	elif _in_game_name != null:
		_in_game_name = ""
	# else: keep old name while call with name == null
	
	if _on_name_changed_callback is Callable:
		_on_name_changed_callback.call(_in_game_name)
	elif _on_name_changed_callback and "text" in _on_name_changed_callback:
		_on_name_changed_callback.text = _in_game_name
	
	_init_factory_signals()

func get_block_name():
	return _in_game_name

#endregion

#region  Factory signals interface

func get_signal_name(signal_name: String) -> String:
	if _in_game_name:
		return _in_game_name + "_" + signal_name
	else:
		return signal_name

func set_signal_value(signal_name: String, value: Variant) -> void:
	_factory_control.set_signal_value(get_signal_name(signal_name), value)
	
func get_signal_value(signal_name: String, default: Variant = 0) -> Variant:
	return _factory_control.get_signal_value(get_signal_name(signal_name), default)

func add_signals(block_signals_outputs, block_signals_inputs):
	if _signals_are_registered:
		_factory_control.register_factory_signals(
			block_signals_outputs, block_signals_inputs, [],
			_in_game_name, _using_computer_id,
		)
	_block_signals_outputs.merge(block_signals_outputs)
	_block_signals_inputs.merge(block_signals_inputs)
	
func remove_signals(block_signals_outputs, block_signals_inputs):
	for s in block_signals_outputs:
		_block_signals_outputs.erase(s)
	for s in block_signals_inputs:
		_block_signals_inputs.erase(s)
	if _signals_are_registered:
		_factory_control.unregister_factory_signals(
			block_signals_outputs, block_signals_inputs, [],
			_in_game_name, _using_computer_id,
		)

#endregion

#region  init and deinit

## Constructor - set owner object
func _init(owner):
	_owner_object = owner

## Init FAG_FactoryBlockControl object, set name and register signals
## Arguments:
##  * factory_root - FactoryRoot node to get FactoryControl
##  * name - block name, see [member set_block_name] for details
##  * callback can be callable (will be called with new name as argument) or any object with text property (text property will be set to new name)
##  * block_signals_outputs, block_signals_inputs, circuit_entries - signal description, see FactoryControl.register_factory_signals for details
func init(factory_root, name = null, callback = null, block_signals_outputs := {}, block_signals_inputs := {}, circuit_entries := []) -> void:
	_factory_control = factory_root.factory_control
	
	_on_name_changed_callback = callback
	_block_signals_outputs = block_signals_outputs
	_block_signals_inputs = block_signals_inputs
	_circuit_entries = circuit_entries
	
	_using_computer_id = _owner_object.get_meta("block_config", {}).get("using_computer_id", null)
	
	set_block_name(name)

func _init_factory_signals() -> void:
	_factory_control.register_factory_signals(
		_block_signals_outputs, _block_signals_inputs, _circuit_entries,
		_in_game_name, _using_computer_id,
	)
	_signals_are_registered = true

func _deinit_factory_signals() -> void:
	if not _signals_are_registered:
		return
	_factory_control.unregister_factory_signals(
		_block_signals_outputs, _block_signals_inputs, _circuit_entries,
		_in_game_name, _using_computer_id,
	)
	_signals_are_registered = false

#endregion

#region  private variables

var _factory_control

var _owner_object: FAG_FactoryBlock
var _on_name_changed_callback = null

var _in_game_name: String
var _block_signals_outputs: Dictionary
var _block_signals_inputs: Dictionary
var _circuit_entries: Array
var _signals_are_registered := false
var _using_computer_id = null

#endregion
