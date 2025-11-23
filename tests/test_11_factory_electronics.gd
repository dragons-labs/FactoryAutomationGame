# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_TestGame

@warning_ignore_start("redundant_await")

func before():
	await super()
	if not await start_factory():
		return

func test_circuit_simulation_1():
	# diodes-transistors latch
	
	# check factory signals value
	assert_factory_signal_value("io_expander_1_signal_08_out").is_equal_approx(0.0, 0.01)
	assert_factory_signal_value("io_expander_1_signal_09_out").is_equal_approx(0.0, 0.01)
	
	# set factory signal
	factory_control.set_signal_value("io_expander_1_signal_08_in", 2.5)
	
	# check factory signals value - input to circuit simulation
	await runner.simulate_frames(1)
	assert_factory_signal_value("io_expander_1_signal_08_out").is_equal_approx(2.5, 0.01)
	
	# check factory signals value - output from circuit simulation
	await runner.simulate_frames(1)
	assert_factory_signal_value("io_expander_1_signal_09_in").is_equal_approx(3.3, 0.2)
	
	# set factory signal
	factory_control.set_signal_value("io_expander_1_signal_08_in", 0.0)
	
	# check factory signals value - input to circuit simulation
	await runner.simulate_frames(1)
	assert_factory_signal_value("io_expander_1_signal_08_out").is_equal_approx(0.0, 0.01)
	
	# check factory signals value - output from circuit simulation
	await runner.simulate_frames(1)
	assert_factory_signal_value("io_expander_1_signal_09_in").is_equal_approx(3.3, 0.2)

func test_circuit_simulation_2():
	# RC circuit
	
	# check factory signals value
	assert_factory_signal_value("io_expander_1_signal_10_out").is_equal_approx(0.0, 0.01)
	assert_factory_signal_value("io_expander_1_signal_11_out").is_equal_approx(0.0, 0.01)
	
	# set factory signal
	factory_control.set_signal_value("io_expander_1_signal_10_in", 5.0)
	
	# check factory signals value - input to circuit simulation
	await runner.simulate_frames(1)
	assert_factory_signal_value("io_expander_1_signal_10_out").is_equal_approx(5.0, 0.01)
	
	# check factory signals value - output from circuit simulation
	var prev_value := 0.0
	for i in range(8):
		await runner.simulate_frames(2)
		assert_factory_signal_value("io_expander_1_signal_11_in").is_greater(prev_value)
		prints("↑", last_signal_value, prev_value)
		prev_value = last_signal_value
	
	# set factory signal
	factory_control.set_signal_value("io_expander_1_signal_10_in", 0.0)
	
	# check factory signals value - input to circuit simulation
	await runner.simulate_frames(1)
	assert_factory_signal_value("io_expander_1_signal_10_out").is_equal_approx(0.0, 0.01)
	
	# check factory signals value - output from circuit simulation
	prev_value = 5.0
	for i in range(5):
		await runner.simulate_frames(2)
		assert_factory_signal_value("io_expander_1_signal_11_in").is_less(prev_value)
		prints("↓", last_signal_value, prev_value)
		prev_value = last_signal_value
