<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

# levels.json syntax

All `*.json` files in this directory (`Levels`) are read as levels list.

Each of these files should be a dictionary mapping `level_id` to level description:

* `level_id` is level path (relative to this directory) to level scene file (without filename extension, `.tscn` will be added by load system)
* level description is dictionary with keys:
	* `is_saved_data` - optional (default false), if true `level_id` is path (relative to this directory) to game save format directory instead of scene file;
	                    real `level_id` (being a path to scene file) is stored in `save_info.json` file in save directory pointed by `level_id` from this file
	* `unlocked_by` - condition of unlocking this level, supported values:
		* `false` - always unlocked
		* array of array, examples:
			* `[["A"]]` - unlocked by completing level with `level_id == "A"`
				* use non existed level id eg. `[["__LOCKED__"]]` to keep level always locked
			* `[["A", "B"]]` - unlocked by completing level with `level_id == "A"` **AND** level with `level_id == "B"`
			* `[["A"], ["B"]]` - unlocked by completing level with `level_id == "A"` **OR** level with `level_id == "B"`
			* `[["A", "B"], ["C"]]` - unlocked by completing (level with `level_id == "A"` **AND** level with `level_id == "B"`) **OR** level with `level_id == "C"`
	* `name` - name of level as multi-language dictionary mapped *lang_id* to *text*
	* `description` - description of level as multi-language dictionary mapped *lang_id* to *text*
