# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends GdUnitTestSuite

func test_jsons():
	const input1 = {
		"aa aa": true,
		"bb(b)": 17.13,
		"x.1": [1, 2.23456, true],
		"x-2": {2.3: "string", "x": 15, 17: 0.0},
		"a": Vector3(1,2,3),
		"b": Vector2(1,2),
		"c": Transform3D.IDENTITY,
		"d": "100k",
		"3u": "10.6M",
		"less typical": {
			Vector3(1,2,3) : {
				[1,2,3]: "test",
				true: 15,
				"Vector2": "test",
				Vector2(0,13): "test",
			},
			Transform3D.IDENTITY: "abc"
		}
	}
	
	var a = input1.duplicate(true)
	var b = FAG_Utils.to_JSON(a)
	var c = FAG_Utils.from_JSON(b)
	
	# check if to_JSON do not modify orginal data
	assert_dict(a).is_equal(input1)
	
	# check if round trip conversion returns data equal to input
	assert_dict(c).is_equal(input1)
	
	# modifiability
	a["a"] = true
	c["a"] = false
	assert_dict(a).is_not_equal(input1)
	assert_dict(c).is_not_equal(input1)
	assert_bool(a["a"]).is_true()
	assert_bool(c["a"]).is_false()
