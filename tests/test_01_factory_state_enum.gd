# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends GdUnitTestSuite

func _check_bits(value: int):
	var bits = []
	for i in range(0,32):
		if value & (1<<i):
			bits.append(i)
	return bits

# check if factory_root.FactoryState are valid bit field enum
# (each value is unique and has exactly one bit set)
func test_factory_state_enum():
	var factory_root := preload("res://Factory/FactoryRoot.gd")
	var values = {}
	for k in factory_root.FactoryState.keys():
		var res = _check_bits(factory_root.FactoryState[k])
		prints(k, factory_root.FactoryState[k], res)
		assert_int(len(res)).is_equal(1)
		if res[0] in values:
			fail("Duplicated bit " + str(res[0]) + " in FactoryState")
		else:
			values[res[0]] = true

	
