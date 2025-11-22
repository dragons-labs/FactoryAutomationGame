# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Control

# tested with:
#   vncserver -geometry 1024x768 -depth 24 -SecurityTypes None
# from "tigervnc-standalone-server" (1.12.0)

## VNC server host to connect (unless [member reverse] is set)
@export var host := "127.0.0.1"

## VNC server port (not display id) to connect (unless [member reverse] is set)
@export var port := 5901

## act as TCP server not client, use [member host] and [member port] setting for binding
## if port is 0 dynamically allocate port and return it as result of [member init] function
@export var reverse := false

## auto reconnect to VNC server after error
@export var reconnect_on_error := true

## VNC responce timeout
@export var timeout_ms := 1500

## Control node used as display
@export var display : Control = self

signal bell()

func init() -> int:
	var retval = 1
	if reverse:
		_reverse_vnc_server = TCPServer.new()
		_reverse_vnc_server.listen(port, host)
		retval = _reverse_vnc_server.get_local_port()
	else:
		if not _do_connect():
			printerr("[VNC] Init error")
			return 0
	
	display.connect("gui_input", _on_gui_input)
	display.connect("focus_exited", _on_focus_exited)
	display.connect("focus_entered", _on_focus_entered)
	display.connect("mouse_exited", _on_mouse_exited)
	display.connect("mouse_entered", _on_mouse_entered)
	return retval


var _connection : StreamPeerTCP = null
var _reverse_vnc_server : TCPServer = null
var _timeout_start := 0
enum {NONE, CONNECTING, HANDSHAKE, AUTH, INIT, WORKING}
var _state := NONE
var _display_size : Vector2i
var _display_image : Image
var _framebuffer_update_request = null

func _process(_delta : float) -> void:
	if not _connection:
		if _reverse_vnc_server and _reverse_vnc_server.is_connection_available():
			_connection = _reverse_vnc_server.take_connection()
			_connection.set_no_delay(true)
			_connection.big_endian = true;
			_set_state(CONNECTING)
		return
	
	var current_time = Time.get_ticks_msec()
	if current_time - _timeout_start > timeout_ms:
		_error("[VNC] Operation timeout @ state=" + str(_state))
		return
		
	_connection.poll()
	match _state:
		CONNECTING:
			if _connection.get_status() == StreamPeerTCP.STATUS_CONNECTED:
				_set_state(HANDSHAKE)
		HANDSHAKE:
			if _connection.get_available_bytes() >= 12:
				var data = _connection.get_utf8_string(12)
				if data != "RFB 003.003\n" and data != "RFB 003.007\n" and data != "RFB 003.008\n":
					_error("[VNC] Wrong RFB version: " + data)
				else:
					_connection.put_data("RFB 003.003\n".to_utf8_buffer())
					_set_state(AUTH)
		AUTH:
			if _connection.get_available_bytes() >= 4:
				var auth_mode = _connection.get_u32()
				if auth_mode == 2:
					_error("[VNC] Authentication not supported, auth_mode=" + str(auth_mode))
				elif auth_mode != 1:
					_error("[VNC] Authentication error, auth_mode=" + str(auth_mode))
				else:
					_connection.put_u8(1) # shared-flag
					_set_state(INIT)
		INIT:
			if _connection.get_available_bytes() >= 24:
				_display_size = Vector2i(_connection.get_u16(), _connection.get_u16())
				_connection.get_data(_connection.get_available_bytes())
				
				print("[VNC] Display_size is:", _display_size)
				
				_display_image = Image.create( _display_size.x, _display_size.y, false, Image.FORMAT_RGBA8 )
				_display_image.fill(Color.TRANSPARENT)
				display.texture = ImageTexture.create_from_image(_display_image)
				
				var msg_buf = StreamPeerBuffer.new()
				msg_buf.big_endian = true
				
				# Set Pixel Format
				msg_buf.put_u8(0)      # message type
				msg_buf.put_u8(0)      # ?
				msg_buf.put_u8(0)      # ?
				msg_buf.put_u8(0)      # ?
				msg_buf.put_u8(32)     # bits
				msg_buf.put_u8(24)     # depth
				msg_buf.put_u8(1)      # big-endian (network byte order)
				msg_buf.put_u8(1)      # true color
				msg_buf.put_u16(0xff)  # red max
				msg_buf.put_u16(0xff)  # green max
				msg_buf.put_u16(0xff)  # blue max
				msg_buf.put_u8(8)      # red shift
				msg_buf.put_u8(16)     # green shift
				msg_buf.put_u8(24)     # blue shift
				msg_buf.put_u8(0)      # ?
				msg_buf.put_u8(0)      # ?
				msg_buf.put_u8(0)      # ?
				_connection.put_data(msg_buf.data_array)
				msg_buf.clear()
				
				# Set Encodings
				msg_buf.put_u8(2)      # message type
				msg_buf.put_u8(0)      # padding
				msg_buf.put_u16(1)     # number of encodings
				msg_buf.put_u32(0)     # raw
				# msg_buf.put_u32(1)     # copy rectangle
				_connection.put_data(msg_buf.data_array)
				msg_buf.clear()
				
				# prepare and send first update request
				msg_buf.put_u8(3)                # message type
				msg_buf.put_u8(0)                # incremental (0 == whole screen)
				msg_buf.put_u16(0)               # x
				msg_buf.put_u16(0)               # y
				msg_buf.put_u16(_display_size.x) # width
				msg_buf.put_u16(_display_size.y) # height
				_framebuffer_update_request = msg_buf.data_array
				
				_connection.put_data(_framebuffer_update_request)
				_framebuffer_update_request[1] = 1 # incremental (1 == partial)
				
				_set_state(WORKING)
		WORKING:
			var data_len = _connection.get_available_bytes()
			if data_len > 0:
				var msg_type = _connection.get_u8()
				match msg_type:
					0:
						_connection.get_u8()
						var rects_count = _connection.get_u16()
						for r in range(rects_count):
							var x       = _connection.get_u16()
							var y       = _connection.get_u16()
							var width   = _connection.get_u16()
							var height  = _connection.get_u16()
							var enc     = _connection.get_u32();
							
							if enc == 0: # raw
								var data = _connection.get_data(width*height*4)[1]
								for i in range(3, len(data), 4):
									data[i] = 0xff
								var rect_new_img = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)
								_display_image.blit_rect(rect_new_img, Rect2i(0, 0, width, height), Vector2i(x, y))
							else:
								_error("[VNC] Unsupported FramebufferUpdate encoding: " + str(enc))
						for i in range(10):
							_display_image.data.data[20+i] = 0xaa
							_display_image.data.data[10240+i] = 0xaa
						display.texture.update(_display_image)
					1:
						_connection.get_u8()
						_connection.get_u16()
						_connection.get_data( 6 * _connection.get_u16() )
					2:
						# print_verbose("[VNC] Bell")
						bell.emit()
					3:
						_connection.get_u8()
						_connection.get_u16()
						_connection.get_data( _connection.get_u32() )
					_:
						_error("[VNC] Unsupported server message type: " + str(msg_type))
				_set_state(WORKING)
			elif current_time - _timeout_start > 30:
				_connection.put_data(_framebuffer_update_request)

func _send_mouse_event(mouse_position : Vector2i, mouse_button_mask : int) -> void:
	var gd_mouse_button_mask = Input.get_mouse_button_mask()
	
	if gd_mouse_button_mask & MOUSE_BUTTON_MASK_LEFT:
		mouse_button_mask |= 1 << 0
	if gd_mouse_button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		mouse_button_mask |= 1 << 1
	if gd_mouse_button_mask & MOUSE_BUTTON_MASK_RIGHT:
		mouse_button_mask |= 1 << 2
	
	var msg_buf = StreamPeerBuffer.new()
	msg_buf.big_endian = true
	
	msg_buf.put_u8(5)                  # message type
	msg_buf.put_u8(mouse_button_mask)  # button mask
	msg_buf.put_u16(mouse_position.x)  # x position
	msg_buf.put_u16(mouse_position.y)  # y position
	
	_connection.put_data(msg_buf.data_array)

func _send_key_event(event : InputEventKey) -> void:
	# 1. try get from unicode
	var keysym = event.unicode
	if keysym > 0:
		if keysym > 31 && keysym < 256: # use ASCII + LATIN-1 ("Western European") == ISO 8859-1
			# print_verbose("[VNC] Convert " + event.as_text_keycode() + " as ASCII %x" % keysym)
			pass
		elif keysym > 255: # use Unicode for "modern systems"
			keysym += 0x1000000
			# can't use this for non-ASCII subset of ISO8859-1 due to bug in XmbLookupString & Xutf8LookupString
			# (return LATIN-1 string instead of UTF-8 string for 0x1000080 .. 0x10000ff); XLookupString works OK
			# print_verbose("[VNC] Convert " + event.as_text_keycode() + " as Unicode %x" % keysym)
		else:
			keysym = 0
	
	if keysym == 0:
		if event.keycode < 256:
			keysym = event.keycode
		elif event.keycode >= KEY_F1 and event.keycode <= KEY_F35:
			keysym = event.keycode - KEY_F1 + 0xffbe
		elif event.keycode >= KEY_KP_0 and event.keycode <= KEY_KP_9:
			keysym = event.keycode - KEY_KP_0 + 0xffb0
		else:
			match event.keycode:
				KEY_ESCAPE:
					keysym = 0xff1b
				
				KEY_UP:
					keysym = 0xff52
				KEY_DOWN:
					keysym = 0xff54
				KEY_LEFT:
					keysym = 0xff51
				KEY_RIGHT:
					keysym = 0xff53
				
				KEY_HOME:
					keysym = 0xff50
				KEY_END:
					keysym = 0xff57
				KEY_PAGEUP:
					keysym = 0xff55
				KEY_PAGEDOWN:
					keysym = 0xff56
				
				KEY_INSERT:
					keysym = 0xff63
				KEY_DELETE:
					keysym = 0xffff
				KEY_PAUSE:
					keysym = 0xff13
				KEY_SYSREQ:
					keysym = 0xff61
				KEY_PRINT:
					keysym = 0xff61
				
				KEY_SCROLLLOCK:
					keysym = 0xff14
				KEY_CAPSLOCK:
					keysym = 0xffe5
				KEY_NUMLOCK:
					keysym = 0xff7f
				
				KEY_TAB:
					keysym = 0xff09
				KEY_BACKSPACE:
					keysym = 0xff08
				KEY_ENTER:
					keysym = 0xff0d
				KEY_KP_ENTER:
					keysym = 0xff8d
				
				KEY_SHIFT:
					if event.location == KEY_LOCATION_RIGHT:
						keysym = 0xffe2
					else:
						keysym = 0xffe1
				KEY_CTRL:
					if event.location == KEY_LOCATION_RIGHT:
						keysym = 0xffe4
					else:
						keysym = 0xffe3
				KEY_META:
					if event.location == KEY_LOCATION_RIGHT:
						keysym = 0xffec
					else:
						keysym = 0xffeb
				KEY_ALT:
					if event.location == KEY_LOCATION_RIGHT:
						keysym = 0xfe03
					else:
						keysym = 0xffe9
				
				KEY_KP_MULTIPLY:
					keysym = 0xffaa
				KEY_KP_DIVIDE:
					keysym = 0xffaf
				KEY_KP_SUBTRACT:
					keysym = 0xffad
				KEY_KP_ADD:
					keysym = 0xffab
				KEY_KP_PERIOD:
					keysym = 0xffae
				
				_:
					printerr("[VNC] Unknown key mapping for: ", event)
	
	var msg_buf = StreamPeerBuffer.new()
	msg_buf.big_endian = true
	
	msg_buf.put_u8(4)              # message type
	msg_buf.put_u8(event.pressed)  # down flag
	msg_buf.put_u16(0)             # padding
	msg_buf.put_u32(keysym)        # X11 keysym
	
	_connection.put_data(msg_buf.data_array)

func _on_gui_input(event: InputEvent) -> void:
	if not _connection:
		return
	
	if not display.has_focus():
		if event is InputEventMouseButton and event.pressed:
			display.grab_focus()
			if event.button_index == MOUSE_BUTTON_MASK_LEFT:
				# block send activate left button click to vnc server
				return
		else:
			return
	
	var mouse_button_mask = 0
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			mouse_button_mask |= 1 << 3;
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			mouse_button_mask |= 1 << 4;
	
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		_send_mouse_event(display.get_local_mouse_position(), mouse_button_mask)
	elif event is InputEventKey:
		_send_key_event(event)

func _on_focus_exited() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_focus_entered() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_mouse_exited() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_mouse_entered() -> void:
	if display.has_focus():
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _do_connect() -> bool:
	_connection = StreamPeerTCP.new()
	if _connection.connect_to_host(host, port) != OK:
		_error("[VNC] Connection error")
		return false
	else:
		_connection.set_no_delay(true)
		_connection.big_endian = true;
		_set_state(CONNECTING)
		return true

func _set_state(state) -> void:
	_timeout_start = Time.get_ticks_msec()
	_state = state

func _error(message : String) -> void:
	printerr(message)
	push_error(message)
	_connection = null
	_state = NONE
	if (not reverse and reconnect_on_error):
		_do_connect()

func stop():
	_state = NONE
	_connection = null
