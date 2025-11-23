# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends FAG_TestGame

func test_factory_computers():
	var save_path := create_temp_dir("saves") + "/test"
	factory_root.save(save_path)
	
	assert_bool(FileAccess.file_exists(save_path+"/save_info.json")).is_true()
	
	for file in ["Factory.json", "Circuit.json", "save_info.json"]:
		var old = FAG_Utils.load_from_json_file(default_save_to_load+"/"+file)
		var new = FAG_Utils.load_from_json_file(save_path+"/"+file)
		if file == "save_info.json":
			old["stats"] = factory_root._stats
		if old is Array:
			assert_array(new).append_failure_message(file).is_equal(old)
		else:
			assert_dict(new).append_failure_message(file).is_equal(old)
	
	
	# TODO: add testing factory computers filesystems saving
