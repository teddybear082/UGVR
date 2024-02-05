extends Node

func _init() -> void:
	print("running check for custom classes in injector.gd init")
	var config = ConfigFile.new()
	config.load("res://.godot/global_script_class_cache.cfg")
	var custom_class_list = config.get_value('', 'list', [])
	print("Custom classes found present in game:")
	print(custom_class_list)
	#var custom_class_list = ProjectSettings.get_global_class_list()
	#print(custom_class_list)
	#[{ "base": &"CharacterBody3D", "class": &"Player", "icon": "", "language": &"GDScript", "path": "res://player/player.gd" }]
	if not custom_class_list.has({"base": &"RefCounted", "class": &"XRToolsPointerEvent", "icon": "", "language": &"GDScript", "path": "res://xr_pointer_event.gd"}):
		print("adding custom XR tools classes from xrinjector init")
		custom_class_list.append(
			{ "base": &"RefCounted", "class": &"XRToolsPointerEvent", "icon": "","language": &"GDScript", "path": "res://xr_pointer_event.gd"},
			{ "base": &"Node3D", "class": &"XRToolsFunctionPointer", "icon": "","language": &"GDScript", "path": "res://xr_pointer.gd"}
		)
		print("New custom class list:")
		print(custom_class_list)
	config.set_value("", 'list', custom_class_list)
	var error_code = config.save("res://.godot/global_script_class_cache.cfg")
	print(error_code)
	
func _ready() -> void:
	print("running check for custom classes in injector.gd ready")
	var config = ConfigFile.new()
	config.load("res://.godot/global_script_class_cache.cfg")
	var custom_class_list = config.get_value('', 'list', [])
	print("Custom classes found present in game:")
	print(custom_class_list)
	#var custom_class_list = ProjectSettings.get_global_class_list()
	#print(custom_class_list)
	#[{ "base": &"CharacterBody3D", "class": &"Player", "icon": "", "language": &"GDScript", "path": "res://player/player.gd" }]
	if not custom_class_list.has({ "base": &"RefCounted", "class": &"XRToolsPointerEvent", "icon": "", "language": &"GDScript", "path": "res://xr_pointer_event.gd"}):
		print("adding custom XR tools classes in injector.gd ready")
		custom_class_list.append(
			{ "base": &"RefCounted", "class": &"XRToolsPointerEvent", "icon": "","language": &"GDScript", "path": "res://xr_pointer_event.gd"},
			{ "base": &"Node3D", "class": &"XRToolsFunctionPointer", "icon": "","language": &"GDScript", "path": "res://xr_pointer.gd"}
		)
		print("New custom class list:")
		print(custom_class_list)
	config.set_value("", 'list', custom_class_list)
	var error_code = config.save("res://.godot/global_script_class_cache.cfg")
	print(error_code)
	var xr_scene : PackedScene = load("res://xr_scene.tscn")
	get_node("/root").call_deferred("add_child", xr_scene.instantiate())
