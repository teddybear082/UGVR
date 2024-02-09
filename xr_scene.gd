# This is the main VR Scene that is injected into the 3D game.
# The method for this was developed by Decacis (creator of Badaboom on AppLab)
# Then JulianTodd (creator of TunnelVR on AppLab/Sidequest) developed a way to allow VR pointers to be used in the game's 2D UI
# Along with the code in injector.gd developed by Decacis, these form the core parts of injecting VR into a Godot 3D game

extends Node3D

@onready var xr_origin_3d : XROrigin3D = $XROrigin3D
@onready var xr_camera_3d : XRCamera3D = xr_origin_3d.get_node("XRCamera3D")
@onready var xr_main_viewport2d_in_3d : Node3D = xr_camera_3d.get_node("XRMainViewport2Din3D")
@onready var xr_main_viewport2d_in_3d_subviewport : SubViewport = xr_main_viewport2d_in_3d.get_node("Viewport")
@onready var xr_left_controller : XRController3D = xr_origin_3d.get_node("XRController3D")
@onready var xr_right_controller : XRController3D = xr_origin_3d.get_node("XRController3D2")

var primary_action_map : Dictionary
var secondary_action_map : Dictionary
var xr_interface: XRInterface


#var active_ui_node


func _ready() -> void:
	set_process(false)
	
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
		# Set viewport2din3d to correct size
		var vp_size : Vector2 = xr_interface.get_render_target_size()
		print("Viewport size: ", vp_size)
		xr_main_viewport2d_in_3d.set_viewport_size = vp_size
		
		# Set xr viewport2d_in_3d's subviewport to the same world2d as the main viewport, this allows 2D UI to appear in VR
		xr_main_viewport2d_in_3d_subviewport.world_2d = get_viewport().world_2d
		xr_main_viewport2d_in_3d._update_render()

		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true
		get_viewport().gui_embed_subwindows = false
		print("xr viewport ", get_viewport())
		
		# Enable input calculations on main viewport 2D UI with Viewport2Din3D node
		print("static body viewport before rewrite: ", xr_main_viewport2d_in_3d.get_node("StaticBody3D")._viewport)
		xr_main_viewport2d_in_3d.get_node("StaticBody3D")._viewport = get_viewport()
		print("static body viewport after rewrite: ", xr_main_viewport2d_in_3d.get_node("StaticBody3D")._viewport)

		map_xr_controllers_to_action_map()
		
		set_process(true)
	else:
		print("OpenXR not initialized, please check if your headset is connected")


func _process(_delta : float) -> void:
	if Engine.get_process_frames() % 90 == 0:
		_eval_tree_new()
	
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
			print("New active camera found")
			active_camera.add_to_group("possible_xr_cameras")
			print("Active camera: ", active_camera)
			var remote_t : RemoteTransform3D = RemoteTransform3D.new()
			remote_t.update_rotation = false
			remote_t.update_scale = false
			remote_t.remote_path = xr_origin_3d.get_path()
			active_camera.add_child(remote_t)
	
	# fallback
	if not active_camera:
		print("No active cameras found, reverting to fallback search of cameras")
		var cameras : Array = get_node("/root").find_children("*", "Camera3D", true, false)
		print(cameras)
		for camera in cameras:
			if camera != xr_camera_3d:
				#set_process(false)
				if camera.is_current() and not camera.is_in_group("possible_xr_cameras"):
					camera.add_to_group("possible_xr_cameras")
					print("final camera selected: ", camera)
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

func map_xr_controllers_to_action_map():
	print("mapping controls")
	print(xr_left_controller)
	print(xr_right_controller)
	var flat_screen_actions = InputMap.get_actions()
	for action in flat_screen_actions:
		var action_events = InputMap.action_get_events(action)
		print("Action: ", action, " Events: ", action_events)
		for event in action_events:
			if event is InputEventJoypadButton:
				print(event)
	xr_left_controller.connect("button_pressed", Callable(self, "handle_secondary_xr_inputs"))
	xr_right_controller.connect("button_pressed", Callable(self,"handle_primary_xr_inputs"))
	xr_left_controller.connect("button_released", Callable(self,"handle_secondary_xr_release"))
	xr_right_controller.connect("button_released", Callable(self,"handle_primary_xr_release"))
	xr_left_controller.connect("input_float_changed", Callable(self, "handle_secondary_xr_float"))
	xr_right_controller.connect("input_float_changed", Callable(self, "handle_primary_xr_float"))
	xr_left_controller.connect("input_vector2_changed", Callable(self, "handle_secondary_xr_vector2"))
	xr_right_controller.connect("input_vector2_changed", Callable(self, "handle_primary_xr_vector2"))
	
	
	primary_action_map = {
		"grip_click":JOY_BUTTON_RIGHT_SHOULDER,
		"primary_click":JOY_BUTTON_RIGHT_STICK,
		"ax_button":JOY_BUTTON_A,
		"by_button":JOY_BUTTON_X
	}
	secondary_action_map = {
		"grip_click":JOY_BUTTON_LEFT_SHOULDER,
		"primary_click":JOY_BUTTON_LEFT_STICK,
		"ax_button":JOY_BUTTON_B,
		"by_button":JOY_BUTTON_Y
	}
	
	

func handle_primary_xr_inputs(button):
	if primary_action_map.has(button):
		var event = InputEventJoypadButton.new()
		event.button_index = primary_action_map[button]
		event.pressed = true
		Input.parse_input_event(event)
	#print("pressed button",button)
	#if button == "ax_button":
		#print("detected ax button press")
		#var ax_event = InputEventJoypadButton.new()
		#ax_event.button_index = 0
		#ax_event.pressed = true
		#Input.parse_input_event(ax_event)
		# If there was action mapping, which may be a good alternative option to allow someday, this is how it would work:
		#Input.action_press(&"jump")
	#if button == "by_button":
		#print("detected by button press")
		#var by_event = InputEventJoypadButton.new()
		#by_event.button_index = JOY_BUTTON_B
		#by_event.pressed = true
		#Input.parse_input_event(by_event)
		#Input.action_press(&"shoot")

func handle_primary_xr_release(button):
	if primary_action_map.has(button):
		var event = InputEventJoypadButton.new()
		event.button_index = primary_action_map[button]
		event.pressed = false
		Input.parse_input_event(event)
	#print("released button", button)
	#if button == "ax_button":
		# If there was action mapping, which may be a good alternative option to allow someday, this is how it would work:
		#Input.action_release(&"jump")
		#var ax_event = InputEventJoypadButton.new()
		#ax_event.button_index = 0
		#ax_event.pressed = false
		#Input.parse_input_event(ax_event)
	
	#if button == "by_button":
		#Input.action_release(&"shoot")
		#var by_event = InputEventJoypadButton.new()
		#by_event.button_index = JoyButton.JOY_BUTTON_B
		#by_event.pressed = false
		#Input.parse_input_event(by_event)


func handle_secondary_xr_inputs(button):
	if secondary_action_map.has(button):
		var event = InputEventJoypadButton.new()
		event.button_index = secondary_action_map[button]
		event.pressed = true
		Input.parse_input_event(event)
	
	
func handle_secondary_xr_release(button):
	if secondary_action_map.has(button):
		var event = InputEventJoypadButton.new()
		event.button_index = secondary_action_map[button]
		event.pressed = false
		Input.parse_input_event(event)

func handle_primary_xr_float(button, value):
	print(button)
	print(value)

func handle_secondary_xr_float(button, value):
	print(button)
	print(value)
	
func handle_primary_xr_vector2(button, value):
	print(button)
	print(value)
	
func handle_secondary_xr_vector2(button, value):
	print(button)
	print(value)
