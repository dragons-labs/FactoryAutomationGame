# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT
# used some code from GdCEF gui example
# (https://github.com/Lecrapouille/gdcef/blob/godot-4.x/addons/gdcef/demos/2D/CEF.gd)
# SPDX-FileCopyrightText: 2022 Alain Duron <duron.alain@gmail.com>
# SPDX-FileCopyrightText: 2022 Quentin Quadrat <lecrapouille@gmail.com>

extends Control

enum ModeEnum {Default, GdCEF, GodotWRY}
@export var backend := ModeEnum.Default :
	set(new_value):
		backend = new_value
		if _display:
			if backend == ModeEnum.Default:
				if "create_browser" in _gdcef:
					backend = ModeEnum.GdCEF
				elif "visible" in _webview:
					backend = ModeEnum.GodotWRY
				else:
					printerr("WARNING: Can't find web browser backend")
			if backend == ModeEnum.GodotWRY:
				_browser = _webview
				_display.visible = false
				#_browser.connect("ipc_message", _on_ipc_message)
				_browser.connect("page_load_started", _on_page_start_loading_wry)
				_browser.connect("page_load_finished", _on_page_loaded_wry)
			elif backend == ModeEnum.GdCEF:
				if "visible" in _webview:
					_webview.visible = false
				_init_GdCEF()
	get():
		return backend

@export var ui_visible := true :
	set(new_value):
		ui_visible = new_value
		if _ui:
			_ui.visible = new_value
	get():
		return ui_visible

@onready var _ui := %UI
@onready var _url_bar := %URL
@onready var _url_status := %URL_Status
@onready var _display := %DisplayTexture
@onready var _webview := %WebView
@onready var _gdcef := %GdCEF

var _browser

func _ready() -> void:
	# call setters
	ui_visible = ui_visible
	backend = backend
	
	_url_status.add_theme_stylebox_override("disabled", _url_status.get_theme_stylebox("normal"))


#region  UI action callbacks

func open_url(new_url: String) -> void:
	_url_status.text = " "
	_url_status.disabled = true
	_browser.load_url(new_url)

func _on_reload_pressed() -> void:
	_browser.reload()

func _on_go_back_pressed() -> void:
	if backend == ModeEnum.GdCEF:
		_browser.previous_page()
	else:
		_browser.eval("history.back()")

func _on_go_next_pressed() -> void:
	if backend == ModeEnum.GdCEF:
		_browser.next_page()
	else:
		_browser.eval("history.forward()")

func _on_enter_pressed() -> void:
	open_url(_url_bar.text)

func _on_stop_pressed() -> void:
	if backend == ModeEnum.GdCEF:
		_browser.stop_loading()
	else:
		_browser.eval("window.stop()")

func _on_url_text_changed(_new_text: String) -> void:
	_url_status.text = tr("BUTTON_ENTER")
	_url_status.tooltip_text = tr("BUTTON_ENTER_TOOLTIP")
	_url_status.disabled = false

#endregion

#region  WebBrowser loading state callbacks

enum {START, DONE_OK, DONE_ERROR}

var curr_state
func _set_ui_loading_state(state, url) -> void:
	_url_bar.text = url
	_url_status.disabled = true
	
	match state:
		START:
			_url_status.text = tr("URL_STATUS_LOADING")
			_url_status.tooltip_text = tr("URL_STATUS_LOADING_TOOLTIP")
			_url_status.add_theme_color_override("font_disabled_color", Color.YELLOW)
		DONE_OK:
			if curr_state == DONE_ERROR:
				return
			_url_status.text = tr("URL_STATUS_OK")
			_url_status.tooltip_text = tr("URL_STATUS_OK_TOOLTIP")
			_url_status.add_theme_color_override("font_disabled_color", Color.GREEN)
		DONE_ERROR:
			_url_status.text = tr("URL_STATUS_ERROR")
			_url_status.tooltip_text = tr("URL_STATUS_ERROR_TOOLTIP")
			_url_status.add_theme_color_override("font_disabled_color", Color.RED)
	curr_state = state

func _on_page_start_loading_gdcef(node):
	_set_ui_loading_state(START, node.get_url())

func _on_page_start_loading_wry(url: String) -> void:
	_set_ui_loading_state(START, url)

func _on_page_loaded_gdcef(http_code, node):
	if http_code >= 400:
		prints("GdCEF loading error http code:", http_code)
		_set_ui_loading_state(DONE_ERROR, node.get_url())
	else:
		_set_ui_loading_state(DONE_OK, node.get_url())

func _on_page_loaded_wry(url: String) -> void:
	_set_ui_loading_state(DONE_OK, url)

func _on_page_failed_loading_gdcef(aborted, msg_err, node):
	prints("GdCEF loading error:", aborted, msg_err)
	_set_ui_loading_state(DONE_ERROR, node.get_url())

#endregion

#region  GdCEF specific

func _init_GdCEF():
	var use_gpu = true
	if OS.has_environment("GDCEF_NO_GPU"):
		print("GdCEF disabling GPU, because GDCEF_NO_GPU env variable is set")
		use_gpu = false
	elif OS.get_name() == "Linux" and OS.execute(FAG_Utils.globalize_path("cef_artifacts/linux/check_libGL.sh"), []) != 0:
		print("GdCEF disabling GPU, because libGL not found")
		use_gpu = false
	if not _gdcef.initialize({
			"incognito":true,
			"locale":"en-US",
			"enable_media_stream": true,
			"artifacts": "res://cef_artifacts",
			"exported_artifacts": FAG_Utils.globalize_path("cef_artifacts"),
			"root_cache_path": FAG_Utils.globalize_path("user://cef_cache"),
			"log_file": FAG_Utils.globalize_path("user://cef.log"),
			"use_gpu": use_gpu,
	}):
		printerr("GdCEF init error: ", _gdcef.get_error())
		return
	
	_browser = _gdcef.create_browser("", _display, {"javascript":true})
	if not _browser:
		printerr("GdCEF create error: ", _gdcef.get_error())
		return
	_browser.connect("on_page_start_loading", _on_page_start_loading_gdcef)
	_browser.connect("on_page_loaded", _on_page_loaded_gdcef)
	_browser.connect("on_page_failed_loading", _on_page_failed_loading_gdcef)
	
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
