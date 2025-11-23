# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_TestGame

@warning_ignore_start("redundant_await")

func test_pause_before_running(wait_fort_start_signal:bool, _test_parameters := [ [false], [true] ]):
	print_rich("[color=orange_red][b]STARTING[/b][/color]")
	prints("  for test with wait_fort_start_signal =", wait_fort_start_signal)
	factory_root.run_factory()
	assert_bool(main_menu.visible).is_false()
	var paused = get_tree().paused
	
	if wait_fort_start_signal:
		print_rich("[color=orange_red][b]WAITING FOR FACTORY START[/b][/color]")
		await assert_signal(factory_root).is_emitted('factory_start')
		paused = get_tree().paused
	
	# open main menu
	runner.simulate_key_pressed(KEY_ESCAPE)
	await runner.simulate_frames(1)
	assert_bool(main_menu.visible).is_true()
	assert_bool(get_tree().paused).is_equal(paused)
	
	# hide main menu
	runner.simulate_key_pressed(KEY_ESCAPE)
	await runner.simulate_frames(1)
	assert_bool(main_menu.visible).is_false()
	assert_bool(get_tree().paused).is_equal(paused)
	
	await assert_signal(factory_root).is_emitted('factory_started')
	await stop_factory()

func test_pause_while_running(factory_is_paused:bool, _test_parameters := [ [false], [true] ]):
	await start_factory()
	await runner.simulate_frames(5)
	if factory_is_paused:
		factory_root.pause_factory()
	await runner.simulate_frames(5)
	assert_bool(get_tree().paused).is_equal(factory_is_paused)
	
	# open main menu
	runner.simulate_key_pressed(KEY_ESCAPE)
	await runner.simulate_frames(1)
	assert_bool(get_tree().paused).is_equal(true)
	
	# hide main menu
	runner.simulate_key_pressed(KEY_ESCAPE)
	await runner.simulate_frames(1)
	assert_bool(get_tree().paused).is_equal(factory_is_paused)
	
	await stop_factory()
