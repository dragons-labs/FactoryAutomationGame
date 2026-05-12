# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-FileCopyrightText: Copyright (c) 2024 Serhii Snitsaruk
# SPDX-License-Identifier: MIT
# based on addons/limbo_console/LimboConsole.BuiltinCommands.gd and limbo_console.gd

extends Node

func _init() -> void:
	# if this script is attached to main scene (ApplicationRoot) subnodes
	# this will be call before `LimboConsole._ready()`
	
	_greet()
	
func _ready() -> void:
	# if this script is attached to main scene (ApplicationRoot) subnodes
	# this will be call after `LimboConsole._read()` but before deferred calls from `LimboConsole._read()`
	
	LimboConsole.unregister_command("commands")
	LimboConsole.unregister_command("fps_max")
	LimboConsole.unregister_command("fullscreen")
	LimboConsole.unregister_command("vsync")
	LimboConsole.unregister_command("help")
	
	LimboConsole.register_command(cmd_help, "help", "show command info")
	LimboConsole.register_command(LimboConsole.BuiltinCommands.cmd_commands, "cmdlist", "list all commands")
	LimboConsole.register_command(LimboConsole.BuiltinCommands.cmd_fps_max, "graphics fps_max", "limit framerate")
	LimboConsole.register_command(LimboConsole.BuiltinCommands.cmd_fullscreen, "graphics fullscreen", "toggle fullscreen")
	LimboConsole.register_command(LimboConsole.BuiltinCommands.cmd_vsync, "graphics vsync", "adjust V-Sync")

func _input(p_event: InputEvent) -> void:
	# if this script is attached to main scene (ApplicationRoot) subnodes
	# this will be call before `LimboConsole._input()`
	if LimboConsole._control.visible and LimboConsole._is_open and p_event is InputEventKey and p_event.is_pressed():
		if p_event.is_action_pressed("limbo_auto_complete_reverse", false, true):
			LimboConsole._reverse_autocomplete()
		elif p_event.is_action_pressed("limbo_auto_complete_forward", false, true):
			LimboConsole._autocomplete()
		elif p_event.is_action_pressed("limbo_auto_complete_with_list", false, true):
			_autocomplete_with_list()
		else:
			return
		get_viewport().set_input_as_handled() # do not call LimboConsole._input() if we handled input here


static func cmd_help(p_command_name: String = "") -> Error:
	if p_command_name.is_empty():
		LimboConsole.print_line(LimboConsole.format_tip("Type %s to list all available commands." %
				[LimboConsole.format_name("cmdlist")]))
		LimboConsole.print_line(LimboConsole.format_tip("Type %s to get more info about the command." %
				[LimboConsole.format_name("help command")]))
		return OK
	else:
		return LimboConsole.usage(p_command_name)

static func _greet() -> void:
	var message: String = LimboConsole._options.greeting_message
	message = message.format({
		"project_name": ProjectSettings.get_setting("application/config/name"),
		"project_version": ProjectSettings.get_setting("application/config/version"),
		})
	if not message.is_empty():
		if LimboConsole._options.greet_using_ascii_art and LimboConsole.AsciiArt.is_boxed_art_supported(message):
			LimboConsole.print_boxed(message)
			LimboConsole.info("")
		else:
			LimboConsole.info("[b]" + message + "[/b]")
	cmd_help()
	LimboConsole.info(LimboConsole.format_tip("-----"))


## Auto-completes with propositions list on second pressing TAB and without cycles (bash-like)
func _autocomplete_with_list() -> void:
	var matches_count = LimboConsole._autocomplete_matches.size()
	if matches_count == 0:
		_autocomplete_counter = 0
		return
	elif matches_count == 1:
		var match_str: String = LimboConsole._autocomplete_matches[0]
		LimboConsole._fill_entry(match_str + " ")
		LimboConsole._autocomplete_matches.clear()
		LimboConsole._update_autocomplete()
		_autocomplete_counter = 0
	else:
		_autocomplete_counter += 1
		if _autocomplete_counter == 2:
			_autocomplete_counter = 0
			var argc = LimboConsole._entry.text.split(" ").size() - 1
			var sugestions = []
			for sugestion in LimboConsole._autocomplete_matches:
				var sugestion_argv = sugestion.split(" ", true, argc)
				if sugestion_argv.size() > argc:
					sugestions.append(sugestion_argv[argc])
			_print_in_columns(sugestions)

## Prints array of string in constant length columns
func _print_in_columns(strings, separator_size = 3):
	var column_size = 0
	for s in strings:
		if s.length() > column_size:
			column_size = s.length()
	column_size += separator_size
	var string = ""
	for s in strings:
		string += s.rpad(column_size)
	LimboConsole.print_line(string)

var _autocomplete_counter := 0
