# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT
# used some code from GDCef gui example
# (https://github.com/Lecrapouille/gdcef/blob/godot-4.x/addons/gdcef/demos/2D/CEF.gd)
# SPDX-FileCopyrightText: 2022 Alain Duron <duron.alain@gmail.com>
# SPDX-FileCopyrightText: 2022 Quentin Quadrat <lecrapouille@gmail.com>

extends GDCef

@export var display : TextureRect
@export var url : LineEdit
@export var url_status : Button

func open_url(new_url: String) -> void:
	url_status.text = " "
	url_status.disabled = true
	_browser.load_url(new_url)

var _browser

func _ready() -> void:
	if not initialize({
			"incognito":true,
			"locale":"en-US",
			"enable_media_stream": true,
			"artifacts": "res://cef_artifacts",
			"exported_artifacts": FAG_Utils.globalize_path("cef_artifacts" if OS.get_name() != "Windows" else ""), # TODO TEST without "cef_artifacts" dir for Windows platform
	}):
		printerr("GDCef init error: ", get_error())
		return
	
	_browser = create_browser("", display, {"javascript":true})
	if not _browser:
		printerr("GDCef create error: ", get_error())
		return
	_browser.connect("on_page_loaded", _on_page_loaded)
	_browser.connect("on_page_failed_loading", _on_page_failed_loading)
	
	display.resized.connect(_on_resize)
	display.gui_input.connect(_on_input)
	
	url_status.add_theme_stylebox_override("disabled", url_status.get_theme_stylebox("normal"))

func _on_resize():
	_browser.resize(display.get_size())

func _on_go_back_pressed() -> void:
	_browser.previous_page()

func _on_go_next_pressed() -> void:
	_browser.next_page()

func _on_enter_pressed() -> void:
	open_url(url.text)

func _on_reload_pressed() -> void:
	_browser.reload()

func _on_stop_pressed() -> void:
	_browser.stop_loading()

func _on_page_loaded(node):
	url.text = node.get_url()
	url_status.text = tr("URL_STATUS_OK")
	url_status.tooltip_text = tr("URL_STATUS_OK_TOOLTIP")
	url_status.add_theme_color_override("font_disabled_color", Color.GREEN)
	url_status.disabled = true

func _on_page_failed_loading(_aborted, _msg_err, node):
	url.text = node.get_url()
	url_status.text = tr("URL_STATUS_ERROR")
	url_status.tooltip_text = tr("URL_STATUS_ERROR_TOOLTIP")
	url_status.add_theme_color_override("font_disabled_color", Color.RED)
	url_status.disabled = true

func _on_url_text_changed(new_text: String) -> void:
	url_status.text = tr("BUTTON_ENTER")
	url_status.tooltip_text = tr("BUTTON_ENTER_TOOLTIP")
	url_status.disabled = false

var _mouse_pressed := false
func _on_input(event):
	if _browser == null:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_browser.set_mouse_wheel_vertical(2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_browser.set_mouse_wheel_vertical(-2)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_pressed = event.pressed
			if _mouse_pressed:
				_browser.set_mouse_left_down()
			else:
				_browser.set_mouse_left_up()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_mouse_pressed = event.pressed
			if _mouse_pressed:
				_browser.set_mouse_right_down()
			else:
				_browser.set_mouse_right_up()
		else:
			_mouse_pressed = event.pressed
			if _mouse_pressed:
				_browser.set_mouse_middle_down()
			else:
				_browser.set_mouse_middle_up()
	elif event is InputEventMouseMotion:
		if _mouse_pressed:
			_browser.set_mouse_left_down()
		_browser.set_mouse_moved(event.position.x, event.position.y)
	pass

func _input(event):
	if display.has_focus() and event is InputEventKey and _browser != null:
		_browser.set_key_pressed(
			event.unicode if event.unicode != 0 else event.keycode,
			event.pressed, event.shift_pressed, event.alt_pressed,
			event.is_command_or_control_pressed()
		)
		get_viewport().set_input_as_handled()
