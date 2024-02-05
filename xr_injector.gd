extends Node

# Start by loading a zip that is produced using Godot's export functionality and contains the xr injector files
# May just wind up using local files again once custom global classes are removed from scripts for ease of use, remains to be seen.
func _init() -> void:
	print("loading injector files")
	var loaded = ProjectSettings.load_resource_pack("res://injector_src.zip")
	if loaded == true:
		print("loaded injector files")
	else:
		print("There was some issue loading the injector files in xr_injector _init.")
		
func _ready() -> void:
	print("Now loading xr_scene.")
	var xr_scene : PackedScene = load("res://xr_scene.tscn")
	get_node("/root").call_deferred("add_child", xr_scene.instantiate())

# No method of trying to add to custom classes works, so need to refactor not to use custom classes for now, saving prior work
# See https://github.com/godotengine/godot/pull/82084, https://github.com/godotengine/godot/issues/61556

#func _check_and_save_global_class_config():
	#var config = ConfigFile.new()
	#var loading_error = config.load("res://.godot/global_script_class_cache.cfg")
	#if loading_error != OK:
		#print("error loading global_script_class_cache.cfg; error code:")
		#print(loading_error)
		#return
	#else:
		#var custom_class_list = config.get_value('', 'list', [])
		#print("Custom classes found present in game:")
		#print(custom_class_list)
		##var custom_class_list = ProjectSettings.get_global_class_list()
		##print(custom_class_list)
		##example: [{ "base": &"CharacterBody3D", "class": &"Player", "icon": "", "language": &"GDScript", "path": "res://player/player.gd" }]
		#if not custom_class_list.has({ "base": &"RefCounted", "class": &"XRToolsPointerEvent", "icon": "", "language": &"GDScript", "path": "res://xr_pointer_event.gd"}):
			#print("adding custom XR tools classes in xr_injector _check_and_save_config function")
			#custom_class_list.append(
				#{ "base": &"RefCounted", "class": &"XRToolsPointerEvent", "icon": "","language": &"GDScript", "path": "res://xr_pointer_event.gd"},
				#{ "base": &"Node3D", "class": &"XRToolsFunctionPointer", "icon": "","language": &"GDScript", "path": "res://xr_pointer.gd"}
			#)
			#print("New custom class list:")
			#print(custom_class_list)
		#config.set_value("", 'list', custom_class_list)
		#var godot_contents = DirAccess.get_files_at("res://.godot/")
		#print(godot_contents)
		#print(DirAccess.get_open_error())
		#var config_path = ProjectSettings.globalize_path("res://.godot/global_script_class_cache.cfg")
		#var saving_error = config.save("res://.godot/global_script_class_cache.cfg")
		#print(saving_error)
		#maybe try copying file instead, saving to different file
		#var dir = DirAccess.open(OS.get_executable_path().get_base_dir())
		#var custom_classes_cfg_path = OS.get_executable_path().get_base_dir() + "/global_script_class_cache.cfg"
		#print(custom_classes_cfg_path)
		#var saving_error = config.save(custom_classes_cfg_path)
		#if saving_error != OK:
		#	print("Error saving custom classes cfg; error code:")
		#	print(saving_error)
		#else:
		#	var err = dir.copy(custom_classes_cfg_path, "res://.godot/global_script_class_cache.cfg")
		#	print(err)
		#var saving_error = config.save(config_path)
		#if saving_error != OK: 
		#	print("Error saving global_script_class_cache.cfg; error code:")
		#	print(saving_error)
