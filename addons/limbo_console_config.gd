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
