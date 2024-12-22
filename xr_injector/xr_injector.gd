extends Node

# As shown in commented code, in the alternative could load a zip that is produced using Godot's export functionality and contains the xr injector files
# Mabye this could also be used later to expand capabilities to load game-specific mod files, e.g., in a folder called "mods"
# For now just using local files loaded  through override.cfg
func _init() -> void:
	print("loading injector files")
	print("Size of game window found in injector.gd: ", DisplayServer.window_get_size())
	print("Size (resolution) of screen found in injector.gd: ", DisplayServer.screen_get_size())
	#var loaded = ProjectSettings.load_resource_pack("res://injector_src.zip")
	#if loaded == true:
	#	print("loaded injector files")
	#else:
	#	print("There was some issue loading the injector files in xr_injector _init.")
		
func _ready() -> void:
	print("Now loading xr_scene.")
	var xr_scene : PackedScene = load("res://xr_injector/xr_scene.tscn")
	get_node("/root").call_deferred("add_child", xr_scene.instantiate())

# No method of trying to add to custom classes works, so not using custom classes for now, saving prior work in comments above
# See https://github.com/godotengine/godot/pull/82084, https://github.com/godotengine/godot/issues/61556
