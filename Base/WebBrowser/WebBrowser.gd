# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT
# used some code from GDCef gui example
# (https://github.com/Lecrapouille/gdcef/blob/godot-4.x/addons/gdcef/demos/2D/CEF.gd)
# SPDX-FileCopyrightText: 2022 Alain Duron <duron.alain@gmail.com>
# SPDX-FileCopyrightText: 2022 Quentin Quadrat <lecrapouille@gmail.com>

extends Control

enum ModeEnum {Webview, GDCEF}
@export var backend: ModeEnum

@onready var _url_bar := %URL
@onready var _url_status := %URL_Status
@onready var _display := %DisplayTexture
@onready var _webview := %WebView

var _browser

func _ready() -> void:
	if backend == ModeEnum.Webview:
		_browser = _webview
		_display.visible = false
		_display = null
		#_browser.connect("ipc_message", _on_ipc_message)
	
	elif backend == ModeEnum.GDCEF:
		if "visible" in _webview:
			_webview.visible = false
		_webview = null
		_init_GDCef(%GDCef)
	
	_url_status.add_theme_stylebox_override("disabled", _url_status.get_theme_stylebox("normal"))


#region  UI action callbacks

func open_url(new_url: String) -> void:
	_url_status.text = " "
	_url_status.disabled = true
	_browser.load_url(new_url)

func _on_reload_pressed() -> void:
	_browser.reload()

func _on_go_back_pressed() -> void:
	if backend == ModeEnum.GDCEF:
		_browser.previous_page()
	else:
		_browser.eval("history.back()")

func _on_go_next_pressed() -> void:
	if backend == ModeEnum.GDCEF:
		_browser.next_page()
	else:
		_browser.eval("history.forward()")

func _on_enter_pressed() -> void:
	open_url(_url_bar.text)

func _on_stop_pressed() -> void:
	if backend == ModeEnum.GDCEF:
		_browser.stop_loading()
	else:
		_browser.eval("window.stop()")

func _on_url_text_changed(_new_text: String) -> void:
	_url_status.text = tr("BUTTON_ENTER")
	_url_status.tooltip_text = tr("BUTTON_ENTER_TOOLTIP")
	_url_status.disabled = false

#endregion

#region  WebBrowser loading state callbacks

func _on_page_loaded(node):
	_url_bar.text = node.get_url()
	_url_status.text = tr("URL_STATUS_OK")
	_url_status.tooltip_text = tr("URL_STATUS_OK_TOOLTIP")
	_url_status.add_theme_color_override("font_disabled_color", Color.GREEN)
	_url_status.disabled = true

func _on_page_failed_loading(_aborted, _msg_err, node):
	_url_bar.text = node.get_url()
	_url_status.text = tr("URL_STATUS_ERROR")
	_url_status.tooltip_text = tr("URL_STATUS_ERROR_TOOLTIP")
	_url_status.add_theme_color_override("font_disabled_color", Color.RED)
	_url_status.disabled = true

# TODO on start loading

# TODO support on Webview  after merge https://github.com/doceazedo/godot_wry/pull/64

#endregion

#region  GDCef specific

func _init_GDCef(gdcef):
	if not gdcef.initialize({
			"incognito":true,
			"locale":"en-US",
			"enable_media_stream": true,
			"artifacts": "res://cef_artifacts",
			"exported_artifacts": FAG_Utils.globalize_path("cef_artifacts" if OS.get_name() != "Windows" else ""), # TODO TEST without "cef_artifacts" dir for Windows platform
	}):
		printerr("GDCef init error: ", gdcef.get_error())
		return
	
	_browser = gdcef.create_browser("", _display, {"javascript":true})
	if not _browser:
		printerr("GDCef create error: ", gdcef.get_error())
		return
	_browser.connect("on_page_loaded", _on_page_loaded)
	_browser.connect("on_page_failed_loading", _on_page_failed_loading)
	
	_display.resized.connect(_display_on_resize)
	_display.gui_input.connect(_display_on_input)

var _mouse_pressed := false

func _display_on_input(event):
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
	elif event is InputEventKey:
		_browser.set_key_pressed(
			event.unicode if event.unicode != 0 else event.keycode,
			event.pressed, event.shift_pressed, event.alt_pressed,
			event.is_command_or_control_pressed()
		)
	get_viewport().set_input_as_handled()

func _display_on_resize():
	_browser.resize(_display.get_size())

#endregion
