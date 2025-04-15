extends Node

# Convenience Left VR controller reference, do not modify, will be set in xr_scene.gd automatically
var left_controller : XRController3D
# Convenience Right VR controller reference, do not modify, will be set in xr_scene.gd automatically
var right_controller : XRController3D
# Convenience VR Camera / HMD reference, do not modify, will be set in xr_scene.gd automatically
var hmd : XRCamera3D
# Convenience reference to Primary (weapon/turning hand) controller set by user, do not modify, will be set in xr_scene.gd automatically
var primary_controller
# Convenience reference to Secondary (movement/off-hand) controller set by user, do not modify, will be set in xr_scene.gd automatically
var secondary_controller
# Convenience XR Scene reference (the parent node of all of UGVR), do not modify, will be set in xr_scene.gd
var xr_scene : Node3D = null
# Convenience reference to the node at the top of the scene tree in any game, allows finding or getting other nodes in game scene tree
var scene_root = null
# Convenience reference to active flat screen game camera
var active_flat_screen_camera3D = null
# Track whether single use function has already been called
var on_xr_setup_already_run : bool = false
# Basic clear 2D shader (for use in trying to replace problematic canvas item shaders)
var default_2d_transparent_shader = """
shader_type canvas_item;

void fragment(){
  COLOR = vec4(1.0, 1.0, 1.0, 0.0);
}
"""
# Basic clear 3D mesh shader (for use in trying to replace problematic mesh shaders)
var default_3d_transparent_mesh_shader = """
shader_type spatial;
render_mode unshaded, transparent;

void fragment() {
	ALBEDO = vec3(1.0); // RGB = white
	ALPHA = 0.0;        // Fully transparent
}
"""

# Put game specific custom variables here for your code, e.g., var game_name_important_node = null


# Called when the node enters the scene tree for the first time.  Can't use convenience references yet as they will not be set up yet.
func _ready():
	pass

# Called only once after xr scene and all convenience variables are set, insert any code you want to run then here
# Note that you can now access any of the xr scene variables directly at this point, example: xr_scene.xr_pointer.enabled=false
func _on_xr_setup_run_once():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Don't try to run code if xr_scene not set yet
	if not xr_scene:
		return
	
	# Always make sure references to convenience variables are current
	left_controller = xr_scene.xr_left_controller
	right_controller = xr_scene.xr_right_controller
	hmd = xr_scene.xr_camera_3d
	primary_controller = xr_scene.primary_controller
	secondary_controller = xr_scene.secondary_controller
	active_flat_screen_camera3D = xr_scene.current_camera
	
	# If any of the references are invalid, return (may have to use not is_instance_valid() here instead)
	if not (left_controller and right_controller and hmd and primary_controller and secondary_controller):
		return
		
	# Run single use function the first time after all convenience variables are set up
	if not on_xr_setup_already_run:
		on_xr_setup_already_run = true
		_on_xr_setup_run_once()
	
	# Put any code you want to run each tick here
	# Note that you can now access any of the xr scene variables directly, example: xr_scene.xr_pointer.enabled=false

# Called each physics frame
func _physics_process(delta):
	# Don't try to run code if xr_scene not set yet
	if not xr_scene:
		return
	
	# If any of the references are invalid, return
	if not (left_controller and right_controller and hmd and primary_controller and secondary_controller):
		return
	
	# Put any code you want to run each physics tick here
	



## Built in UGVR Convenience Functions for Your Potential Use
# But remember you have full access to all Godot GDSCript scripting for Godot 4 - just be mindful of game's Godot version.
# To be on the safe side, aim to use Godot 4.2 documentation when finding potential methods, properties and signals

# Convenience function to get node reference by absolute path to node
func get_node_reference_by_absolute_path(absolute_node_path : NodePath) -> Node:
	var node = get_node_or_null(absolute_node_path)
	return node

# Convenience function to get node from path relative to scene root 
func get_node_from_scene_root_relative_path(relative_path_from_scene_root : String) -> Node:
	if not scene_root:
		return null
	var node = scene_root.get_node_or_null(relative_path_from_scene_root)
	return node

# Convenience function to find the first game node with a certain name in the scene
# Use * to match any number of wildcard characters and ? to match any single wildcard character
func find_first_node_by_name(node_name_pattern : String) -> Node:
	if not scene_root:
		return null
	var found_node : Node = scene_root.find_child(node_name_pattern, true, false)
	return found_node

# Convenience function to find all game nodes with a name containing the pattern string in the scene
# Use * to match any number of wildcard characters and ? to match any single wildcard character
func find_all_nodes_with_pattern_in_name(pattern_in_name : String) -> Array:
	if not scene_root:
		return []
	var found_nodes : Array = scene_root.find_children(pattern_in_name, "", true, false)
	return found_nodes

# Convenience function to find all game nodes of a certain class in the scene
func find_nodes_by_class(class_type : String) -> Array:
	if not scene_root:
		return []
	var class_nodes : Array = scene_root.find_children("*", class_type, true, false)
	return class_nodes

# Convenience function to move game node to track controller, may not work in all instances, offset is x, y, z relative to controller
func reparent_game_node_to_controller(game_node : Node3D, controller : XRController3D, offset: Vector3 = Vector3(0,0,0)) -> void:
	var remote_transform : RemoteTransform3D = RemoteTransform3D.new()
	var node_holder : Node3D = Node3D.new()
	controller.add_child(node_holder)
	node_holder.transform.origin = offset
	node_holder.add_child(remote_transform)
	remote_transform.update_scale = false
	remote_transform.remote_path = game_node.get_path()

# Convenience function to move game node to track HMD, may not work in all instances, offset is x, y, z relative to HMD
func reparent_game_node_to_hmd(game_node : Node3D, hmd_node : XRCamera3D, offset: Vector3 = Vector3(0,0,0)) -> void:
	var remote_transform : RemoteTransform3D = RemoteTransform3D.new()
	var node_holder : Node3D = Node3D.new()
	hmd_node.add_child(node_holder)
	node_holder.transform.origin = offset
	node_holder.add_child(remote_transform)
	remote_transform.update_scale = false
	remote_transform.remote_path = game_node.get_path()

# Convenience function to try to delete a problematic shader from a 3D mesh, may cause game crashes if game code depends on setting variables in the shader
func remove_shader_from_mesh(mesh_node : MeshInstance3D)-> void :
	var surface_material = mesh_node.get_surface_override_material(0)
	if surface_material:
		if surface_material.is_class("ShaderMaterial"):
			surface_material.get_shader().set_code(default_3d_transparent_mesh_shader)

# Convenience funcrion to try to delete a problematic shader from a 2D canvas object (like a rectangle on the screen), may cause game crashes if game code depends on setting variables in the shader
func remove_shader_from_UI_object(canvas_item : CanvasItem)-> void :
	var surface_material = canvas_item.material
	if surface_material:
		if surface_material.is_class("ShaderMaterial"):
			surface_material.get_shader().set_code(default_2d_transparent_shader)

# Convenience function to completely remove a potential problematic material from a mesh.  May have unintended consequences or create unwarranted visual artifacts.
func remove_material_from_mesh(mesh_node : MeshInstance3D) -> void:
	var number_of_surface_materials = mesh_node.get_surface_override_material_count()
	for i in range(number_of_surface_materials):
		mesh_node.set_surface_override_material(i, null)
	var mesh = mesh_node.mesh	
	if mesh:
		var mesh_surface_count = mesh.get_surface_count()
		for i in range(mesh_surface_count):
			mesh.surface_set_material(i, null)

# Convenience function to completely remove a potential problematic material from a 2D item (like a UI item).  May have unintended consequences or create unwarranted visual artifacts.	
func remove_material_from_UI_object(canvas_item : CanvasItem) -> void:
	canvas_item.material = null

# Convenience function to hide a node.  May need to be run in _process if other game code may dynamically hide and show the element
func hide_node(node : Node) -> void:
	if node.has_method("hide"):
		node.hide()
	else:
		for property_dictionary in node.get_property_list():
			if "visible" in property_dictionary["name"]:
				node.visible = false
				break

# Convenience function to show a hidden node. May need to be run in _process if other game code may dynamically hide and show the element
func show_node(node : Node) -> void:
	if node.has_method("show"):
		node.show()
	else:
		for property_dictionary in node.get_property_list():
			if "visible" in property_dictionary["name"]:
				node.visible = true
				break

# Convenience function to print a scene tree of the scene at the time the function is called to the existing log for the game
# The log is usually found in Users/userscomputername/AppData/Roaming/Godot/app_userdata/game_name, but some games maintain their user data with logs in other folders
# This can be used to find potential nodes for reparenting, adjusting shaders, etc., without having to try to decompile the flat screen game
func print_scene_tree_pretty_to_game_log() -> void:
	get_tree().current_scene.print_tree_pretty()

# Convenience function to print a scene tree of the scene at the time the function is called to a text file dedicated to this purpose in the XRConfigs folder.  Note that by default the file does NOT clear.  Set to true instead when calling the function to just print the latest scene tree to the file.
# This can be used to find potential nodes for reparenting, adjusting shaders, etc., without having to try to decompile the flat screen game
func print_scene_tree_pretty_to_text_file(full_file_path : String = "", clear_previous_contents : bool = false) -> void:
	var text_file = full_file_path if full_file_path != "" else xr_scene.xr_config_handler.cfg_base_path + "/xr_scene_tree_print_log.txt"
	if clear_previous_contents == true and FileAccess.file_exists(text_file):
		OS.move_to_trash(text_file)
	var file = FileAccess.open(text_file, FileAccess.WRITE)
	var node_tree_string = get_tree().current_scene.get_tree_string_pretty() + "\n\n"
	file.store_string(node_tree_string)
	
# Setter function for xr_scene reference, called in xr_scene.gd automatically
func set_xr_scene(new_xr_scene) -> void:
	xr_scene = new_xr_scene
	scene_root = get_node("/root")
