# This is the main VR Scene that is injected into the 3D game.
# The method for this was developed by Decacis (creator of Badaboom on AppLab)
# Then JulianTodd (creator of TunnelVR on AppLab/Sidequest) developed a way to allow VR pointers to be used in the game's 2D UI
# Along with the code in injector.gd developed by Decacis, these form the core parts of injecting VR into a Godot 3D game

extends Node3D

# Core XR Scene Components
@onready var xr_origin_3d : XROrigin3D = $XROrigin3D
@onready var xr_start : Node = xr_origin_3d.get_node("StartXR")
@onready var xr_camera_3d : XRCamera3D = xr_origin_3d.get_node("XRCamera3D")
@onready var xr_main_viewport2d_in_3d : Node3D = xr_camera_3d.get_node("XRMainViewport2Din3D")
@onready var xr_main_viewport2d_in_3d_subviewport : SubViewport = xr_main_viewport2d_in_3d.get_node("Viewport")
@onready var xr_secondary_viewport2d_in_3d : Node3D = xr_camera_3d.get_node("XRSecondaryViewport2Din3D")
@onready var xr_secondary_viewport2d_in_3d_subviewport : SubViewport = xr_secondary_viewport2d_in_3d.get_node("Viewport")
@onready var xr_left_controller : XRController3D = xr_origin_3d.get_node("XRController3D")
@onready var xr_right_controller : XRController3D = xr_origin_3d.get_node("XRController3D2")
@onready var gesture_area : Area3D = xr_camera_3d.get_node("GestureArea")
@onready var left_gesture_detection_area : Area3D = xr_left_controller.get_node("GestureDetectionArea")
@onready var right_gesture_detection_area : Area3D = xr_right_controller.get_node("GestureDetectionArea")
@onready var left_xr_pointer = xr_left_controller.get_node("XRPointer")
@onready var right_xr_pointer = xr_right_controller.get_node("XRPointer")
@onready var welcome_label_3d = xr_camera_3d.get_node("WelcomeLabel3D")
# Variables to hold mapping other events necessary for gamepad emulation with motion controllers
var primary_action_map : Dictionary
var secondary_action_map : Dictionary

var grip_deadzone : float = 0.7
var left_x_axis : InputEventJoypadMotion = InputEventJoypadMotion.new()
var left_y_axis : InputEventJoypadMotion = InputEventJoypadMotion.new()
var right_x_axis : InputEventJoypadMotion = InputEventJoypadMotion.new()
var right_y_axis : InputEventJoypadMotion = InputEventJoypadMotion.new()
var dpad_up : InputEventJoypadButton = InputEventJoypadButton.new()
var dpad_down : InputEventJoypadButton = InputEventJoypadButton.new()
var dpad_left : InputEventJoypadButton = InputEventJoypadButton.new()
var dpad_right : InputEventJoypadButton = InputEventJoypadButton.new()

# Store state of dpad toggle
var dpad_toggle_active : bool = false

# Store state of start activation
var start_toggle_active : bool = false

# Store state of select activation
var select_toggle_active : bool = false

# Button to toggle VR pointers with head gesture - eventually configurable
var pointer_gesture_toggle_button = "trigger_click"

# Button to activate dpad alternative binding for joystick
var dpad_activation_button = "primary_touch"

# Button to activate start button
var start_activation_button = "primary_touch"

# Button to activate select button
var select_activation_button = "primary_touch"

# Start button (when toggle active)
var start_button = "primary_click"

# Select button (when toggle active)
var select_button = "by_button"

# Prepare for eventual user configs to set primary and secondary controllers
var primary_controller : XRController3D
var primary_detection_area : Area3D
var secondary_controller = XRController3D
var secondary_detection_area : Area3D
var primary_pointer = null
var secondary_pointer = null
var current_camera = null
var current_camera_remote_transform = null

var xr_interface : XRInterface
var xr_world_scale : float = 1.0
var enable_passthrough : bool = false
var disable_2d_ui : bool = false
var gui_embed_subwindows : bool = false
var show_welcome_label : bool = true
var already_set_up : bool = false

func _ready() -> void:
	set_process(false)
	xr_start.connect("xr_started", Callable(self, "_on_xr_started"))

func _process(_delta : float) -> void:
	# Trigger method to find active camera and parent XR scene to it at regular intervals
	if Engine.get_process_frames() % 90 == 0:
		_eval_tree_new()
	
	# Process emulated joypad inputs, someday maybe this could be a toggle in the event someone wants to use gamepad only controls
	process_joystick_inputs()

# Constantly checks for current camera 3D
func _eval_tree_new() -> void:
	# Ensure Vsync stays OFF!
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# Try automatically overwriting game options to set max FPS at 144 to avoid hard caps at low frame rate
	Engine.set_max_fps(144)
	
	# Get active camera3D by looking for an array of Camera3D nodes in the scene tree
	var remote_t : RemoteTransform3D = null
	var cameras : Array = get_node("/root").find_children("*", "Camera3D", true, false)
	#print(cameras)
	# For each camera, check if it's not our XR Camera
	for camera in cameras:
		if camera != xr_camera_3d:
			# If we haven't found camera before, add it to our group for possible group functions someday, and add a remote transform
			if not camera.is_in_group("possible_xr_cameras"):
				camera.add_to_group("possible_xr_cameras")
				print("New camera found: ", camera)
				print("Camera's viewport is: ", camera.get_viewport())
				print("Camera's window is: ", camera.get_window())
				remote_t = RemoteTransform3D.new()
				remote_t.name = "XRRemoteTransform"
				remote_t.update_rotation = false
				remote_t.update_scale = false
				remote_t.remote_path = xr_origin_3d.get_path()
				camera.add_child(remote_t)
			# Regardless of whether we have found it before, if it's not the current camera driving the xr camera in the scene, but it is the current 3d camera on the same viewport, activate it
			if camera != current_camera and camera.current == true and camera.get_viewport() == xr_camera_3d.get_viewport():
				print("Found a current camera that is not xr camera_3d: ", camera)
				print("Camera's viewport is: ", camera.get_viewport())
				print("Camera's window is: ", camera.get_window())
				if current_camera_remote_transform != null:
					print("Clearing previous remote transform")
					current_camera_remote_transform.remote_path = ""
				current_camera_remote_transform = camera.find_child("*XRRemoteTransform*",false,false)
				print("Current camera remote transform: ", current_camera_remote_transform)
				current_camera_remote_transform.remote_path = xr_origin_3d.get_path()
				current_camera = camera


	# Find canvas layer and display it
	# This works, only remaining problem is canvas layer is too small in some games, likely because canvas layer or content have been downscaled
	var potential_canvas_layer_nodes : Array = get_node("/root").find_children("*", "CanvasLayer", true, false)
	#print("Potential canvas layer nodes: ", potential_canvas_layer_nodes)
	
	if potential_canvas_layer_nodes != []:
		
		for canvas_layer in potential_canvas_layer_nodes:
			if canvas_layer.visible == true and not canvas_layer.is_in_group("active_canvas_layers"):
				print("making canvas layer active: ", canvas_layer)
				canvas_layer.add_to_group("active_canvas_layers")
				canvas_layer.set_custom_viewport(xr_main_viewport2d_in_3d_subviewport)


	# if user enabled passthrough mode, try to enable it by finding world environment and setting sky to passthrough color (may not work, need to test on airlink/oculus)
	if enable_passthrough and xr_interface.is_passthrough_supported():
		var passthrough_color = Color(0,0,0,0.2)
		print("trying passthrough setup")
		var potential_world_environment_nodes : Array = get_node("/root").find_children("*", "WorldEnvironment", true, false)
		if potential_world_environment_nodes != []:
			for world_environment in potential_world_environment_nodes:
				if not world_environment.is_in_group("world_environment_nodes"):
					print("New world environment node found: ", world_environment)
					print(world_environment.print_tree_pretty())
					world_environment.add_to_group("world_environment_nodes")
					var environment : Environment = world_environment.get_environment()
					environment.set_bg_color(passthrough_color)
					environment.set_background(Environment.BG_COLOR)
		
			enable_passthrough = xr_interface.start_passthrough()


# Function to set up VR Controllers to emulate gamepad
func map_xr_controllers_to_action_map():
	print("mapping controls")
	
	primary_controller = xr_right_controller
	primary_detection_area = right_gesture_detection_area
	secondary_controller = xr_left_controller
	secondary_detection_area = left_gesture_detection_area
	primary_pointer = right_xr_pointer
	secondary_pointer = left_xr_pointer
	
	print(secondary_controller)
	print(primary_controller)
	
	# Print action map for debugging - someday maybe can facilitate user remapping of actions as alternative to general keybinds
	var flat_screen_actions = InputMap.get_actions()
	for action in flat_screen_actions:
		var action_events = InputMap.action_get_events(action)
		print("Action: ", action, " Events: ", action_events)
		for event in action_events:
			if event is InputEventJoypadButton:
				print(event)
	
	# Connect controller button and joystick signals to handlers
	secondary_controller.connect("button_pressed", Callable(self, "handle_secondary_xr_inputs"))
	primary_controller.connect("button_pressed", Callable(self,"handle_primary_xr_inputs"))
	secondary_controller.connect("button_released", Callable(self,"handle_secondary_xr_release"))
	primary_controller.connect("button_released", Callable(self,"handle_primary_xr_release"))
	secondary_controller.connect("input_float_changed", Callable(self, "handle_secondary_xr_float"))
	primary_controller.connect("input_float_changed", Callable(self, "handle_primary_xr_float"))
	primary_controller.connect("input_vector2_changed", Callable(self, "primary_stick_moved"))
	# Will be a configurable option which stick turns, for now assume primary
	#secondary_controller.connect("input_vector2_changed", Callable(self, "secondary_stick_moved"))
	
	# Map xr button input to joypad inputs
	
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
	
	# Map xr controller joysticks to gamepad joysticks
	left_x_axis.axis = JOY_AXIS_LEFT_X
	left_y_axis.axis = JOY_AXIS_LEFT_Y
	right_x_axis.axis = JOY_AXIS_RIGHT_X
	right_y_axis.axis = JOY_AXIS_RIGHT_Y
	
	# Create gamepad dpad inputs for emulation
	dpad_up.button_index = JOY_BUTTON_DPAD_UP
	dpad_down.button_index = JOY_BUTTON_DPAD_DOWN
	dpad_left.button_index = JOY_BUTTON_DPAD_LEFT
	dpad_right.button_index = JOY_BUTTON_DPAD_RIGHT

# Handle button presses on VR controller assigned as primary
func handle_primary_xr_inputs(button):
	#print("primary contoller button pressed: ", button)
	
	# Toggle pointers if user holds primary hand over their head and presses toggle button
	if button == pointer_gesture_toggle_button and gesture_area.overlaps_area(primary_detection_area):
		primary_pointer.set_enabled(!primary_pointer.enabled)
		secondary_pointer.set_enabled(!secondary_pointer.enabled)
	
	# If user just pressed activation button, activate special combo buttons
	if button == dpad_activation_button:
		dpad_toggle_active = true
		print("dpad toggle active")
		
	if button == start_activation_button:
		start_toggle_active = true
		print("start toggle active")
		
	if button == select_activation_button:
		select_toggle_active = true
		print("select toggle active")
	
	# Finally pass through remaining gamepad emulation input
	if primary_action_map.has(button):
		var event = InputEventJoypadButton.new()
		event.button_index = primary_action_map[button]
		event.pressed = true
		Input.parse_input_event(event)
	
	# Saved code to handle other ways of triggering input in case later we allow game custom action mapping
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

# Handle release of buttons on primary controller
func handle_primary_xr_release(button):
	#print("primary button released: ", button)
	if button == dpad_activation_button:
		dpad_toggle_active = false
		print("dpad toggle off")
		
	if button == start_activation_button:
		start_toggle_active = false
		print("start toggle off")
		
	if button == select_activation_button:
		select_toggle_active = false
		print("select toggle off")
	
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

# Handle button presses on VR Controller assigned as secondary
func handle_secondary_xr_inputs(button):
	#print("secondary button pressed: ", button)

	# If pressing pointer activation button and making gesture, toggle pointer
	if button == pointer_gesture_toggle_button and gesture_area.overlaps_area(secondary_detection_area):
		primary_pointer.set_enabled(!primary_pointer.enabled)
		secondary_pointer.set_enabled(!secondary_pointer.enabled)
	
	if start_toggle_active and button == start_button:
		var event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_START
		event.pressed = true
		Input.parse_input_event(event)
		
	if select_toggle_active and button == select_button:
		var event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_BACK
		event.pressed = true
		Input.parse_input_event(event)
	
	if secondary_action_map.has(button):
		var event = InputEventJoypadButton.new()
		event.button_index = secondary_action_map[button]
		event.pressed = true
		Input.parse_input_event(event)
	
# Handle release of buttons on VR Controller assigned as secondary	
func handle_secondary_xr_release(button):
	#print("secondary button released: ", button)
	if button == start_button:
		var event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_START
		event.pressed = false
		Input.parse_input_event(event)
	
	if button == select_button:
		var event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_BACK
		event.pressed = false
		Input.parse_input_event(event)
	
	if secondary_action_map.has(button):
		var event = InputEventJoypadButton.new()
		event.button_index = secondary_action_map[button]
		event.pressed = false
		Input.parse_input_event(event)

# Handle analogue button presses on VR controller assigned as primary
func handle_primary_xr_float(button, value):
	#print(button)
	#print(value)
	if button == "trigger":
		var event = InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_TRIGGER_RIGHT
		event.axis_value = value
		Input.parse_input_event(event)
		
	if button == "grip":
		var event = InputEventJoypadButton.new()
		event.button_index = primary_action_map["grip"]
		if value >= grip_deadzone:
			event.pressed = true
		else:
			event.pressed=false
		Input.parse_input_event(event)

# Handle analogue button presses on VR Controller assigned as secondary	 	
func handle_secondary_xr_float(button, value):
	#print(button)
	#print(value)
	if button == "trigger":
		var event = InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_TRIGGER_LEFT
		event.axis_value = value
		Input.parse_input_event(event)
		
	if button == "grip":
		var event = InputEventJoypadButton.new()
		event.button_index = secondary_action_map["grip"]
		if value >= grip_deadzone:
			event.pressed = true
		else:
			event.pressed=false
		Input.parse_input_event(event)

# Always process joystick analogue inputs
func process_joystick_inputs():
	# For some reason xr y input values are reversed, so we have to negate those
	# Probably have to make these primary and secondary at some point too
	# Also likely have to include option to turn off x axis handling for primary if stick turning used
	
	left_x_axis.axis_value = xr_left_controller.get_vector2("primary").x
	left_y_axis.axis_value = -xr_left_controller.get_vector2("primary").y
	
	right_x_axis.axis_value = xr_right_controller.get_vector2("primary").x
	right_y_axis.axis_value = -xr_right_controller.get_vector2("primary").y
	
	# If dpad toggle button is active, then send joystick inputs to dpad instead
	if dpad_toggle_active:
		if left_x_axis.axis_value < -0.5:
			dpad_left.pressed = true
			Input.parse_input_event(dpad_left)
		else:
			dpad_left.pressed = false
			Input.parse_input_event(dpad_left)
			
			
		if left_x_axis.axis_value >= 0.5:
			dpad_right.pressed = true
			Input.parse_input_event(dpad_right)
		else:
			dpad_right.pressed = false
			Input.parse_input_event(dpad_right)
			
			
		if left_y_axis.axis_value < -0.5:
			dpad_up.pressed = true
			Input.parse_input_event(dpad_up)
		else:
			dpad_up.pressed = false
			Input.parse_input_event(dpad_up)
			
		if left_y_axis.axis_value >= 0.5:
			dpad_down.pressed = true
			Input.parse_input_event(dpad_down)
		else:
			dpad_down.pressed = false
			Input.parse_input_event(dpad_down)
	
	# Otherwise process joystick like normal		
	else:
		Input.parse_input_event(left_x_axis)
		Input.parse_input_event(left_y_axis)
		Input.parse_input_event(right_x_axis)
		Input.parse_input_event(right_y_axis)


# Decacis Smooth / Stick turning code

enum TurningType {
	SNAP = 0,
	SMOOTH = 1
}

const DEADZONE : float = 0.65

var last_stick_val : Vector2 = Vector2.ZERO
var current_controller = null
var currently_rotating : bool = false
var already_performed_rotation : bool = false

var turning_type : TurningType = TurningType.SNAP
var turning_speed : float = 90.0
var turning_degrees : float = 30.0


# Again could include option to use secondary stick someday but turning off for now
#func secondary_stick_moved(stick_name : String, value : Vector2) -> void:
	#_stick_handler(secondary_controller, stick_name, value)
			
func primary_stick_moved(stick_name : String, value : Vector2) -> void:
	_stick_handler(primary_controller, stick_name, value)


func _stick_handler(c_controller : XRController3D, stick_name : String, value : Vector2) -> void:
	if current_controller == null or current_controller == c_controller:
		
		if stick_name == "primary":
			# Set stick value. Correct dead zones
			# https://web.archive.org/web/20191208161810/http://www.third-helix.com/2013/04/12/doing-thumbstick-dead-zones-right.html
			last_stick_val = Vector2(value.x, value.y)
			if last_stick_val.length() < DEADZONE:
				last_stick_val = Vector2.ZERO
			else:
				last_stick_val = last_stick_val.normalized() * ((last_stick_val.length() - DEADZONE) / (1 - DEADZONE))
		
		if not already_performed_rotation:
			
			if not currently_rotating and (last_stick_val.x < -0.5 or last_stick_val.x > 0.5):
				_handle_camera_rotation_request(c_controller)
			
			elif last_stick_val.x > -0.5 and last_stick_val.x < 0.5:
				currently_rotating = false
				current_controller = null
		
		elif last_stick_val.x > -0.5 and last_stick_val.x < 0.5:
			already_performed_rotation = false
			currently_rotating = false
			current_controller = null


func _handle_camera_rotation_request(controller : XRController3D) -> void:
	currently_rotating = true
	current_controller = controller
	
	var rotation_angle : float = deg_to_rad(turning_degrees)
	
	if turning_type == TurningType.SNAP:
		
		if last_stick_val.x < 0:
			rotation_angle = -rotation_angle
			
		_handle_rotation(rotation_angle)
		already_performed_rotation = true
	
	elif turning_type == TurningType.SMOOTH:
		_smooth_rotate()


func _smooth_rotate() -> void:
	if currently_rotating:
		var angle2 : float = deg_to_rad(turning_speed) * get_process_delta_time()
		
		if last_stick_val.x < 0:
			angle2 = -angle2
		
		_handle_rotation(angle2)
		
		await get_tree().process_frame
		if currently_rotating:
			_smooth_rotate()


func _handle_rotation(angle : float) -> void:
	var t1 : Transform3D = Transform3D()
	var t2 : Transform3D = Transform3D()
	var rot : Transform3D = Transform3D()

	t1.origin = -xr_camera_3d.transform.origin
	t2.origin = xr_camera_3d.transform.origin
	rot = rot.rotated(Vector3(0.0, -1.0, 0.0), angle) ## <-- this is the rotation around the camera
	xr_origin_3d.transform = (xr_origin_3d.transform * t2 * rot * t1).orthonormalized()


func _on_xr_started():
	# Only set up once not every time user goes in and out of VR
	if already_set_up:
		return
	# Turn off v-sync!
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	xr_interface = XRServer.find_interface("OpenXR")
		
	# Set viewport2din3d to correct size
	var vp_size = xr_interface.get_render_target_size()
	print("Viewport size: ", vp_size)
	# Should the following be disabled?
	#xr_main_viewport2d_in_3d.set_viewport_size(vp_size)
		
	# Set xr viewport2d_in_3d's subviewport to the same world2d as the main viewport, this allows 2D UI to appear in VR
	if disable_2d_ui == false:
		print("Viewport world2d: ", get_viewport().world_2d)
		#get_viewport().vrs_mode = Viewport.VRS_DISABLED
		#get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		#get_viewport().use_hdr_2d = false
		#get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		xr_main_viewport2d_in_3d_subviewport.world_2d = get_viewport().world_2d
		xr_main_viewport2d_in_3d._update_render()

	if gui_embed_subwindows == true:
		get_viewport().gui_embed_subwindows = true
	
	else:
		get_viewport().gui_embed_subwindows = false
	
	# Enable input calculations on main viewport 2D UI with Viewport2Din3D node
	print("xr viewport ", get_viewport())
	print("static body viewport before rewrite: ", xr_main_viewport2d_in_3d.get_node("StaticBody3D")._viewport)
	xr_main_viewport2d_in_3d.get_node("StaticBody3D")._viewport = get_viewport()
	print("static body viewport after rewrite: ", xr_main_viewport2d_in_3d.get_node("StaticBody3D")._viewport)

	# Setup secondary viewport for use with canvaslayer node contents, if any found
	xr_secondary_viewport2d_in_3d.set_viewport_size(xr_main_viewport2d_in_3d.viewport_size)
		
	# Set up xr controllers to emulate gamepad
	map_xr_controllers_to_action_map()
		
	# Set XR worldscale (eventually user configurable)
	xr_origin_3d.world_scale = xr_world_scale
		
	# Print final viewport and window of xr camera
	print("XR Camera's viewport is: ", xr_camera_3d.get_viewport())
	print("XR Camera's window is: ", xr_camera_3d.get_window()) 
	
	set_process(true)

	# Clear Welcome label (probably someday can make it a config not to show again)
	if show_welcome_label:
		welcome_label_3d.show()
		await get_tree().create_timer(12.0).timeout
		welcome_label_3d.hide()
	
	# Once set up, don't do it again during session
	already_set_up = true
