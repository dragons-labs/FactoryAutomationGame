# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends HBoxContainer

@export var items : Array[String]

## max size used for clculating popup menu size
## if x <= 0 then use viewport size minus abs of this value 
@export var max_size := Vector2i(0, 0)

## emit on item selected
signal value_changed(value: String)

## emit on popup menu visibility change
## when emitted with `value == true`, emitted before using `items` to display the menu
## (so it's possible update items list in this signal handler)
signal popup_active(value: bool)

@onready var editbbox: LineEdit = $LineEdit
@onready var menubutton: MenuButton = $MenuButton
@onready var popupmenu: PopupMenu = menubutton.get_popup()

func _ready() -> void:
	popupmenu.visibility_changed.connect(_on_popup_visibility_changed)
	popupmenu.id_pressed.connect(_on_item_selected)
	popupmenu.focus_exited.connect(popupmenu.hide)
	if max_size.x <= 0:
		max_size = get_viewport().size + max_size

func _on_item_selected(index: int) -> void:
	popupmenu.set_item_checked(index, true)
	if editbbox.text != popupmenu.get_item_text(index):
		editbbox.text = popupmenu.get_item_text(index)
		value_changed.emit(editbbox.text)

func _generate_items():
	popupmenu.clear()
	var idx := 0
	for val in items:
		popupmenu.add_radio_check_item(val)
		if val == editbbox.text:
			popupmenu.set_item_checked(idx, true)
		idx += 1

func _update_popupmenu_position() -> void:
	var new_pos_x := int(menubutton.global_position.x - popupmenu.size.x + menubutton.size.x)
	popupmenu.position.x = new_pos_x if new_pos_x > 0 else 0
	popupmenu.max_size.x = max_size.x
	
	var new_pos_y := int(menubutton.global_position.y + menubutton.size.y)
	if new_pos_y < max_size.y/2:
		popupmenu.position.y = new_pos_y
		popupmenu.max_size.y = max_size.y - new_pos_y
	else:
		new_pos_y = int(menubutton.global_position.y - popupmenu.size.y)
		popupmenu.position.y = new_pos_y if new_pos_y > 0 else 0
	
	popupmenu.min_size.x = 0
	popupmenu.min_size.y = 0

func _on_popup_visibility_changed() -> void:
	if popupmenu.visible:
		popup_active.emit(true)
		_generate_items()
		call_deferred("_update_popupmenu_position")
	else: 
		popup_active.emit(false)

func _on_line_edit_text_changed(new_text: String) -> void:
	value_changed.emit(new_text)
