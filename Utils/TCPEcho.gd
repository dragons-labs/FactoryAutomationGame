# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node

func get_port() -> int:
	if not _listen_port:
		_server.listen(0)
		_listen_port = _server.get_local_port()
		_stop_request = false
		_thread.start(_echo)
		print("TCP echo server started on: ", _listen_port)
	return _listen_port

func stop() -> void:
	for client in _clients:
		client.disconnect_from_host()
	_stop_request = true
	_thread.wait_to_finish()
	_clients.clear()
	_server.stop()
	print("TCP echo server on: ", _listen_port, " is stopped")
	_listen_port = 0

var _server := TCPServer.new()
var _listen_port := 0
var _clients : Array[StreamPeerTCP]
var _stop_request := false
var _thread := Thread.new()

func _echo():
	while true:
		if _server.is_connection_available():
			var client = _server.take_connection()
			client.set_no_delay(true)
			_clients.append(client)
		for client in _clients:
			client.poll()
			var status = client.get_status()
			if status == StreamPeerTCP.STATUS_CONNECTED:
				var data_len = client.get_available_bytes()
				if data_len > 0:
					var data = client.get_data(data_len)
					for client2 in _clients:
						if client2 != client:
							client2.put_data(data[1])
			elif status == StreamPeerTCP.STATUS_ERROR:
				_clients.erase(client)
		if _stop_request:
			return
		OS.delay_usec(500)
