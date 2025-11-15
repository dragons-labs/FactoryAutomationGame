# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node

## see [code]Mode[/code] enum for value interpretation (bitmask)
@export var mode := 1
enum Mode {TERMINAL = 1, UI_CODE_EDITOR = 2, GRAPHICAL_VNC = 4}

## path to kernel image
@export var kernel_image_path := "res://qemu_img/linux-noinitrd.bzImage"

## path to (read-only) root fs image
@export var rootfs_image_path := "res://qemu_img/rootfs.img"

## size of memory for emulated system (including kernel memory)
@export var memory_size := "192M"

## gameplay ID used to selecting of computer system set of input/output signals, disk images, etc
@export var computer_system_id := 0

## path to writable root fs image (containing overlay upperdir and workdir)
@export var writable_disk_image := ""

## dictionary of virtfs configuration (mapping tag name to directory path on host system)
@export var virtfs := {}

## initial list controller inputs names (factory can also add controller inputs on fly by settings it value)
@export var computer_input_names := []

## initial list controller outputs name (factory can also add controller inputs on fly by call [code]add_computer_output[/code])
@export var computer_output_names := []

## time (in seconds) to waiting for emulator quit after poweroff command, before will be killed
@export var on_close_timeout := 10

## port number for TCP echo service used for create local network for this computer
## (all computers in one network should use the same echo service on the same tcp port)
@export var tcp_echo_service_port := 0

## emit on receive message bus command
signal msg_bus_command(command : String, sender : Variant)

## emit when reach ready state
signal computer_system_is_run_and_ready()

@onready var terminal := %Terminal
@onready var vnc_client := %VNC_Display
@onready var code_editor := %CodeEditor

enum {IS_NOT_RUNNING=0x10, IS_RUNNING=0x20, IS_STOPPING=0x40, IS_READY=0x01}
var running_state : int = IS_NOT_RUNNING

func configure(system_id, configuration : Dictionary) -> void:
	computer_system_id = system_id
	for setting_name in [
			"kernel_image_path", "rootfs_image_path",
			"writable_disk_image", "virtfs",
			"computer_input_names", "computer_output_names",
			"memory_size",
			"tcp_echo_service_port"
		]:
		if setting_name in configuration:
			set(setting_name, configuration[setting_name])

func start():
	if _pid:
		printerr("Can't start. Simulation already is running.")
		return
	
	running_state = IS_RUNNING
	
	_user_console_server.listen(0, "127.0.0.1")
	_msg_bus_server.listen(0, "127.0.0.1")
	
	var user_port = _user_console_server.get_local_port()
	var msg_port = _msg_bus_server.get_local_port()
	print("Listen on: %d %d for computer system %d" % [user_port, msg_port, computer_system_id])
	
	# configure TabContainer
	
	var parent_min_size : Vector2i
	var number_of_tabs := 0
	
	if mode & Mode.TERMINAL:
		number_of_tabs += 1
		terminal.get_parent().reparent(%TabContainer, false)
		terminal.data_sent.connect(_on_data_sent)
		terminal.size_changed.connect(_on_size_changed)
		terminal.gui_input.connect(_on_gui_mouse_input)
		terminal.visibility_changed.connect(_on_visibility_changed)
		parent_min_size = Vector2i(135,20)
	else:
		terminal.get_parent().reparent(%TabContainer.get_parent(), false)
		terminal.visible = false
	
	if mode & Mode.UI_CODE_EDITOR:
		number_of_tabs += 1
		code_editor.get_parent().reparent(%TabContainer, false)
		# TODO implement "code editor" mode - editing code in UI text editor and run (in terminal?) by UI button
		parent_min_size = Vector2i(300,200)
	else:
		code_editor.get_parent().reparent(%TabContainer.get_parent(), false)
		code_editor.visible = false
	
	var vnc_port = 0
	if mode & Mode.GRAPHICAL_VNC:
		number_of_tabs += 1
		vnc_client.get_parent().reparent(%TabContainer, false)
		vnc_client.reverse = true
		vnc_port = vnc_client.init()
		parent_min_size = Vector2i(740,570)
	else:
		vnc_client.get_parent().reparent(%TabContainer.get_parent(), false)
		vnc_client.visible = false
	
	if number_of_tabs > 1:
		%TabContainer.tabs_visible = true
		%TabContainer.current_tab = 1
	
	if get_parent() is Window:
		# print_verbose("Setting minimum parent size = ", parent_min_size)
		get_parent().min_size = parent_min_size
	
	# start qemu
	
	_pid = _run_qemu(user_port, msg_port, vnc_port)
	print("Computer system emulator %d -> pid = %d "  % [computer_system_id, _pid])

func stop():
	print("Stop computer system emulator %d (pid %d)" % [computer_system_id, _pid])
	if _pid > 0:
		running_state = IS_STOPPING
		if mode & Mode.TERMINAL:
			terminal.data_sent.disconnect(_on_data_sent)
			terminal.size_changed.disconnect(_on_size_changed)
			terminal.gui_input.disconnect(_on_gui_mouse_input)
			terminal.visibility_changed.disconnect(_on_visibility_changed)
		
		send_message_via_msg_bus("request_poweroff")
		
		for x in range(on_close_timeout * 10):
			if not OS.is_process_running(_pid):
				break
			if x % 10 == 0:
				print("Wait for computer system %d (%d) exit ... %d" % [computer_system_id, _pid, x])
			await FAG_Utils.real_time_wait(0.1)
		
		if OS.is_process_running(_pid):
			printerr("Kill computer system emulator %d (pid=%d)" % [computer_system_id, _pid])
			if OS.kill(_pid) != OK:
				printerr("Failed to kill computer system emulator %d (pid=%d)" % [computer_system_id, _pid])
		else:
			print("Computer system %d (%d) is down" % [computer_system_id, _pid])
		
	_pid = 0
	_user_console_stream = null
	_msg_bus_stream = null
	running_state = IS_NOT_RUNNING

func wait_for_stop():
	if running_state & IS_RUNNING:
		stop()
	for x in range(on_close_timeout * 10):
		if running_state == IS_NOT_RUNNING:
			return
		await FAG_Utils.real_time_wait(0.1)

func _run_qemu(user_port, msg_port, vnc_port):
	var args = [
		"-kernel", FAG_Utils.globalize_path(kernel_image_path),
		"-drive",  "file=" + FAG_Utils.globalize_path(rootfs_image_path) + ",index=0,media=disk,if=virtio,read-only=on",
		"-append", "init=/init root=/dev/vda console=ttyS0,115200 quiet",
		"-serial", "tcp:127.0.0.1:%d" % user_port, "-serial", "tcp:127.0.0.1:%d" % msg_port,
		"-nographic", "-m", memory_size,
		# "-nic", "socket,mcast=[ff01::46:41:47:0:1]:4617,model=virtio,mac=52:54:%02x:%02x:%02x:%02x" % [
		# "-netdev", "dgram,id=n1,remote.type=inet,remote.host=::1,remote.port=4617", "-device", "model=virtio,netdev=n1,mac=52:54:%02x:%02x:%02x:%02x" % [
		# NOTE: qemu do not support IPv6 multicast (in socket nor in dgram) and IPv4 mulicast do not provide host-scope address space (like ffx1::/16 in IPv6)
		#       so (to avoid send packets outside host) use tcp with own tcp echo server
		"-nic", "socket,connect=127.0.0.1:%d,model=virtio,mac=52:54:%02x:%02x:%02x:%02x" % [
			tcp_echo_service_port,
			(computer_system_id>>24)&0xff, (computer_system_id>>16)&0xff, (computer_system_id>>8)&0xff, (computer_system_id>>0)&0xff
		]
	]
	
	if OS.get_name() != "Windows":
		args.append("-enable-kvm")
	
	if OS.get_name() != "Windows": # TODO / BUG: no virtfs support under windows → https://gitlab.com/qemu-project/qemu/-/issues/2016
		for virtfs_tag in virtfs:
			args.append("-virtfs")
			args.append("local,path=%s,mount_tag=%s,security_model=mapped" % [FAG_Utils.globalize_path(virtfs[virtfs_tag]), virtfs_tag])
	
	if vnc_port:
		args.append("-vnc")
		args.append("127.0.0.1:%d,reverse=on" % vnc_port)
	if writable_disk_image:
		args.append("-drive")
		args.append("file=" + FAG_Utils.globalize_path(writable_disk_image) + ",index=1,media=disk,if=virtio,read-only=off")
	
	print("Starting qemu with args: ", args)
	
	if OS.get_name() == "Windows":
		return OS.create_process("qemu/qemu-system-x86_64.exe", args)
	else:
		return OS.create_process("qemu-system-x86_64", args)


var _user_console_server := TCPServer.new()
var _user_console_stream : StreamPeerTCP = null
var _msg_bus_server := TCPServer.new()
var _msg_bus_stream : StreamPeerTCP = null
var _msg_buf := ""
var _pid := 0
var _output_values = {}

func _ready() -> void:
	process_physics_priority = -10

func _physics_process(_delta):
	if not _user_console_stream:
		if _user_console_server.is_connection_available():
			_user_console_stream = _user_console_server.take_connection()
			_user_console_server.stop()
	else:
		_user_console_stream.poll()
		if _user_console_stream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			var data_len = _user_console_stream.get_available_bytes()
			if data_len > 0:
				var data = _user_console_stream.get_data(data_len)
				if data[0] != OK:
					printerr("Error in receive console data")
				terminal.write(data[1])
	
	if not _msg_bus_stream:
		if _msg_bus_server.is_connection_available():
			_msg_bus_stream = _msg_bus_server.take_connection()
			_msg_bus_server.stop()
			_on_size_changed(Vector2i(terminal.get_cols(), terminal.get_rows()))
	else:
		_msg_bus_stream.poll()
		if _msg_bus_stream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			var data_len = _msg_bus_stream.get_available_bytes()
			if data_len > 0:
				_msg_buf += _msg_bus_stream.get_utf8_string(data_len)
				var pos = 0
				while pos < len(_msg_buf):
					var npos = _msg_buf.find("\n", pos)
					if npos < 0:
						break
					var cmd = _msg_buf.substr(pos, npos-pos)
					# print_verbose("Computer system ", computer_system_id, " received command: ", cmd)
					if cmd == "ping":
						send_message_via_msg_bus("pong")
					elif cmd == "controller_ready":
						send_message_via_msg_bus("terminal_size_changed %d %d" % [terminal.get_rows(), terminal.get_cols()])
						send_message_via_msg_bus("input_names " + " ".join(computer_input_names))
						send_message_via_msg_bus("output_names " + " ".join(computer_output_names))
						send_message_via_msg_bus("configuration_done")
					elif cmd.begins_with("computer_system_ready"):
						running_state = IS_RUNNING | IS_READY
						print("Computer system (id=%d) is ready" % computer_system_id)
						computer_system_is_run_and_ready.emit()
					elif cmd.begins_with("set_output_value"):
						var cmd_split = cmd.split(" ", 2)
						_output_values[cmd_split[1]] = cmd_split[2]
					elif cmd != "":
						msg_bus_command.emit(cmd, self)
					pos = npos + 1
				_msg_buf = _msg_buf.substr(pos)

func time_step(time : float) -> void:
	send_message_via_msg_bus("time " + str(time))

func is_running_and_ready() -> bool:
	return running_state & IS_READY

func add_computer_output(signal_name : String) -> void:
	send_message_via_msg_bus("add_output " + signal_name)

func remove_computer_output(signal_name : String) -> void:
	send_message_via_msg_bus("remove_output " + signal_name)

func remove_computer_input(signal_name : String) -> void:
	send_message_via_msg_bus("remove_input " + signal_name)

func get_signal_value(signal_name : String, default_value : Variant = 0) -> Variant:
	return _output_values.get(signal_name, default_value)

func set_signal_value(signal_name : String, signal_value : Variant) -> void:
	send_message_via_msg_bus("set_input_value " + signal_name + " " + str(signal_value))

func send_message_via_msg_bus(string):
	if _msg_bus_stream:
		_msg_bus_stream.put_data(string.to_utf8_buffer())
		_msg_bus_stream.put_8(0x0a)

func _on_data_sent(data):
	if _user_console_stream:
		_user_console_stream.put_data(data)

func _on_size_changed(new_size):
	print("Terminal size changed: ", new_size)
	if _msg_bus_stream:
		send_message_via_msg_bus("terminal_size_changed %d %d" % [new_size.y, new_size.x])
		# send resize info on auxiliary channel to call `stty -F /dev/ttyS0 rows $ARG1 cols $ARG2`

func _on_gui_mouse_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		if OS.get_name() == "Linux":
			_user_console_stream.put_data(DisplayServer.clipboard_get_primary().to_utf8_buffer())
		else:
			_user_console_stream.put_data(DisplayServer.clipboard_get().to_utf8_buffer())
		terminal.grab_focus()

func _on_visibility_changed() -> void:
	if terminal.visible:
		terminal.grab_focus()
