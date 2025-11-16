# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

class_name FAG_ConsoleReadSet

var _object = null
var _name : String

func _init(object, name : String, variables : Array[String]):
	_object = object
	_name = name
	
	LimboConsole.register_command(_set_variable, _name + " set", "set variable in " + _name)
	LimboConsole.add_argument_autocomplete_source(_name + " set", 0, func(): return variables )
	
	LimboConsole.register_command(_read_variable, _name + " read", "read variable from " + _name)

func _set_variable(variable: String, value: Variant):
	var res := set_property(_object, variable, value)
	if res != "ok":
		LimboConsole.error("Results: " + res)
	else:
		_read_variable(variable)

func _read_variable(variable: String):
	LimboConsole.info("Variable " + variable + " in " + _name + " is: " + str(_object.get(variable)))


static func set_property(object : Object, name : String, value : Variant) -> String:
	var curr = object.get(name)
	
	match typeof(curr):
		TYPE_NIL:
			return "not found"
		TYPE_BOOL:
			if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
				value = bool(value)
		TYPE_INT:
			if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
				value = int(value)
	
	if typeof(curr) != typeof(value):
		return "invalid type, expect: " + type_string(typeof(curr))
	
	object.set(name, value)
	
	return "ok"
