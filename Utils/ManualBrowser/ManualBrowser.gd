# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Window

## Page path tamplate
## [code]{file}[/code] will be replaced by file path from `MANUALS_CONTENTS_FILE`
## [code]{lang}[/code] will be replaced by lang id
@export var MANUAL_PAGE_PATH_TEMPLATE = "res://Manual/generated-bbcode/{file}_{lang}.not_edit"

## Manual contents file path
@export var MANUALS_CONTENTS_FILE := "res://Manual/Pages/contents.json"

## Manual tabs (per topic sections)
@export var MANUAL_TABS = ["guide", "trivia"]

func show_info(object : Object, progress_save_path : String) -> void:
	var text_area = _tab_container.get_current_tab_control().get_node("RichTextLabel")
	if text_area:
		text_area.text = tr("MANUAL_SELECT_TOPIC")
	if object:
		if _task_info_node.get_parent() != _tab_container:
			_task_info_node.get_parent().remove_child(_task_info_node)
			_tab_container.add_child(_task_info_node)
			_tab_container.move_child(_task_info_node, 0)
		_task_info_node.get_child(0).text = FAG_Utils.get_locale_version(object.task_info)
		_update_tree(object.guide_topic_paths[0], progress_save_path)
		_task_info_node.show()
	else:
		if _task_info_node.get_parent() == _tab_container:
			_tab_container.remove_child(_task_info_node)
			_tab_container.get_parent().add_child(_task_info_node)
			_task_info_node.hide()
		_update_tree("", progress_save_path)
	show()
	grab_focus()

func switch_topic(topic_path : String, tab : String):
	var item = _get_by_path(topic_path)
	_add_to_history(item, _guide_info_nodes[tab])
	_tree.set_selected(item, 0)
	_guide_info_nodes[tab].show()
	_on_tab_changed() # call this even if we don't change tab


### topics tree - generation and usage

var manual_contents := {}

func _update_tree(selected_path : String, progress_save_path : String):
	var lang : String = TranslationServer.get_locale()
	var fallback_lang : String = ProjectSettings.get("internationalization/locale/fallback")
	manual_contents = FAG_Utils.load_from_json_file(MANUALS_CONTENTS_FILE)
	var unlocked_manuals : Array = FAG_Utils.load_from_json_file(progress_save_path)["unlocked_manuals"]
	
	_restet_history()
	_tree.clear()
	var root = _tree.create_item()
	_tree.hide_root = true
	
	_recusrise_build_tree(root, manual_contents, unlocked_manuals, "", selected_path, lang, fallback_lang)

func _get_by_path(path : String):
	var level_dict := manual_contents
	var current_path := ""
	for path_element in path.split("/"):
		prints(" - ", path_element, level_dict)
		current_path += path_element
		
		if path_element in level_dict:
			level_dict = level_dict[path_element]
			if current_path == path:
				break
			elif "subtopics" in level_dict:
				level_dict = level_dict["subtopics"]
				current_path += "/"
				continue
		
		printerr("Can't select topic by path: ", path, " - ", path_element, " is missing in ", level_dict)
		return
	
	return level_dict["_item"]

func _recusrise_build_tree(parent : TreeItem, contents : Dictionary, unlocked_manuals : Array, path : String, selected_path : String, lang : String, fallback_lang : String) -> void:
	for topic_name in contents:
		var topic_path = path + topic_name
		if topic_path in unlocked_manuals:
			var child = _tree.create_item(parent)
			child.set_text(0, FAG_Utils.get_with_fallback(contents[topic_name]["title"], lang, fallback_lang))
			for tab in MANUAL_TABS:
				child.set_meta(tab, contents[topic_name].get(tab, ""))
			if topic_path == selected_path:
				_add_to_history(child, _guide_info_nodes[MANUAL_TABS[0]])
				_tree.set_selected(child, 0)
			contents[topic_name]["_item"] = child
			if "subtopics" in contents[topic_name]:
				_recusrise_build_tree(child, contents[topic_name]["subtopics"], unlocked_manuals, topic_path + "/", selected_path, lang, fallback_lang)

func _get_manual_page_path(file: String, lang: String):
	return MANUAL_PAGE_PATH_TEMPLATE.format({
		"file": file,
		"lang": lang
	})

func _on_tree_item_selected() -> void:
	var tab = _tab_container.get_current_tab_control()
	var item = _tree.get_selected()
	var file = null
	
	if not item:
		return
		
	var tab_id = tab.get_meta("tab_id")
	if not tab_id in _guide_info_nodes:
		return
	file = item.get_meta(tab_id)
	
	var text = ""
	if file:
		var lang = TranslationServer.get_locale()
		var file2 = _get_manual_page_path(file, lang)
		if not FileAccess.file_exists(file2):
			lang = ProjectSettings.get("internationalization/locale/fallback")
			file2 = _get_manual_page_path(file, lang)
		file = FileAccess.open(file2, FileAccess.READ)
		if file: 
			text = file.get_as_text()
	
	var richTextLabel = tab.get_node("RichTextLabel")
	if text:
		_add_to_history(item, tab)
		richTextLabel.text = text
	else:
		richTextLabel.text = tr("MANUAL_NOTHING_TO_SHOW")
	richTextLabel.scroll_to_line(0)


## keep common tree for multiple tabs

func _on_tab_changed(_tab := 0) -> void:
	var current_tab : Control = _tab_container.get_current_tab_control()
	var tree_parent : Control = current_tab.get_node_or_null("TreeParent")
	if tree_parent:
		var moving_node = _tree
		moving_node.get_parent().remove_child(moving_node)
		tree_parent.add_child(moving_node)
		tree_parent.move_child(moving_node, 0)
		_on_tree_item_selected()


# url opening and history support

func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	for prefix in MANUAL_TABS:
		if meta.begins_with(prefix + "://"):
			switch_topic(meta.substr(len(prefix)+3), prefix)
			return
	%MANUAL_EXTERNAL_TITLE.open_url(meta)
	%MANUAL_EXTERNAL_TITLE.show()

var _history = []
var _history_current = -1

func _restet_history():
	_history = []
	_history_current = -1

func _add_to_history(item : TreeItem, tab : Control):
	if _history_current >= 0 and _history[_history_current][0] == item and _history[_history_current][1] == tab:
		return
	
	if _history_current >= 0 and _history_current != len(_history)-1:
		_history.resize(_history_current+1)
	_history.append([item, tab])
	_history_current += 1


func _on_go_back_pressed() -> void:
	if _history_current < 0:
		return
	
	var item = _tree.get_selected()
	var tab = _tab_container.get_current_tab_control()
	if _history_current > 0 and _history[_history_current][0] == item and _history[_history_current][1] == tab:
		# current page is on top of the history
		_history_current -= 1
	
	_tree.set_selected(_history[_history_current][0], 0)
	_history[_history_current][1].show()
	_on_tab_changed()

func _on_go_next_pressed() -> void:
	if _history_current + 1 < len(_history):
		_history_current += 1
		_tree.set_selected(_history[_history_current][0], 0)
		_history[_history_current][1].show()
		_on_tab_changed()


## init and close

@onready var _tree := %Tree
@onready var _tab_container := $TabContainer
@onready var _task_info_node := %MANUAL_TASK_INFO_TITLE
@onready var _guide_info_nodes := {}

func _ready() -> void:
	FAG_WindowManager.init_window(self)
	close_requested.connect(_on_close_requested)
	_tab_container.tab_changed.connect(_on_tab_changed)
	var tab_template = %MANUAL_TASK_GUIDE_TEMPLATE
	
	for i in range(0, len(MANUAL_TABS)):
		var tab
		var tab_id = MANUAL_TABS[i]
		
		if i > 0:
			tab = tab_template.duplicate()
			
			# remove tree from other tabs, we keep single tree
			var treeparent = tab.get_node("TreeParent")
			var tree = treeparent.get_node("Tree")
			treeparent.remove_child(tree)
			tree.queue_free()
			
			_tab_container.add_child(tab)
		else:
			tab = tab_template
		
		tab.name = "MANUAL_TASK_GUIDE_TITLE_" + tab_id
		tab.get_node("RichTextLabel").text = tr("MANUAL_SELECT_TOPIC")
		tab.set_meta("tab_id", tab_id)
		
		_guide_info_nodes[tab_id] = tab
	
	_tab_container.move_child(%MANUAL_EXTERNAL_TITLE, -1)
	_on_tab_changed()

func _on_close_requested() -> void:
	hide()
