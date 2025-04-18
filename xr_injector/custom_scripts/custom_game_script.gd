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
# Variables to hold control map 3D label objects
var xr_primary_control_mapping_label3D : Label3D = null
var xr_secondary_control_mapping_label3D : Label3D = null
var xr_hmd_control_mapping_label3D : Label3D = null
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
	# Example: This automatically shows the game controls for 30 seconds once xr is set up
	show_vr_control_mapping(30.0)

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

# Convenience function to show a text message to the user for a designated time period at the location of a controller or the camera, with a designated offset
func show_text_in_vr(text_to_show : String, location : Node3D, offset : Vector3 = Vector3.ZERO, time_to_show : float = 15.0) -> void:
	var label = Label3D.new()
	location.add_child(label)
	label.transform.origin = offset
	label.set_width(800.0)
	label.render_priority = 2
	label.font_size = 24
	label.pixel_size = 0.0005
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_draw_flag(Label3D.DrawFlags.FLAG_DISABLE_DEPTH_TEST, true)
	label.set_draw_flag(Label3D.DrawFlags.FLAG_SHADED, false)
	label.text = text_to_show
	await get_tree().create_timer(time_to_show).timeout
	label.visible = false
	
# Convenience function to show VR control mapping (optionally for a designated time period)
func show_vr_control_mapping(time_to_show: float = 0.0) -> void:
	if not xr_scene:
		return

	# Only build the labels once
	if not is_instance_valid(xr_primary_control_mapping_label3D) and not is_instance_valid(xr_secondary_control_mapping_label3D) and not is_instance_valid(xr_hmd_control_mapping_label3D):
		if not is_instance_valid(xr_scene.xr_config_handler):
			return

		# Load the action map config
		var cfg = ConfigFile.new()
		var err = cfg.load(xr_scene.xr_config_handler.game_action_map_cfg_path)
		if err != OK:
			print("Failed to load VR control mapping config in custom_game_script show vr control mapping function: %s" % xr_scene.xr_config_handler.game_action_map_cfg_path)
			return

		# Prepare grouped control strings
		var primary_vr_controls = ""
		var secondary_vr_controls = ""
		var miscellaneous_controls = ""

		# Iterate each game action mapping
		for action_key in cfg.get_section_keys("GAME_ACTIONS"):
			var raw_value = cfg.get_value("GAME_ACTIONS", action_key)
			print("raw_value: ", raw_value)
			var mapping_str = ""
			var mapping_str_direction = ""
			if typeof(raw_value) == TYPE_ARRAY:
				mapping_str = str(raw_value[0])
				mapping_str_direction = str(raw_value[1])
			else:
				mapping_str = str(raw_value)
			var display_mapping = ""

			# Override stick & trigger mappings
			if mapping_str.contains("LeftStick"):
				display_mapping = "Secondary VR Controller Thumbstick Move"
			elif mapping_str.contains("LeftTrigger"):
				display_mapping = "Secondary VR Controller Trigger"
			elif mapping_str.contains("RightStick"):
				display_mapping = "Primary VR Controller Thumbstick Move"
				if mapping_str_direction:
					if mapping_str.contains("X"):
						display_mapping += " Left" if mapping_str_direction.contains("-1.0") else " Right"
					if mapping_str.contains("Y"):
						display_mapping += " Up" if mapping_str_direction.contains("-1.0") else " Down"
						
			elif mapping_str.contains("RightTrigger"):
				display_mapping = "Primary VR Controller Trigger"

			# Handle unmapped entries
			elif mapping_str == "needs_joypad_mapping":
				display_mapping = "Not Mapped"

			# All other joypad buttons
			else:
				display_mapping = mapping_str.replace("Joypad", "")
				display_mapping = display_mapping.replace("A/Cross", "Primary VR Controller A/X")
				display_mapping = display_mapping.replace("B/Circle", "Secondary VR Controller A/X")
				display_mapping = display_mapping.replace("X/Square", "Primary VR Controller B/Y")
				display_mapping = display_mapping.replace("Y/Triangle", "Secondary VR Controller B/Y")
				display_mapping = display_mapping.replace("RB", "Primary VR Controller Grip")
				display_mapping = display_mapping.replace("LB", "Secondary VR Controller Grip")
				display_mapping = display_mapping.replace("L3", "Secondary VR Controller Thumbstick Click")
				display_mapping = display_mapping.replace("R3", "Primary VR Controller Thumbstick Click")

			# Prepare a line for this action
			var line = "%s: %s\n" % [action_key, display_mapping]

			# Append into the appropriate group
			if display_mapping == "Not Mapped":
				miscellaneous_controls += line
			elif display_mapping.contains("Secondary VR Controller Thumbstick Move"):
				continue
			elif display_mapping.contains("Primary VR Controller"):
				primary_vr_controls += line
			elif display_mapping.contains("Secondary VR Controller"):
				secondary_vr_controls += line
			else:
				miscellaneous_controls += line

		# Add extra instructions to misc
		var added_control_info = """

Activate radial menu: Hold primary thumbstick down, hover over option and release
Start/Select: HOTKEY plus bound start / select key
DPad: HOTKEY plus directions on secondary thumbstick
Toggle VR pointer: Primary controller near head, press trigger
Reload controls: Secondary controller near head, press B/Y

**You can activate arm swing movement and jump, 
physical melee, and motion sickness vignette in config files**

		"""
		miscellaneous_controls += added_control_info

		# Create and configure the 3D labels
		xr_primary_control_mapping_label3D = Label3D.new()
		xr_secondary_control_mapping_label3D = Label3D.new()
		xr_hmd_control_mapping_label3D = Label3D.new()
		primary_controller.add_child(xr_primary_control_mapping_label3D)
		secondary_controller.add_child(xr_secondary_control_mapping_label3D)
		hmd.add_child(xr_hmd_control_mapping_label3D)
		
		for xr_control_mapping_label3D in [xr_primary_control_mapping_label3D, xr_secondary_control_mapping_label3D, xr_hmd_control_mapping_label3D]:
			xr_control_mapping_label3D.set_width(800.0)
			xr_control_mapping_label3D.render_priority = 2
			xr_control_mapping_label3D.font_size = 16
			xr_control_mapping_label3D.pixel_size = 0.0005
			xr_control_mapping_label3D.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			xr_control_mapping_label3D.set_draw_flag(Label3D.DrawFlags.FLAG_DISABLE_DEPTH_TEST, true)
			xr_control_mapping_label3D.set_draw_flag(Label3D.DrawFlags.FLAG_SHADED, false)
		xr_primary_control_mapping_label3D.transform.origin = Vector3(0, 0.1, 0.1)
		xr_secondary_control_mapping_label3D.transform.origin = Vector3(0, 0.1, 0.1)
		xr_hmd_control_mapping_label3D.transform.origin = Vector3(0,-0.2,-0.8)

		# Set text for each respective Label3D
		xr_primary_control_mapping_label3D.text = primary_vr_controls
		xr_secondary_control_mapping_label3D.text = secondary_vr_controls
		xr_hmd_control_mapping_label3D.font_size = 24
		xr_hmd_control_mapping_label3D.text = miscellaneous_controls

	else:
		xr_primary_control_mapping_label3D.visible = true
		xr_secondary_control_mapping_label3D.visible = true
		xr_hmd_control_mapping_label3D.visible = true
	
	# Optionally hide after a delay
	if time_to_show > 0.0:
		await get_tree().create_timer(time_to_show).timeout
		xr_primary_control_mapping_label3D.visible = false
		xr_secondary_control_mapping_label3D.visible = false
		xr_hmd_control_mapping_label3D.visible = false

# Convenience function to hide VR control mapping display if its visible
func hide_vr_control_mapping() -> void:
	if is_instance_valid(xr_primary_control_mapping_label3D) and is_instance_valid(xr_secondary_control_mapping_label3D) and is_instance_valid(xr_hmd_control_mapping_label3D):
		xr_primary_control_mapping_label3D.visible = false
		xr_secondary_control_mapping_label3D.visible = false
		xr_hmd_control_mapping_label3D.visible = false


	
# Setter function for xr_scene reference, called in xr_scene.gd automatically
func set_xr_scene(new_xr_scene) -> void:
	xr_scene = new_xr_scene
	scene_root = get_node("/root")
