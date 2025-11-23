# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_TestGame

@warning_ignore_start("redundant_await")

func _in_main_menu(open_task_info := true, task_window_is_open := false):
	# task info opened from main menu should be hide by Esc and not visible after exit from main menu
	
	# open main menu and check windows visibility
	runner.simulate_key_pressed(KEY_ESCAPE)
	await runner.simulate_frames(1)
	assert_bool(ApplicationRoot.get_node("ManualBrowser").visible).is_false()
	assert_bool(main_menu.visible).is_true()
	
	if open_task_info:
		# open task info window and check windows visibility
		main_menu._on_show_task_info()
		await runner.simulate_frames(1)
		assert_bool(ApplicationRoot.get_node("ManualBrowser").visible).is_true()
		assert_bool(main_menu.visible).is_true()
		
		# close task info window and check windows visibility
		runner.simulate_key_pressed(KEY_ESCAPE)
		await runner.simulate_frames(1)
		assert_bool(ApplicationRoot.get_node("ManualBrowser").visible).is_false()
		assert_bool(main_menu.visible).is_true()
	
	# close main menu and check windows visibility
	runner.simulate_key_pressed(KEY_ESCAPE)
	await runner.simulate_frames(1)
	assert_bool(ApplicationRoot.get_node("ManualBrowser").visible).is_equal(task_window_is_open)
	assert_bool(main_menu.visible).is_false()

func test_open_from_factory():
	# task info opened from factory should not be closed by Esc, but should pass Esc to MainMenu
	
	# open task info and window check windows visibility
	factory_root.show_task_info()
	await runner.simulate_frames(1)
	assert_bool(ApplicationRoot.get_node("ManualBrowser").visible).is_true()
	assert_bool(main_menu.visible).is_false()
	
	for i in range(3, true):
		await _in_main_menu(i == 1)
	
	ApplicationRoot.get_node("ManualBrowser")._on_close_requested()
	await runner.simulate_frames(1)
	assert_bool(ApplicationRoot.get_node("ManualBrowser").visible).is_false()

func test_open_from_mainmenu():
	await _in_main_menu()
