# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node

@export var supported_locales: Array[String] = ["en", "pl"]

@export var locale := "" :
	set(value):
		print("set locale to ", value)
		if locale in supported_locales:
			TranslationServer.set_locale(value)
			locale = value
	get():
		print("get locale")
		return TranslationServer.get_locale()

## Name of settings group for this object. This allowing override some properties and input maps.
## Set to empty string to disable using settings (hide in settings menu, disallow override properties and key mapping).
@export var settings_group_name := "LOCALE_SETTINGS_GROUP_NAME"

func _init() -> void:
	var default_locale = supported_locales[0]
	if OS.get_locale() in supported_locales:
		default_locale = OS.get_locale()
	elif OS.get_locale_language() in supported_locales:
		default_locale = OS.get_locale_language()
	elif TranslationServer.get_locale() in supported_locales:
		default_locale = TranslationServer.get_locale()
	print("default locale is: ", default_locale)
	print("supported_locales is: ", supported_locales)
	
	if locale and locale in supported_locales:
		TranslationServer.set_locale(locale)
	else:
		TranslationServer.set_locale(default_locale)
	
	var default_settings = {
		"locale": {
			"default_value": default_locale,
			"ui_name": "LOCALE_SETTINGS_locale",
			"possible_values": supported_locales
		}
	}
	FAG_Settings.register_settings(self, settings_group_name, default_settings, {})
