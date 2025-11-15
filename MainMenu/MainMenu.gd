# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends CanvasLayer

const SAVE_DIR := "user://saves/"

enum Mode {NORMAL, LOAD, LOAD_SAVE, WRITE_SAVE, SETTINGS, LOADING}
var _current_mode : Mode

@export var _factory_root : Node3D
@export var _settings_order : Array[String]

func _set_mode(mode : Mode) -> void:
	_current_mode = mode
	%Buttons.hide()
	%LoadDialog.hide()
	%SettingsDialog.hide()
	%Loading.hide()
	match _current_mode:
		Mode.NORMAL:
			var factory_is_loaded = _factory_root.is_loaded()
			%Buttons/Resume.disabled = not factory_is_loaded
			%Buttons/SaveGame.disabled = not factory_is_loaded
			%Buttons/ShowInfo.text = "MAIN_MENU_TASK_INFO" if factory_is_loaded else "MAIN_MENU_MANUAL"
			%Buttons.show()
		Mode.LOAD:
			%NewSaveSlot.hide()
			%LoadDialog/Buttons/Save.hide()
			%LoadDialog/Buttons/Load.show()
			%LoadDialog.show()
		Mode.LOAD_SAVE:
			%NewSaveSlot.hide()
			%LoadDialog/Buttons/Save.hide()
			%LoadDialog/Buttons/Load.show()
			%LoadDialog.show()
		Mode.WRITE_SAVE:
			%NewSaveSlot/NewSaveSlotName.text = ""
			%NewSaveSlot.show()
			%LoadDialog/Buttons/Save.show()
			%LoadDialog/Buttons/Load.hide()
			%LoadDialog.show()
		Mode.SETTINGS:
			%SettingsDialog.show()
		Mode.LOADING:
			%Loading.show()

func _on_load_level_pressed() -> void:
	item_list.clear()
	%LoadDialog_ItemInfo.text = ""
	
	var lang = TranslationServer.get_locale()
	var fallback_lang = ProjectSettings.get("internationalization/locale/fallback")
	var game_progress = FAG_Utils.load_from_json_file(_factory_root.GAME_PROGRESS_SAVE)
	
	for file_name in DirAccess.get_files_at(_factory_root.LEVELS_DIR):
		if file_name.ends_with(".json"):
			var levels = FAG_Utils.load_from_json_file(_factory_root.LEVELS_DIR + file_name)
			for level_id in levels:
				if not levels[level_id].unlocked_by or levels[level_id].unlocked_by.any(
					func(levels_set): return levels_set.all(
						func(level): return game_progress.finished_levels.has(level)
					)
				):
					var index = item_list.add_item(
						FAG_Utils.get_with_fallback(levels[level_id].name, lang, fallback_lang)
					)
					item_list.set_item_metadata(index, {
						"id": level_id,
						"description": FAG_Utils.get_with_fallback(levels[level_id].description, lang, fallback_lang),
						"stats": game_progress.finished_levels.get(level_id, {})
					})
	
	_set_mode(Mode.LOAD)

func _on_save_game_pressed() -> void:
	_list_saves()
	_set_mode(Mode.WRITE_SAVE)

func _on_load_save_pressed() -> void:
	_list_saves()
	_set_mode(Mode.LOAD_SAVE)

func _on_show_task_info() -> void:
	FAG_Settings.get_root_subnode("%Manual").show_info(_factory_root.level_scene_node, _factory_root.GAME_PROGRESS_SAVE)

func _on_settings_pressed() -> void:
	var screen_size := Vector2(get_tree().root.size)
	var relative_size := Vector2(0.55, 0.55)
	%SettingsDialog.custom_minimum_size = screen_size * relative_size
	#%SettingsDialog.position = screen_size * (Vector2(1, 1)-relative_size) * 0.5
	FAG_Settings.reinit_settings_ui(%SettingsList, %KeyReampInfo, _settings_order)
	_set_mode(Mode.SETTINGS)


### "Settings" submenu support (also in `_input` and `_unhandled_input`)

func _on_settings_cancel_pressed() -> void:
	FAG_Settings.cancel_settings_changes()
	_set_mode(Mode.NORMAL)

func _on_settings_reset_pressed() -> void:
	FAG_Settings.reset_to_default_all()
	_on_settings_pressed()

func _on_settings_ok_pressed() -> void:
	FAG_Settings.accept_settings_changes()
	_set_mode(Mode.NORMAL)

var _last_event_to_remap
func _on_action_remap_ok_pressed() -> void:
	FAG_Settings._on_action_remap_finish(_last_event_to_remap)

func _on_action_remap_remove_pressed() -> void:
	FAG_Settings._on_action_remap_finish(null)

func _on_action_remap_cancel_pressed() -> void:
	%KeyReampInfo.hide()


### "Load" submenu support

func _on_item_list_item_selected(index: int) -> void:
	if _current_mode == Mode.LOAD:
		var level_info = item_list.get_item_metadata(index)
		%LoadDialog_ItemInfo.text = level_info.description + "\n\n" + _factory_root.stats2string(level_info.stats)
	elif _current_mode == Mode.LOAD_SAVE:
		var metadata = item_list.get_item_metadata(index)
		var save_info = FAG_Utils.load_from_json_file(metadata.path + _factory_root.SAVE_INFO_FILE)
		metadata["level"] = save_info.level
		%LoadDialog_ItemInfo.text = _factory_root.stats2string(save_info.stats)

func _on_load_pressed() -> void:
	var selected = item_list.get_selected_items()
	if len(selected) > 0:
		%Loading.show()
		FAG_WindowManager.cancel_hideen_by_escape()
		await _factory_root.close()
		if _current_mode == Mode.LOAD:
			var level_info = item_list.get_item_metadata(selected[0])
			_factory_root.load_level(level_info.id)
		elif _current_mode == Mode.LOAD_SAVE:
			var metadata = item_list.get_item_metadata(selected[0])
			_factory_root.restore(metadata.path)
		_factory_root.set_visibility(true)
		_hide()

var _save_path_to_confirm : String
func _on_save_pressed() -> void:
	var selected = item_list.get_selected_items()
	if len(selected) > 0:
		var save_name = item_list.get_item_text(selected[0])
		var save_dir = item_list.get_item_metadata(selected[0]).path
		if FileAccess.file_exists(save_dir + _factory_root.SAVE_INFO_FILE):
			_save_path_to_confirm = save_dir
			%OverwriteConfirmationDialog.dialog_text = tr("MAIN_MENU_SAVE_%s_OVERWRITE_CONFIRM_TEXT") % save_name
			%OverwriteConfirmationDialog.show()
		else:
			_factory_root.save(save_dir)
			_set_mode(Mode.NORMAL)

func _on_overwrite_confirmation_dialog_confirmed() -> void:
	_factory_root.save(_save_path_to_confirm)
	_set_mode(Mode.NORMAL)

func _list_saves() -> void:
	%LoadDialog_ItemInfo.text = ""
	item_list.clear()
	for dir_name in DirAccess.get_directories_at(SAVE_DIR):
		var index = item_list.add_item(dir_name)
		item_list.set_item_metadata(index, {
			"path": SAVE_DIR + dir_name
		})

func _on_add_save_slot_pressed(text := "") -> void:
	if not text:
		text = %NewSaveSlot/NewSaveSlotName.text
	if text and FAG_Utils.find_item_in_item_list(item_list, text) < 0:
		var index = item_list.add_item(text)
		item_list.set_item_metadata(index, {
			"path": SAVE_DIR + text
		})
		item_list.select(index)
		item_list.move_item(index, 0)
		item_list.ensure_current_is_visible()
		%NewSaveSlot/NewSaveSlotName.text = ""


### Show / Hide main menu

func _show():
	if %SettingsDialog.visible:
		FAG_Settings.cancel_settings_changes()
	FAG_WindowManager.hide_by_escape_all_windows()
	_factory_root.pause_factory()
	_factory_root.input_off()
	_set_mode(Mode.NORMAL)
	show()

func _hide():
	hide()
	_factory_root.input_on()
	_factory_root.unpause_factory()
	FAG_WindowManager.restore_hideen_by_escape()


### Application close

func _on_quit_pressed() -> void:
	print("Quit request")
	await _factory_root.stop_simulations()
	get_tree().quit()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_on_quit_pressed()


### Init / Open / BackTo main menu

func _init():
	var default_controls = FAG_Settings.set_default_controls_and_create_actions("ACTION_", {
		"GLOBAL_ESCAPE": [{"key": KEY_ESCAPE}],
		"GLOBAL_BREAK":  [{"key": KEY_PAUSE, "shift": true}, {"key": KEY_PAUSE, "ctrl": true}],
	})
	FAG_Settings.register_settings(self, "MAIN_MENU_UI_SETTINGS_GROUP_NAME", {}, default_controls)

@onready var item_list := %LoadDialog_ItemList

func _ready():
	get_tree().set_auto_accept_quit(false)
	if not FileAccess.file_exists(_factory_root.GAME_PROGRESS_SAVE):
		FAG_Utils.write_to_json_file(_factory_root.GAME_PROGRESS_SAVE, {
			"finished_levels": {},
			"unlocked_manuals": ["game", "game/credits"]
		})
	call_deferred("_show")

func _input(event: InputEvent):
	if FAG_Settings.action_rempaing and event is InputEventKey and event.pressed:
		_last_event_to_remap = event
		%KeyReampInfo_Key.text = event.as_text()
	elif event.is_action_pressed("GLOBAL_BREAK", false, true):
		_show()
	elif event.is_action_pressed("GLOBAL_ESCAPE"):
		if visible and _current_mode == Mode.NORMAL and _factory_root.is_loaded():
			_hide()
		else:
			_show()

func _unhandled_input(event: InputEvent) -> void:
	if FAG_Settings.action_rempaing and event is InputEventMouseButton and event.pressed:
		_last_event_to_remap = event
		%KeyReampInfo_Key.text = event.as_text()

func _on_subdialog_cancel_pressed() -> void:
	_set_mode(Mode.NORMAL)
