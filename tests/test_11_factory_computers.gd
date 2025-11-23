# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_TestGame

@warning_ignore_start("redundant_await")

func test_factory_computer_io():
	FAG_WindowManager.set_windows_visibility_recursive(factory_control.computer_control_blocks[0], true)
	
	if not await start_factory():
		return
	
	# set signal value
	factory_control.set_signal_value("io_expander_1_signal_15_in", 3.131)
	assert_factory_signal_value("io_expander_1_signal_15_in").is_equal_approx(3.131, 0.01)
	
	await runner.simulate_frames(1)
	
	# read 00_out and set 01_in via comuputer
	await _enter_command(null, """echo `cat /dev/factory_control/inputs/io_expander_1_signal_15_out` + 0.5 | \
       bc > /dev/factory_control/outputs/io_expander_1_signal_14_in\n""")
	
	# computer need some time to process commands and set output
	# GPIO expander need 1 frame to copy input to iutput
	await runner.simulate_frames(3, 100)
	
	# check results (output of GPIOExpander connected to input driven by computer)
	assert_factory_signal_value("io_expander_1_signal_14_out").is_equal_approx(3.631, 0.01)
	
	await stop_factory()

func test_factory_computer_net():
	await wait_for_computers_ready()
	
	await _enter_command(0, "ifconfig eth0 up 192.168.0.10/24\n")
	await _enter_command(1, "ifconfig eth0 up 192.168.0.11/24\n")
	await _enter_command(2, "ifconfig eth0 up 192.168.0.13/24\n")
	
	await runner.simulate_frames(2, 100)
	
	# we using factory signal for computer command sucess/fail indicators,
	# so first check initial values of those signals
	assert_factory_signal_value("io_expander_1_signal_13_in").is_equal_approx(0.0, 0.01)
	assert_factory_signal_value("io_expander_1_signal_12_in").is_equal_approx(0.0, 0.01)
	
	# execute ping command and get results as factory signals
	# cid=1 should be available, cid=2 should not be available (diffrent "local network")
	await _enter_command(0, "ping -c 1 192.168.0.11 && echo 3.14 > /dev/factory_control/outputs/io_expander_1_signal_13_in\n", true)
	await _enter_command(0, "ping -c 1 192.168.0.12 || echo 2.71 > /dev/factory_control/outputs/io_expander_1_signal_12_in\n", true)
	
	# wait some (long, due to ping timeout) time to execute commands and check results
	await runner.simulate_frames(1, 15000)
	assert_factory_signal_value("io_expander_1_signal_13_in").is_equal_approx(3.14, 0.01)
	assert_factory_signal_value("io_expander_1_signal_12_in").is_equal_approx(2.71, 0.01)

func _enter_command(cid : Variant, cmd : String, keep_open := false) -> void:
	var win
	if cid != null:
		win = factory_control.computer_control_blocks[cid]
		FAG_WindowManager.set_windows_visibility_recursive(win, true)
		win.get_node("ComputerSystemSimulator/TabContainer").current_tab = 0
		await runner.simulate_frames(1)
	
	for c in cmd.to_utf8_buffer():
		runner.simulate_key_pressed(c)
	
	if cid != null and not keep_open:
		await runner.simulate_frames(1)
		FAG_WindowManager.set_windows_visibility_recursive(win, false)
