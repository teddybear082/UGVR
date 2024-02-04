extends Node


func _ready() -> void:
	var xr_scene : PackedScene = load("res://xr_scene.tscn")
	get_node("/root").call_deferred("add_child", xr_scene.instantiate())