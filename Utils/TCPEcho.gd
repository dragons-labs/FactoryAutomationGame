# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node

class_name FAG_TCPEcho

func get_port() -> int:
	if not _listen_port:
		_server.listen(0)
		_listen_port = _server.get_local_port()
		print("TCP echo server started on: ", _listen_port)
	return _listen_port

func stop() -> void:
	for client in _clients:
		client.disconnect_from_host()
	_clients.clear()
	_listen_port = 0
	_server.stop()

var _server := TCPServer.new()
var _listen_port := 0
var _clients : Array[StreamPeerTCP]

# TODO move this to C++ to run as separated thread with `while (true) {...; sleep(1ms);}` to decrease ping value

func _ready() -> void:
	process_physics_priority = -10

func _physics_process(_delta: float) -> void:
	if _server.is_connection_available():
		var client = _server.take_connection()
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
