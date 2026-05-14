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

enum Virtfs_Mode {VIRTIO_9P, VIRTIO_FS}
@export var virtfs_mode: Virtfs_Mode = Virtfs_Mode.VIRTIO_FS

## initial list controller inputs names (factory can also add controller inputs on fly by settings it value)
@export var computer_input_names := []

## initial list controller outputs name (factory can also add controller inputs on fly by call [code]add_computer_output[/code])
@export var computer_output_names := []

## time (in seconds) to waiting for emulator quit after poweroff command, before will be killed
@export var on_close_timeout := 10

## time (in seconds) to waiting for sockets
@export var socket_wait_timeout := 5

## port number for TCP echo service used for create local network for this computer
## (all computers in one network should use the same echo service on the same tcp port)
@export var tcp_echo_service_port := 0

## emit on receive message bus command
signal msg_bus_command(command : String, sender : Variant)

## emit when reach ready state
signal computer_system_is_run_and_ready()

## emit when detected error in system start or running (qemu process not existed)
signal system_crash(computer_system_id: Variant, after_ready: bool)

@onready var terminal := %Terminal
@onready var vnc_client := %VNC_Display
@onready var code_editor := %CodeEditor

enum {IS_NOT_RUNNING=0x10, IS_RUNNING=0x20, IS_STOPPING=0x40, IS_READY=0x01}
var running_state : int = IS_NOT_RUNNING


### configure, start and stop computer system

func configure(system_id, configuration : Dictionary) -> void:
	computer_system_id = system_id
	for setting_name in [
			"mode",
			"kernel_image_path", "rootfs_image_path",
			"writable_disk_image", "virtfs",
			"computer_input_names", "computer_output_names",
			"memory_size",
			"tcp_echo_service_port"
		]:
		if setting_name in configuration:
			set(setting_name, configuration[setting_name])
		if "work_dir" in configuration:
			_work_dir = configuration["work_dir"]
		else:
			_work_dir = DirAccess.create_temp("FAG-qemu")

func async_start():
	if _pid:
		printerr("Can't start. Simulation already is running.")
		return
	
	running_state = IS_RUNNING
	
	_user_console.listen(0, "127.0.0.1")
	_msg_bus.listen(0, "127.0.0.1")
	_qemu_mon.listen(0, "127.0.0.1")
	
	var user_port = _user_console.get_local_port()
	var msg_port = _msg_bus.get_local_port()
	var qemu_mon_port = _qemu_mon.get_local_port()
	print("Listen on: %d %d %d for computer system %d" % [user_port, msg_port, qemu_mon_port, computer_system_id])
	
	# configure TabContainer
	
	var parent_min_size := Vector2i(135,20)
	var number_of_tabs := 0
	
	if mode & Mode.TERMINAL:
		number_of_tabs += 1
		terminal.get_parent().reparent(%TabContainer, false)
		terminal.data_sent.connect(_on_data_sent)
		terminal.size_changed.connect(_on_size_changed)
		terminal.gui_input.connect(_on_gui_mouse_input)
		terminal.visibility_changed.connect(_on_visibility_changed)
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
	else:
		vnc_client.get_parent().reparent(%TabContainer.get_parent(), false)
		vnc_client.visible = false
	
	if number_of_tabs > 1:
		%TabContainer.tabs_visible = true
		%TabContainer.current_tab = 1
	else:
		%TabContainer.tabs_visible = false
		%TabContainer.current_tab = 0
	
	if get_parent() is Window:
		get_parent().min_size = parent_min_size
	
	# start qemu
	
	_pid = await _async_run_qemu(user_port, msg_port, qemu_mon_port, vnc_port)
	if _pid > 0:
		print("Computer system emulator %d -> pid = %d "  % [computer_system_id, _pid])
		$CheckAlive.start()
	else:
		printerr("Computer system emulator %d not started (_run_qemu returned: %d)"  % [computer_system_id, _pid])
		system_crash.emit(computer_system_id, false)

func async_stop():
	print("Stop computer system emulator %d (pid %d)" % [computer_system_id, _pid])
	if _pid > 0:
		running_state = IS_STOPPING
		$CheckAlive.stop()
		if mode & Mode.TERMINAL:
			terminal.data_sent.disconnect(_on_data_sent)
			terminal.size_changed.disconnect(_on_size_changed)
			terminal.gui_input.disconnect(_on_gui_mouse_input)
			terminal.visibility_changed.disconnect(_on_visibility_changed)
		if mode & Mode.GRAPHICAL_VNC:
			vnc_client.stop()
		send_message_via_msg_bus("request_poweroff")
		
		for x in range(on_close_timeout * 10):
			if not OS.is_process_running(_pid):
				break
			if x % 10 == 0:
				print("Wait for computer system %d (%d) exit ... %d" % [computer_system_id, _pid, x])
			await FAG_Utils.real_time_wait(0.1)
		
		if OS.is_process_running(_pid):
			_kill()
		else:
			print("Computer system %d (%d) is down" % [computer_system_id, _pid])
		
	_pid = 0
	running_state = IS_NOT_RUNNING

func async_wait_for_stop():
	if running_state & IS_RUNNING:
		@warning_ignore("missing_await") async_stop()
	for x in range(on_close_timeout * 10):
		if running_state == IS_NOT_RUNNING:
			return
		await FAG_Utils.real_time_wait(0.1)


### start and kill qemu

func _async_run_qemu(user_port, msg_port, qemu_mon_port, vnc_port):
	var args = [
		"-kernel", FAG_Utils.globalize_path(kernel_image_path),
		"-append", "init=/init root=/dev/vda earlyprintk=hvc0 console=hvc0 panic=-1",
		"-drive",  "file=" + FAG_Utils.globalize_path(rootfs_image_path) + ",index=0,media=disk,if=virtio,read-only=on",
		"-device", "virtio-serial",
		"-chardev", "socket,id=serial_console,port=%d,host=127.0.0.1" % user_port, "-device", "virtconsole,chardev=serial_console,name=serial_console",
		"-chardev", "socket,id=serial_control,port=%d,host=127.0.0.1" % msg_port, "-device", "virtserialport,chardev=serial_control,name=serial_control",
		"-chardev", "socket,id=qemu_mon,port=%d,host=127.0.0.1" % qemu_mon_port, "-mon", "chardev=qemu_mon,mode=control,pretty=off",
		"-nographic", "-m", memory_size, "-no-reboot",
		# "-nic", "socket,mcast=[ff01::46:41:47:0:1]:4617,model=virtio,mac=52:54:%02x:%02x:%02x:%02x" % [
		# "-netdev", "dgram,id=n1,remote.type=inet,remote.host=::1,remote.port=4617", "-device", "model=virtio,netdev=n1,mac=52:54:%02x:%02x:%02x:%02x" % [
		# NOTE: qemu do not support IPv6 multicast (in socket nor in dgram) and IPv4 mulicast do not provide host-scope address space (like ffx1::/16 in IPv6)
		#       so (to avoid send packets outside host) use tcp with own tcp echo server
		"-nic", "socket,connect=127.0.0.1:%d,model=virtio,mac=52:54:%02x:%02x:%02x:%02x" % [
			tcp_echo_service_port,
			(computer_system_id>>24)&0xff, (computer_system_id>>16)&0xff, (computer_system_id>>8)&0xff, (computer_system_id>>0)&0xff
		],
	]
	
	if writable_disk_image:
		args += ["-drive", "id=diskrw0,file=" + FAG_Utils.globalize_path(writable_disk_image) + ",index=1,media=disk,if=virtio,cache=none,read-only=off"]
	
	
	if OS.get_name() == "Windows":
		virtfs_mode = Virtfs_Mode.VIRTIO_9P # NOTE: no VIRTIO_FS support under Windows
	
	var virtiofsd_path: String
	if virtfs_mode == Virtfs_Mode.VIRTIO_FS:
		if OS.get_name() != "Windows":
			virtiofsd_path = FAG_Utils.globalize_path("qemu/virtiofsd")
			if not FileAccess.file_exists(virtiofsd_path):
				virtiofsd_path = "/usr/libexec/virtiofsd"
			if not FileAccess.file_exists(virtiofsd_path):
				print("Can't find virtiofsd, switch to virtio_9p mode.")
				virtfs_mode = Virtfs_Mode.VIRTIO_9P
	
	var socket_paths = []
	if virtfs_mode == Virtfs_Mode.VIRTIO_FS:
		args += ["-object", "memory-backend-file,id=mem,size=%s,mem-path=/dev/shm,share=on" % memory_size, "-numa", "node,memdev=mem"]
		var ii := 0
		for virtfs_tag in virtfs:
			var socket_path := "%s/virtiofs_%d_%s_%d" % [_work_dir.get_current_dir(), computer_system_id, virtfs_tag, msg_port]
			
			var virtiofsd_args := ["--cache=always", "--socket-path=%s" % socket_path, "--shared-dir=%s" % FAG_Utils.globalize_path(virtfs[virtfs_tag])]
			var virtiofsd_pid := OS.create_process(virtiofsd_path, virtiofsd_args)
			print("Started virtiofsd pid=", virtiofsd_pid, " path=", virtiofsd_path, " args=", virtiofsd_args)
			_others_pids.append(virtiofsd_pid)
			
			args += ["-chardev", "socket,id=char%d,path=%s" % [ii, socket_path]]
			args += ["-device", "vhost-user-fs-pci,queue-size=1024,chardev=char%d,tag=%s" % [ii, virtfs_tag]]
			
			socket_paths.append(socket_path)
			ii += 1
	elif virtfs_mode == Virtfs_Mode.VIRTIO_9P:
		for virtfs_tag in virtfs:
			args += ["-virtfs", "local,path=%s,mount_tag=%s,security_model=mapped" % [FAG_Utils.globalize_path(virtfs[virtfs_tag]), virtfs_tag]]
	
	
	if vnc_port:
		args += ["-vnc", "127.0.0.1:%d,reverse=on" % vnc_port]
	
	if OS.get_name() != "Windows":
		args += ["-enable-kvm", "-cpu", "host"]
	
	args += ["-machine", "q35"]
	
	args += ["-L", FAG_Utils.globalize_path("qemu/share")]
	
	
	var path: String
	if OS.get_name() == "Windows":
		path = FAG_Utils.globalize_path("qemu/bin/qemu-system-x86_64.exe")
		if not FileAccess.file_exists(path):
			path = "qemu-system-x86_64.exe"
	else:
		path = FAG_Utils.globalize_path("qemu/qemu-system-x86_64")
		if not FileAccess.file_exists(path):
			path = "qemu-system-x86_64"
		else:
			OS.set_environment("LD_LIBRARY_PATH", FAG_Utils.globalize_path("qemu") + ":" +  OS.get_environment("LD_LIBRARY_PATH"))
	
	print("Waiting for sockets")
	for i in range(socket_wait_timeout * 10):
		var all_sockets_ready = true
		for p in socket_paths:
			if not _work_dir.file_exists(p):
				all_sockets_ready = false
				break
		if all_sockets_ready:
			print("All sockets for qemu (computer system ", str(computer_system_id), ") are ready")
			break
		else:
			await FAG_Utils.real_time_wait(0.1)
	
	
	print("Starting qemu (", path, "), with args: ", args)
	return OS.create_process(path, args)

func _kill():
	if OS.is_process_running(_pid):
		printerr("Kill computer system emulator %d (pid=%d)" % [computer_system_id, _pid])
		var ret = OS.kill(_pid)
		if ret != OK and ret != ERR_INVALID_PARAMETER:
			printerr("Failed to kill computer system emulator %d (pid=%d), error code: %d" % [computer_system_id, _pid, ret])
	for p in _others_pids:
		var ret = OS.kill(p)
		if ret != OK and ret != ERR_INVALID_PARAMETER:
			printerr("Failed to kill computer system emulator %d (pid=%d) support process %d, error code: %d" % [computer_system_id, _pid, p, ret])
	_pid = 0


### utils API

func time_step(time : float) -> void:
	send_message_via_msg_bus("time " + str(time))

func is_running() -> bool:
	return running_state & IS_RUNNING

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

func async_save(filepath : String) -> void:
	if not is_running_and_ready():
		_disk_save_status = SaveStatus.FAIL
		return
	if not writable_disk_image:
		_disk_save_status = SaveStatus.NO_DISK
		return
	
	_disk_save_guest_is_ready = false
	_disk_save_status = SaveStatus.IN_PROGRESS
	
	send_message_via_msg_bus("before_save")
	while not _disk_save_guest_is_ready:
		await FAG_Utils.real_time_wait(0.1)
	
	# NOTE: we use qemu `drive-backup` function to export disk image because simple copying leads to corruption of compressed images
	_disk_save_job_id = "diskrw0-backup-%d" % Time.get_ticks_msec()
	send_qemu_command('{ "execute": "drive-backup", "arguments": { "job-id": "' + _disk_save_job_id + '", "device": "diskrw0", "sync": "full", "format": "qcow2", "compress": true, "target": "' + filepath + '" } }')
	while not _disk_save_status:
		await FAG_Utils.real_time_wait(0.1)
	
	send_message_via_msg_bus("after_save")

func get_disk_save_status() -> SaveStatus:
	return _disk_save_status

func send_message_via_msg_bus(string):
	if _msg_bus.is_client_connected():
		_msg_bus.put_data(string.to_utf8_buffer())
		_msg_bus.put_8(0x0a)

func send_qemu_command(command : String):
	prints("send_qemu_command:", command)
	_qemu_mon.put_data(command.to_utf8_buffer())


### _ready, _process and private variables

static var SSTCPServer = load("res://Utils/SingleStreamTCPServer.gd")

var _work_dir : DirAccess = null
var _user_console = SSTCPServer.new()
var _msg_bus = SSTCPServer.new()
var _qemu_mon = SSTCPServer.new()
var _pid := 0
var _others_pids := []
var _output_values := {}

enum SaveStatus {NONE, NO_DISK, IN_PROGRESS, FAIL, DONE}
var _disk_save_guest_is_ready := false
var _disk_save_status : SaveStatus = SaveStatus.NONE
var _disk_save_job_id := ""

func _ready() -> void:
	process_physics_priority = -10
	# do not set focus to tab bar ... it require mouse to switch tabs
	# (because terminal and VNC windows never return focus via keybord)
	%TabContainer.get_tab_bar().focus_mode = 0

func _physics_process(_delta):
	_user_console.process_raw(func (data): terminal.write(data))
	
	_qemu_mon.process_by_line(func (cmd):
		var data = JSON.parse_string(cmd)
		if data:
			if "QMP" in data:
				send_qemu_command('{ "execute": "qmp_capabilities" }')
			if data.get("event", "") == "JOB_STATUS_CHANGE" and data.data.status == "concluded" and data.data.id == _disk_save_job_id:
				_disk_save_status = SaveStatus.DONE
	)
	
	_msg_bus.process_by_line(func (cmd):
		# print_verbose("Computer system ", computer_system_id, " received command: ", cmd)
		if cmd == "ping":
			send_message_via_msg_bus("pong")
		elif cmd == "ready_to_save":
			_disk_save_guest_is_ready = true
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
			if cmd_split[2] == "":
				_output_values.erase(cmd_split[1])
			else:
				_output_values[cmd_split[1]] = cmd_split[2]
		elif cmd != "":
			msg_bus_command.emit(cmd, self)
	)


### signal callbacks

func _on_data_sent(data):
	if _user_console.is_client_connected():
		_user_console.put_data(data)

func _on_size_changed(new_size):
	print("Terminal size changed: ", new_size)
	if _msg_bus.is_client_connected():
		send_message_via_msg_bus("terminal_size_changed %d %d" % [new_size.y, new_size.x])
		# send resize info on auxiliary channel to call `stty -F /dev/ttyS0 rows $ARG1 cols $ARG2`

func _on_gui_mouse_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		if OS.get_name() == "Linux":
			_user_console.put_data(DisplayServer.clipboard_get_primary().to_utf8_buffer())
		else:
			_user_console.put_data(DisplayServer.clipboard_get().to_utf8_buffer())
		terminal.grab_focus()

func _on_visibility_changed() -> void:
	if terminal.visible:
		terminal.grab_focus()

func _on_check_alive_timeout() -> void:
	if not OS.is_process_running(_pid):
		printerr("Computer system emulator %d (pid = %d) crashed"  % [computer_system_id, _pid])
		system_crash.emit(computer_system_id, running_state & IS_READY)
		$CheckAlive.stop()
		running_state = IS_NOT_RUNNING
		_kill()
