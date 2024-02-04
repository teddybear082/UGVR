extends Node3D

var xr_interface: XRInterface

@onready var xr_origin_3d : XROrigin3D = $XROrigin3D
@onready var xr_camera_3d : XRCamera3D = $XROrigin3D/XRCamera3D


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
		_eval_tree()


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
