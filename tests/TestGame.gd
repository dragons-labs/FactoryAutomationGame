# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

"""
Base class for integration test using normal load system for levels and saves
"""

class_name FAG_TestGame
extends GdUnitTestSuite

var runner : GdUnitSceneRunner
var factory_root : Object
var factory_control
var main_menu
var default_save_to_load := "Levels/demo/data1"

@warning_ignore_start("redundant_await")

func load_save(save_to_load := default_save_to_load) -> void:
	print("\n")
	print_rich("[center][color=green]#################################################[/color][/center]")
	print("")
	print_rich("[center][color=green][b]" + get_script().resource_path.rsplit("/", false, 1)[1] + "[/b][/color][/center]")
	print("")
	print_rich("[center][color=green]#################################################[/color][/center]")
	print("\n")
	
	runner = scene_runner("res://Empty.tscn", true)
	factory_root = ApplicationRoot.get_node("FactoryRoot")
	main_menu = ApplicationRoot.get_node("MainMenu")
	factory_control = factory_root.factory_control
	monitor_signals(factory_root, false)
	main_menu.call_deferred("_load_level_or_save", "", save_to_load)
	await runner.simulate_frames(1)
	print_rich("[color=green][b]LOADED[/b][/color]")

func wait_for_computers_ready() -> void:
	while factory_control._computer_systems_simulation_ready_state != factory_control.READY:
		await FAG_Utils.real_time_wait(0.025)

func start_factory() -> bool:
	print_rich("[color=orange_red][b]STARTING[/b][/color]")
	factory_root.run_factory()
	await assert_signal(factory_root).is_emitted('factory_started')
	return not is_failure()

func stop_factory() -> bool:
	print_rich("[color=orange_red][b]STOPPING[/b][/color]")
	factory_root.stop_factory()
	await assert_signal(factory_root).is_emitted('factory_stopped')
	return not is_failure()

func close() -> void:
	print_rich("[color=orange_red][b]CLOSING[/b][/color]")
	await factory_root.close()
	#await assert_signal(factory_root).is_emitted('factory_closed')
	print_rich("[color=green][b]CLOSED[/b][/color]")
	# main_menu.print_orphan_nodes()


var last_signal_value: float

func assert_factory_signal_value(name: String) -> GdUnitFloatAssert:
	last_signal_value = float(factory_control.get_signal_value(name))
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitFloatAssertImpl.gd").new(last_signal_value)

func debug_factory_values(signal_list) -> Dictionary:
	var values = {}
	for signal_name in signal_list:
		values[signal_name] = factory_control.get_signal_value(signal_name)
	print(get_stack()[1]["line"], "→", var_to_str(values))
	return values


func before() -> void:
	await load_save()

func after() -> void:
	await close()
