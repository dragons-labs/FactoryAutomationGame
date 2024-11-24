# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends RefCounted
class_name FAG_FactoryBlocksUtils 


static func on_block_transform_updated(factory_block_belt : Area3D):
	var speed = 1.0
	if "speed" in factory_block_belt:
		speed = factory_block_belt.speed
	if factory_block_belt.get_parent().scale.z < 0:
		speed *= -1
	factory_block_belt.belt_speed_vector = factory_block_belt.get_parent().quaternion * factory_block_belt.quaternion * Vector3(speed, 0, 0)
	factory_block_belt.y_top_minus_offset =  factory_block_belt.global_position.y + factory_block_belt.get_child(0).shape.size.y * 0.5 - 0.025


static func _abs_max(a : Variant, b : Variant) -> Variant:
	if abs(a) > abs(b):
		return a
	else:
		return b

static func calculate_object_speed(belts) -> Vector3:
	var speed_vector = Vector3.ZERO
	for belt in belts:
		speed_vector.x = _abs_max(speed_vector.x, belt.belt_speed_vector.x)
		speed_vector.y = _abs_max(speed_vector.y, belt.belt_speed_vector.y)
		speed_vector.z = _abs_max(speed_vector.z, belt.belt_speed_vector.z)
	return speed_vector

static func set_object_speed(node : Node3D, speed_vector : Vector3):
	PhysicsServer3D.body_set_state( node.get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, speed_vector )

static func translate_object(node : Node3D, translate_vector : Vector3):
	var rid = node.get_rid()
	var transform = PhysicsServer3D.body_get_state( rid, PhysicsServer3D.BODY_STATE_TRANSFORM )
	PhysicsServer3D.body_set_state( rid, PhysicsServer3D.BODY_STATE_TRANSFORM, transform.translated(translate_vector) )


static func on_object_enter_block__instant_interaction(node : Node3D, factory_block_belt : Area3D) -> void:
	if node is RigidBody3D:
		# print_verbose("entered [", factory_block_belt, "] ", node)
		
		if node.has_meta("exclusive_belt"):
			node.set_meta("next_belt", factory_block_belt)
		else:
			factory_block_belt.transfer_object_to_factory_block(node)

static func on_object_enter_block__delayed_interaction(node : Node3D, factory_block_belt : Area3D) -> void:
	if node is RigidBody3D:
		# print_verbose("entered [", factory_block_belt, "] ", node)
		node.set_meta("next_belt", factory_block_belt)

static func on_object_leave_block(node : Node3D, factory_block_belt : Area3D) -> void:
	if node is RigidBody3D:
		# print_verbose("exited [", factory_block_belt, "] ", node)
		
		# check if this belt is on node's belts lists
		var belt_list = node.get_meta("belts_list")
		if not belt_list:
			return
		var index_on_belt_list = belt_list.find(factory_block_belt)
		if index_on_belt_list >= 0:
			# remove belt from node's belts list
			belt_list.remove_at(index_on_belt_list)
			node.set_meta("belts_list", belt_list)
			
			# calculate speed (from all belts, after remove from this belt)
			var speed_vector : Vector3
			if len(belt_list) > 0:
				speed_vector = calculate_object_speed(belt_list)
			else:
				node.custom_integrator = false
				# keep small speed value to avoid collisions with this belt (return to this belt)
				speed_vector = factory_block_belt.belt_speed_vector * 0.01
			
			set_object_speed(node, speed_vector)
			
			# remove exclusive owner marker
			if node.get_meta("exclusive_belt", node) == factory_block_belt:
				node.remove_meta("exclusive_belt")
			
			# add to next belt (if was set)
			if node.has_meta("next_belt"):
				node.get_meta("next_belt").transfer_object_to_factory_block(node)
				node.remove_meta("next_belt")
			
		elif node.has_meta("next_belt") and node.get_meta("next_belt") == factory_block_belt:
			node.remove_meta("next_belt")

static func accept_object_on_block(node : Node3D, factory_block_belt : Area3D, exclusive_owner : bool, speed_vector : Variant = null) -> void:
	# print_verbose("adding [", self, "] ", node)
	
	if exclusive_owner:
		node.set_meta("exclusive_belt", factory_block_belt)
	
	# register belt in node's belts list
	var belt_list = node.get_meta("belts_list", [])
	belt_list.append(factory_block_belt)
	node.set_meta("belts_list", belt_list)
	
	# calculate speed (from all belts)
	if speed_vector == null:
		speed_vector = FAG_FactoryBlocksUtils.calculate_object_speed(belt_list)
	
	# fix y position - this fixes the problem of catching quickly falling objects:
	# - we want to have all objects just below the top edge of the trigger (not on top of this belt
	#   StaticBody3D) to avoid collision with other's belt StaticBody3D on belts connections
	# NOTE: this assume:
	#        - object root is RigidBody3D
	#        - object use only one collision shape
	#        - no transforms of this collision shape related to object root
	node.global_position.y = factory_block_belt.y_top_minus_offset + node.shape_owner_get_shape(0, 0).extents.y
	
	# disable force integration and set constant speed
	node.custom_integrator = true
	set_object_speed(node, speed_vector)

static func set_object_free(node : Node3D)-> void:
	if node.has_meta("exclusive_belt"):
		node.remove_meta("exclusive_belt")
	if node.has_meta("next_belt"):
		node.remove_meta("next_belt")
	if node.has_meta("belts_list"):
		node.remove_meta("belts_list")
