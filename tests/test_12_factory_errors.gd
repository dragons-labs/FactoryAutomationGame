# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_TestGame

@warning_ignore_start("redundant_await")

func _open_windows():
	# open some windows
	FAG_WindowManager.set_windows_visibility_recursive(factory_control.circuit_simulator_window, true)
	FAG_WindowManager.set_windows_visibility_recursive(factory_control.computer_control_blocks[0], true)
	factory_root.show_task_info()
	
	# check if windows are opened
	await runner.simulate_frames(1)
	assert_bool(factory_control.circuit_simulator_window.visible).is_true()
	assert_bool(factory_control.circuit_simulator_window.visible).is_true()
	assert_bool(ApplicationRoot.get_node("ManualBrowser").visible).is_true()

func _check_visible(title = null):
	# check if error mesage is visible
	await runner.simulate_frames(1)
	assert_bool(factory_root.get_node("FactoryUI/Message").visible).is_true()
	var text = factory_root.get_node("FactoryUI/Message/PanelContainer/MarginContainer/VBoxContainer/Message_Title").text
	if title != null:
		assert_str(text).is_equal(tr(title))
	
	# also all windows should be hidden
	assert_bool(factory_control.circuit_simulator_window.visible).is_false()
	assert_bool(factory_control.circuit_simulator_window.visible).is_false()
	assert_bool(ApplicationRoot.get_node("ManualBrowser").visible).is_false()
	
	return text

func before_test() -> void:
	print_rich("[color=green][b]RELOAD[/b][/color]")
	await main_menu._load_level_or_save("", default_save_to_load)
	await runner.simulate_frames(1)
	print_rich("[color=green][b]LOADED[/b][/color]")

func test_error_on_circiut_init():
	# broke some element
	for n in factory_control.get_node("ElectronicsSimulatorWindow/ElectronicsSimulator/GridEditor/Nodes/Elements").get_children():
		if n.type == "Diode":
			n.params.clear()
	
	# open some windows and start factory
	await _open_windows()
	factory_root.run_factory()
	
	# wait for error signal from simulation and check error
	await assert_signal(factory_control.circuit_simulator).is_emitted('simulation_error')
	await _check_visible("FACTORY_ERROR_TITLE")
	
	await assert_signal(factory_root).is_emitted('emergency_stopped') # TODO BUG https://github.com/MikeSchulze/gdUnit4/issues/1002

func test_error_short_circuit():
	# add short circiut
	factory_control.circuit_simulator.grid_editor.grid.restore(
		{ "Elements": [
			{ "position": Vector2(-100.0, -80.0), "rotation": 0.0, "scale": Vector2(1.0, 1.0), "type": "NetConnector", "values": { "Value": "Vcc" } },
			{ "position": Vector2(-100.0, -80.0), "rotation": 0.0, "scale": Vector2(1.0, 1.0), "type": "GND", "values": {  } }
		], "Lines": [] },
		factory_control.circuit_simulator.grid_editor.ui._elements_dict
	)
	
	# open some windows and start factory
	await _open_windows()
	factory_root.run_factory()
	
	# wait for error signal from simulation and check error
	#await assert_signal(factory_control.circuit_simulator).is_emitted('overcurrent_protection')
	await assert_signal(factory_root).is_emitted('emergency_stopped')
	await _check_visible("FACTORY_OVERCURRENT_ERROR_TITLE")
