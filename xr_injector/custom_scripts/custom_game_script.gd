extends Node

# Convenience Left VR controller reference, do not modify, will be set in xr_scene.gd automatically
var left_controller : XRController3D
# Convenience Right VR controller reference, do not modify, will be set in xr_scene.gd automatically
var right_controller : XRController3D
# Convenience VR Camera / HMD reference, do not modify, will be set in xr_scene.gd automatically
var hmd : XRCamera3D
# Convenience Primary (weapon/turning hand) controller set by user, do not modify, will be set in xr_scene.gd automatically
var primary_controller : XRController3D
# Convenience Secondary (movement/off-hand) controller set by user, do not modify, will be set in xr_scene.gd automatically
var secondary_controller : XRController3D
# Convenience XR Scene reference (the parent node of all of UGVR), do not modify, will be set in xr_scene.gd
var xr_scene : Node3D = null
# Convenience reference to the node at the top of the scene tree in any game, allows finding or getting other nodes in game scene tree
var scene_root = null
# Track whether single use function has already been called
var on_xr_setup_already_run : bool = false

# Called when the node enters the scene tree for the first time.  Can't use controller references yet as they will not be set up yet.
func _ready():
	pass

# Called only once after xr scene and all convenience variables are set, insert any code you want to run then here
# Note that you can now access any of the xr scene variables directly, example: xr_scene.xr_pointer.enabled=false
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
	remote_transform.remote_path = game_node.get_path()

# Convenience function to move game node to track HMD, may not work in all instances, offset is x, y, z relative to HMD
func reparent_game_node_to_hmd(game_node : Node3D, hmd : XRCamera3D, offset: Vector3 = Vector3(0,0,0)) -> void:
	var remote_transform : RemoteTransform3D = RemoteTransform3D.new()
	var node_holder : Node3D = Node3D.new()
	hmd.add_child(node_holder)
	node_holder.transform.origin = offset
	node_holder.add_child(remote_transform)
	remote_transform.remote_path = game_node.get_path()

# Setter function for xr_scene reference, called in xr_scene.gd automatically
func set_xr_scene(new_xr_scene) -> void:
	xr_scene = new_xr_scene
	scene_root = get_node("/root")
