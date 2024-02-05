extends Node

func _init() -> void:
	print("running check for custom classes in injector.init")
	_check_and_save_global_class_config()
	
func _ready() -> void:
	print("running check for custom classes in injector.gd ready")
	_check_and_save_global_class_config()
	var xr_scene : PackedScene = load("res://xr_scene.tscn")
	get_node("/root").call_deferred("add_child", xr_scene.instantiate())

func _check_and_save_global_class_config():
	var config = ConfigFile.new()
	var loading_error = config.load("res://.godot/global_script_class_cache.cfg")
	if loading_error != OK:
		print("error loading global_script_class_cache.cfg; error code:")
		print(loading_error)
		return
	else:
		var custom_class_list = config.get_value('', 'list', [])
		print("Custom classes found present in game:")
		print(custom_class_list)
		#var custom_class_list = ProjectSettings.get_global_class_list()
		#print(custom_class_list)
		#example: [{ "base": &"CharacterBody3D", "class": &"Player", "icon": "", "language": &"GDScript", "path": "res://player/player.gd" }]
		if not custom_class_list.has({ "base": &"RefCounted", "class": &"XRToolsPointerEvent", "icon": "", "language": &"GDScript", "path": "res://xr_pointer_event.gd"}):
			print("adding custom XR tools classes in xr_injector _check_and_save_config function")
			custom_class_list.append(
				{ "base": &"RefCounted", "class": &"XRToolsPointerEvent", "icon": "","language": &"GDScript", "path": "res://xr_pointer_event.gd"},
				{ "base": &"Node3D", "class": &"XRToolsFunctionPointer", "icon": "","language": &"GDScript", "path": "res://xr_pointer.gd"}
			)
			print("New custom class list:")
			print(custom_class_list)
		config.set_value("", 'list', custom_class_list)
		var godot_contents = DirAccess.get_files_at("res://.godot/")
		print(godot_contents)
		print(DirAccess.get_open_error())
		var saving_error = config.save("res://.godot/global_script_class_cache.cfg")
		if saving_error != OK: 
			print("Error saving global_script_class_cache.cfg; error code:")
			print(saving_error)
