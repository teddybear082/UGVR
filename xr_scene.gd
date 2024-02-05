extends Node3D

var xr_interface: XRInterface

@onready var xr_origin_3d : XROrigin3D = $XROrigin3D
@onready var xr_camera_3d : XRCamera3D = $XROrigin3D/XRCamera3D
@onready var xr_main_viewport2d_in_3d : Node3D = $XROrigin3D/XRCamera3D/XRMainViewport2Din3D


func _ready() -> void:
	set_process(false)
	
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

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
	# Get active camera3D
	var active_camera : Camera3D = get_viewport().get_camera_3d()
	
	# Check if we've found active_camera before by determining if its in our custom group, if not add it to group and add remote transform
	if not active_camera.is_in_group("possible_xr_cameras"):
		active_camera.add_to_group("possible_xr_cameras")
		var remote_t : RemoteTransform3D = RemoteTransform3D.new()
		remote_t.update_rotation = false
		remote_t.update_scale = false
		remote_t.remote_path = xr_origin_3d.get_path()
		active_camera.add_child(remote_t)
	
	# Do we need to do something to remove the remote transforms from other cameras here? Remains to be seen.
	# If so could cycle through group of possible cameras and remove.
	
	# Get active menu scene / UI
	var active_gui = get_viewport().gui_get_focus_owner()
	print(active_gui)
	if active_gui != null:
		var viewport_gui = active_gui.duplicate()
		viewport_gui.get_parent().remove_child(viewport_gui)
		#xr_main_viewport2d_in_3d.set_viewport_size(active_gui.get_size())
		xr_main_viewport2d_in_3d.get_node("Viewport").add_child(viewport_gui)
	
	 
