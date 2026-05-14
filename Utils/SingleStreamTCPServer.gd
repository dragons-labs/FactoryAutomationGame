# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends TCPServer

func process_raw(callback : Callable):
	if not _stream:
		if is_connection_available():
			_stream = take_connection()
			stop()
	else:
		_stream.poll()
		if _stream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			var data_len = _stream.get_available_bytes()
			if data_len > 0:
				var data = _stream.get_data(data_len)
				if data[0] != OK:
					printerr("Error in receive data")
				callback.call(data[1])

func process_by_line(callback : Callable):
	if not _stream:
		if is_connection_available():
			_stream = take_connection()
			stop()
	else:
		_stream.poll()
		if _stream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			var data_len = _stream.get_available_bytes()
			if data_len > 0:
				_data_buf += _stream.get_utf8_string(data_len)
				var pos = 0
				while pos < len(_data_buf):
					var npos = _data_buf.find("\n", pos)
					if npos < 0:
						break
					var cmd = _data_buf.substr(pos, npos-pos)
					
					callback.call(cmd)
					
					pos = npos + 1
				_data_buf = _data_buf.substr(pos)

func is_client_connected():
	return _stream != null

func put_data(data):
	_stream.put_data(data)

func put_8(data):
	_stream.put_8(data)

var _stream : StreamPeerTCP = null
var _data_buf : String = ""
