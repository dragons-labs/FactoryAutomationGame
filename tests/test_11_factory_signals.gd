# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_TestGame

@warning_ignore_start("redundant_await")

func test_signal_propagation():
	if not await start_factory():
		return
	
	factory_control.set_signal_value("io_expander_1_signal_00_in", 4)
	factory_control.set_signal_value("io_expander_1_signal_01_in", 4.5)
	
	# input signal for GPIOExpander is set, but output is still not
	assert_factory_signal_value("io_expander_1_signal_00_in").is_equal_approx(4.0, 0.01)
	assert_factory_signal_value("io_expander_1_signal_00_out").is_equal_approx(0.0, 0.1)
	assert_factory_signal_value("io_expander_1_signal_01_in").is_equal_approx(4.5, 0.01)
	assert_factory_signal_value("io_expander_1_signal_01_out").is_equal_approx(0.0, 0.1)
	
	# AND output should be not updated
	assert_factory_signal_value("custom_signal_1").is_equal_approx(0.0, 0.1)
	
	await runner.simulate_frames(1)
	
	# input and output signals for GPIOExpander are set
	assert_factory_signal_value("io_expander_1_signal_00_in").is_equal_approx(4.0, 0.01)
	assert_factory_signal_value("io_expander_1_signal_00_out").is_equal_approx(4.0, 0.1)
	assert_factory_signal_value("io_expander_1_signal_01_in").is_equal_approx(4.5, 0.01)
	assert_factory_signal_value("io_expander_1_signal_01_out").is_equal_approx(4.5, 0.1)
	
	# AND is after GPIOExpander in scene tree so it should be updated
	assert_factory_signal_value("custom_signal_1").is_equal_approx(3.3, 0.1)
	
	# but NOT is before AND in scene tree so it should be not updated
	assert_factory_signal_value("io_expander_1_signal_03_in").is_equal_approx(3.3, 0.1)
	
	await runner.simulate_frames(1)
	
	# now NOT should be updated too
	assert_factory_signal_value("io_expander_1_signal_03_in").is_equal_approx(0.0, 0.1)
	
	# but GPIOExpander and OR are before NOT in scene tree so they should be not updated
	assert_factory_signal_value("io_expander_1_signal_03_out").is_equal_approx(3.3, 0.1)
	assert_factory_signal_value("io_expander_1_signal_05_in").is_equal_approx(3.3, 0.1)
	
	await runner.simulate_frames(1)
	
	# now GPIOExpander signal driven by NOT should be updated
	assert_factory_signal_value("io_expander_1_signal_03_out").is_equal_approx(0.0, 0.1)
	# but OR output should be not updated
	assert_factory_signal_value("io_expander_1_signal_05_in").is_equal_approx(3.3, 0.1)
	assert_factory_signal_value("io_expander_1_signal_05_out").is_equal_approx(3.3, 0.1)

	await runner.simulate_frames(1)
	
	# now OR and GPIOExpander signal driven by OR should be updated
	assert_factory_signal_value("io_expander_1_signal_05_in").is_equal_approx(0.0, 0.1)
	assert_factory_signal_value("io_expander_1_signal_05_out").is_equal_approx(0.0, 0.1)
