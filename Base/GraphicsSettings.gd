# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

extends Node

@export_enum("Disabled", "Enabled", "Exclusive") var full_screen := "Disabled" :
	set(value):
		print("Set full_screen to: ", value)
		match value:
			"Disabled":
				get_tree().root.set_mode(Window.MODE_WINDOWED)
			"Enabled":
				get_tree().root.set_mode(Window.MODE_FULLSCREEN)
			"Exclusive":
				get_tree().root.set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)
		full_screen = value

@export_enum("Disabled", "SSRL", "FXAA", "TAA", "FSR2", "MSAA 2x", "MSAA 4x", "MSAA 8x", "SSAA 2.25x", "SSAA 4x") var antialiasing := "FSR2" :
	set(value):
		print("Set antialiasing to: ", value)
		RenderingServer.screen_space_roughness_limiter_set_active(false, 0.25, 0.18)
		get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		get_viewport().use_taa = false
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		get_viewport().scaling_3d_scale = 1.0
		match value:
			"SSRL":
				RenderingServer.screen_space_roughness_limiter_set_active(true, 0.25, 0.18)
			"FXAA":
				get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			"TAA":
				get_viewport().use_taa = true
			"FSR2":
				get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
			"MSAA 2x":
				get_viewport().msaa_3d = Viewport.MSAA_2X
			"MSAA 4x":
				get_viewport().msaa_3d = Viewport.MSAA_4X
			"MSAA 8x":
				get_viewport().msaa_3d = Viewport.MSAA_8X
			"SSAA 2.25x":
				get_viewport().scaling_3d_scale = 1.5
			"SSAA 4x":
				get_viewport().scaling_3d_scale = 2.0
		antialiasing = value

@export_enum("Disabled", "Adaptive", "Enabled") var vsync := "Enabled":
	set(value):
		print("Set vsync to: ", value)
		match value:
			"Disabled":
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			"Adaptive":
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
			"Enabled":
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		vsync = value

@export var ui_scale := 1.0:
	set(value):
		get_tree().root.content_scale_factor = value
		ui_scale = value

## Name of settings group for this object. This allowing override some properties and input maps.
## Set to empty string to disable using settings (hide in settings menu, disallow override properties and key mapping).
@export var settings_group_name := "GRAPHICS_SETTINGS_GROUP_NAME"

func _init() -> void:
	var default_settings = FAG_Settings.set_default_setting_from_object(self, "GRAPHICS_SETTINGS_", [
		"full_screen",
		"antialiasing",
		"vsync",
		"ui_scale",
	])
	
	var default_controls = FAG_Settings.set_default_controls_and_create_actions("ACTION_", {
		"GRAPHICS_FULL_SCREEN": [{"key": KEY_ENTER, "alt": true}, {"key": KEY_F11}],
	})
	
	if settings_group_name:
		FAG_Settings.register_settings(self, settings_group_name, default_settings, default_controls)

func _unhandled_input(event: InputEvent) -> void:
	if FAG_Utils.action_exact_match_pressed("GRAPHICS_FULL_SCREEN"):
		if get_tree().root.get_mode() in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]:
			get_tree().root.set_mode(Window.MODE_WINDOWED)
		else:
			get_tree().root.set_mode(Window.MODE_FULLSCREEN)
