extends Node

# Start by loading a zip that is produced using Godot's export functionality and contains the xr injector files
# May just wind up using local files again once custom global classes are removed from scripts for ease of use, remains to be seen.
func _init() -> void:
	print("loading injector files")
	#var loaded = ProjectSettings.load_resource_pack("res://injector_src.zip")
	#if loaded == true:
	#	print("loaded injector files")
	#else:
	#	print("There was some issue loading the injector files in xr_injector _init.")
		
func _ready() -> void:
	print("Now loading xr_scene.")
	var xr_scene : PackedScene = load("res://xr_scene.tscn")
	get_node("/root").call_deferred("add_child", xr_scene.instantiate())

# No method of trying to add to custom classes works, so need to refactor not to use custom classes for now, saving prior work
# See https://github.com/godotengine/godot/pull/82084, https://github.com/godotengine/godot/issues/61556
