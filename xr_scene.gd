extends Node3D

var xr_interface: XRInterface

@onready var xr_origin_3d : XROrigin3D = $XROrigin3D
@onready var xr_camera_3d : XRCamera3D = xr_origin_3d.get_node("XRCamera3D")
@onready var xr_main_viewport2d_in_3d : Node3D = xr_camera_3d.get_node("XRMainViewport2Din3D")
@onready var xr_main_viewport2d_in_3d_subviewport : SubViewport = xr_main_viewport2d_in_3d.get_node("Viewport")

var active_ui_node

func _ready() -> void:
	set_process(false)
	
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
		# Set viewport2din3d to correct size
		var vp_size : Vector2 = xr_interface.get_render_target_size()
		xr_main_viewport2d_in_3d.set_viewport_size = vp_size
		
		# Set xr viewport2d_in_3d's subviewport to the same world2d as the main viewport
		# Right now have subviewport set to not handle input which is a change from default, need to think more about this
		xr_main_viewport2d_in_3d_subviewport.world_2d = get_viewport().world_2d
		xr_main_viewport2d_in_3d._update_render()

		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true
		get_viewport().gui_embed_subwindows = false
		
		set_process(true)
	else:
		print("OpenXR not initialized, please check if your headset is connected")


func _process(_delta : float) -> void:
	#if Engine.get_process_frames() % 30 == 0:
	if Engine.get_process_frames() % 90 == 0:
		#_eval_tree()
		_eval_tree_new()

# Original decacis version, checks for Cameras once in scene tree
func _eval_tree() -> void:
	#print(Settings.CONFIG_FILE_PATH)
	var cameras : Array = get_node("/root").find_children("*", "Camera3D", true, false)
	
	for camera in cameras:
		if camera != xr_camera_3d:
			set_process(false)
		
			var remote_t : RemoteTransform3D = RemoteTransform3D.new()
			
			remote_t.update_rotation = false
			remote_t.update_scale = false
			
			remote_t.remote_path = xr_origin_3d.get_path()
			
			camera.add_child(remote_t)

# Possible alternative version, constantly checks for current camera 3D, will have to determine later which works best
func _eval_tree_new() -> void:
	# Ensure Vsync stays OFF!
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# Try automatically overwriting game options to set max FPS at 144
	Engine.set_max_fps(144)
	
	# Get active camera3D
	var active_camera : Camera3D = get_viewport().get_camera_3d()
	
	# Check if we've found active_camera before by determining if its in our custom group, if not add it to group and add remote transform
	if active_camera:
		if not active_camera.is_in_group("possible_xr_cameras"):
			active_camera.add_to_group("possible_xr_cameras")
			var remote_t : RemoteTransform3D = RemoteTransform3D.new()
			remote_t.update_rotation = false
			remote_t.update_scale = false
			remote_t.remote_path = xr_origin_3d.get_path()
			active_camera.add_child(remote_t)
	
	# fallback
	if not active_camera:
		var cameras : Array = get_node("/root").find_children("*", "Camera3D", true, false)
		print(cameras)
		for camera in cameras:
			if camera != xr_camera_3d:
				set_process(false)
			
				var remote_t : RemoteTransform3D = RemoteTransform3D.new()
				
				remote_t.update_rotation = false
				remote_t.update_scale = false
				
				remote_t.remote_path = xr_origin_3d.get_path()
				
				camera.add_child(remote_t)
	
	# Do we need to do something to remove the remote transforms from other cameras here? Remains to be seen.
	# If so could cycle through group of possible cameras and remove.
	
	# Get active menu scene / UI
	#var active_gui = get_viewport().gui_get_focus_owner()
	# In TPS demo, this returns the play button essentially. Maybe check up scene tree until node is no longer a Control, and use last one found as UI to display?
	#print(active_gui)
	#if active_gui != null:
		#var viewport_gui = active_gui.duplicate()
		#viewport_gui.get_parent().remove_child(viewport_gui)
		#xr_main_viewport2d_in_3d.set_viewport_size(active_gui.get_size())
		#xr_main_viewport2d_in_3d.get_node("Viewport").add_child(viewport_gui)
	
	# Get all UI nodes that have the potential to be a top level menu
	#var potential_ui_nodes : Array = get_node("/root").find_children("*", "Control", true, false)
	#var ui_node_final_candidates : Array = []
	#for ui_node in potential_ui_nodes:
		#if ui_node.is_class("Container") or ui_node.is_class("ColorRect") or ui_node.is_class("Panel") or ui_node.get_class() == "Control":
			## Check if we've found ui_node  before by determining if its in our custom group, if not add it to group
			#if not ui_node.is_in_group("possible_xr_uis"):
				#ui_node.add_to_group("possible_xr_uis")
				#ui_node_final_candidates.append(ui_node)
	##print(ui_node_final_candidates)
	## Assume first one found that is visible is our UI? Find children will search recursively so best candidates are likely near top of list if not the top?
	#for ui_node in ui_node_final_candidates:
		#if ui_node.is_visible_in_tree():
			#if active_ui_node != ui_node:
				#active_ui_node = ui_node
				#print(active_ui_node)
				#break
	#if active_ui_node != null:
		#var new_viewport_ui_node = active_ui_node.duplicate()
		#print(new_viewport_ui_node)
		#print(new_viewport_ui_node.get_tree_string_pretty())
		#xr_main_viewport2d_in_3d.get_node("Viewport").add_child(new_viewport_ui_node)
		#xr_main_viewport2d_in_3d._update_render()
		#set_process(false)

	# Possible replacement to allow code to continue to run
	#for ui_node in ui_node_final_candidates:
		#if ui_node.is_visible_in_tree():
			#if active_ui_node != ui_node:
				#new_viewport_ui_node = ui_node.duplicate()
				#xr_main_viewport2d_in_3d.get_node("Viewport").add_child(new_viewport_ui_node)
				#xr_main_viewport2d_in_3d._update_render()
				#active_ui_node = new_viewport_ui_node
