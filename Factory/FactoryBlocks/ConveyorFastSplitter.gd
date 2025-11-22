# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_FactoryBlockConveyor

const _block_signals_outputs := {
	"splitter_object_inside"   : ["splitter_object_inside_@in", "v_splitter_object_inside"],
}
const _block_signals_inputs := {
	"splitter_push" : ["splitter_push_@out"],
}

@onready var _block_control = FAG_FactoryBlockControl.new(self)

func init(factory_root, block_name = null):
	_block_control.init(factory_root, block_name, $Label3D, _block_signals_outputs, _block_signals_inputs, [])
	
	_block_control._factory_control.factory_tick.connect(_on_factory_process)
	
	factory_root.factory_stop.connect(_on_factory_start_stop)
	factory_root.factory_start.connect(_on_factory_start_stop)
	
	_area.body_entered.connect(FAG_FactoryBlockConveyor.on_object_enter_block__instant_interaction.bind(self))
	_area.body_exited.connect(FAG_FactoryBlockConveyor.on_object_leave_block.bind(self))
	
	on_transform_update()

func on_transform_update():
	on_block_transform_updated(_area)


@onready var _area := $Area3D

var _pusher : Node3D
var _pusher_area_objects := []
var _pusher_is_active := false

func _on_factory_start_stop() -> void:
	if not is_inside_tree():
		return
	_pusher_is_active = false
	_pusher_area_objects.clear()
	_block_control.set_signal_value("splitter_object_inside", 0)
	_pusher = %Pusher
	_pusher.visible = false
	_pusher.process_mode = PROCESS_MODE_DISABLED

func transfer_object_to_factory_block(node : RigidBody3D):
	# object entered into this block (but it may still be influenced by the previous one, if `belt_list` meta is not empty)
	FAG_FactoryBlockConveyor.accept_object_on_block(node, self, exclusive_owner)


func _on_pusher_area_3d_body_entered(body: Node3D) -> void:
	# object entered into pusher area
	print("object ", body, " inside pusher area")
	_block_control.set_signal_value("splitter_object_inside", 3.3)
	_pusher_area_objects.append(body)

func _on_pusher_area_3d_body_exited(body: Node3D) -> void:
	# object exited pusher area
	print("object ", body, " outside pusher area")
	_pusher_area_objects.erase(body)
	if len(_pusher_area_objects) == 0:
		print("pusher area is empty")
		_block_control.set_signal_value("splitter_object_inside", 0)
	pass # Replace with function body.


func _on_factory_process(_time : float, _delta_time : float):
	if not _pusher:
		return
	if _block_control.get_signal_value("splitter_push") > 2:
		if not _pusher_is_active:
			print("pusher go to active")
			_pusher_is_active = true
			_pusher.visible = true
			_pusher.process_mode = PROCESS_MODE_INHERIT
			for obj in _pusher_area_objects:
				FAG_FactoryBlockConveyor.set_object_free(obj)
				FAG_FactoryBlockConveyor.set_object_speed(obj, Vector3.ZERO)
				FAG_FactoryBlockConveyor.translate_object(obj, quaternion * Vector3(0, 0, -scale.z))
			_pusher_area_objects.clear()
			_block_control.set_signal_value("splitter_object_inside", 0)
	else:
		if _pusher_is_active:
			print("pusher go to inactive")
			_pusher_is_active = false
			_pusher.visible = false
			_pusher.process_mode = PROCESS_MODE_DISABLED
