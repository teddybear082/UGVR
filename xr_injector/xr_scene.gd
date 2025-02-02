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
@onready var xr_left_hand : Node3D = xr_left_controller.get_node("LeftHand")
@onready var xr_right_hand : Node3D = xr_right_controller.get_node("RightHand")
@onready var gesture_area : Area3D = xr_camera_3d.get_node("GestureArea")
@onready var left_gesture_detection_area : Area3D = xr_left_controller.get_node("GestureDetectionArea")
@onready var right_gesture_detection_area : Area3D = xr_right_controller.get_node("GestureDetectionArea")
@onready var xr_pointer : Node3D = xr_origin_3d.get_node("XRPointer")
@onready var welcome_label_3d : MeshInstance3D = xr_camera_3d.get_node("WelcomeLabel3D")
@onready var xr_config_handler : Node = get_node("XRConfigHandler")
@onready var xr_autosave_timer : Timer = get_node("XRAutoSaveTimer")
@onready var xr_roomscale_controller : Node = xr_origin_3d.get_node("XRRoomscaleController")
@onready var xr_physical_movement_controller : Node = xr_origin_3d.get_node("XRPhysicalMovementController")
@onready var xr_radial_menu : Node3D =  get_node("XRRadialMenu")
@onready var xr_black_out : Node3D = xr_camera_3d.get_node("BlackOut")
@onready var xr_vignette : Node3D = xr_camera_3d.get_node("Vignette")
@onready var xr_reparenting_node : Node3D = get_node("XRReparentingNode")
@onready var xr_reparenting_node_holder : Node3D = xr_reparenting_node.get_node("XRReparentingNodeHolder")
@onready var xr_gui_menu : Node3D = get_node("XRGUIMenu")

# Inrernal variables for xr hands and material (will be set in script)
var show_xr_hands : bool = true
var xr_hand_material = preload("res://xr_injector/hands/materials/labglove_transparent.tres")
var xr_hand_material_choice : int = 0

# Internal variables to hold emulated gamepad/joypad events that are triggered by motion controllers
var secondary_x_axis : InputEventJoypadMotion = InputEventJoypadMotion.new()
var secondary_y_axis : InputEventJoypadMotion = InputEventJoypadMotion.new()
var primary_x_axis : InputEventJoypadMotion = InputEventJoypadMotion.new()
var primary_y_axis : InputEventJoypadMotion = InputEventJoypadMotion.new()
var dpad_up : InputEventJoypadButton = InputEventJoypadButton.new()
var dpad_down : InputEventJoypadButton = InputEventJoypadButton.new()
var dpad_left : InputEventJoypadButton = InputEventJoypadButton.new()
var dpad_right : InputEventJoypadButton = InputEventJoypadButton.new()

# Internal variables to store state of dpad toggle
var dpad_toggle_active : bool = false

# Internal variables to store state of start activation
var start_toggle_active : bool = false

# Internal variables to store state of select activation
var select_toggle_active : bool = false

# Internal variables for user configs to set primary and secondary controllers
var primary_controller : XRController3D
var primary_detection_area : Area3D
var secondary_controller = XRController3D
var secondary_detection_area : Area3D

# Internal variables to store states of active camera following/roomscale status
var current_camera : Camera3D = null
var current_camera_remote_transform : RemoteTransform3D = null
var current_roomscale_character_body : CharacterBody3D = null
var xr_interface : XRInterface
var already_set_up : bool = false
var user_height : float = 0.0
var xr_origin_reparented : bool = false
var backup_xr_origin : XROrigin3D = null
var manually_set_camera : bool = false
var manual_set_possible_xr_cameras_idx : int = 0
var ugvr_menu_showing : bool = false

# Internal variables for using cursor3d (mesh attached to active flatscreen camera to enable easier object picking)
var cursor_3d : MeshInstance3D = MeshInstance3D.new()
var cursor_3d_sphere : SphereMesh = SphereMesh.new()
var long_range_cursor_3d : MeshInstance3D = MeshInstance3D.new()
var long_range_cursor_3d_sphere : SphereMesh = SphereMesh.new()
var unshaded_material : StandardMaterial3D = StandardMaterial3D.new()
var target_xr_viewport : Viewport = null

# Internal variables used for reparenting nodes to controllers and smoothing motion
var xr_reparenting_active : bool = false
var xr_two_handed_aim : bool = false

# Internal variables used for Decacis stick turning
const DEADZONE : float = 0.65
var last_stick_val : Vector2 = Vector2.ZERO
var current_controller = null
var currently_rotating : bool = false
var already_performed_rotation : bool = false

# Internal variable to store whether welcome screen already shown
var welcome_label_already_shown : bool = false

# User control configs
# Button to toggle VR pointers with head gesture - eventually configurable
var pointer_gesture_toggle_button = "trigger_click"

# Button to load action map with gesture (temporary, should eventually be GUI) - Needs to be included in config file
var gesture_load_action_map_button = "by_button"

# Button to set height with gesture (temporary, should eventually be GUI) - Needs to be included in config file
var gesture_set_user_height_button = "by_button"

# Button to manually toggle to next potential active camera with head gesture
var gesture_toggle_active_camera_button = "ax_button"

# Button to activate dpad alternative binding for joystick, start and select buttons
var dpad_activation_button = "primary_touch"

# Start button (when toggle active)
var start_button = "primary_click"

# Select button (when toggle active)
var select_button = "by_button"

# UGVR menu button combo - not presently used
var ugvr_menu_toggle_combo : Dictionary = {}

# Selected side for primary controller - left / right
var primary_controller_selection : String = "right"

# Variables to hold mapping other events necessary for gamepad emulation with motion controllers
var primary_action_map : Dictionary
var secondary_action_map : Dictionary

# Additional user config variables
var xr_world_scale : float = 1.0
var experimental_passthrough : bool = false
var xr_use_vehicle_mode : bool = false
var disable_2d_ui : bool = false  # Not presently in config - ever give option?
var gui_embed_subwindows : bool = false # Not presently in config - ever give option?
var show_welcome_label : bool = true
var use_physical_gamepad_only : bool = false
var stick_emulate_mouse_movement : bool = false
var head_emulate_mouse_movement : bool = false # Not presently working
var primary_controller_emulate_mouse_movement : bool = false # Not presently working
var secondary_controller_emulate_mouse_movement : bool = false # Not presently working
var emulated_mouse_sensitivity_multiplier : int = 10
var emulated_mouse_deadzone : float = 0.25

# Roomscale movement configs
var use_roomscale : bool = false
var roomscale_height_adjustment : float = 0.0
var attempt_to_use_camera_to_set_roomscale_height : bool = false
var reverse_roomscale_direction : bool = false
var use_roomscale_controller_directed_movement : bool = false
var use_roomscale_3d_cursor : bool = false
var use_long_range_3d_cursor : bool = false
var roomscale_3d_cursor_distance_from_camera : float = 2.0
var roomscale_long_range_3d_cursor_distance_from_camera : float = 20.0
var use_arm_swing_jump : bool = false
var use_jog_movement : bool = false
var jog_triggers_sprint : bool = false

# Radial menu configs
var use_xr_radial_menu : bool = false
enum XR_RADIAL_TYPE {
	GAMEPAD = 0,
	KEYBOARD = 1,
	ACTION = 2
}
var xr_radial_menu_mode : XR_RADIAL_TYPE = XR_RADIAL_TYPE.GAMEPAD
var xr_radial_menu_entries : Array = ["Joypad Y/Triangle", "Joypad B/Circle", "Joypad A/Cross", "Joypad X/Square"]
var open_radial_menu_button : String = "by_button"

# Decacis Stick Turning Variables
enum TurningType {
	SNAP = 0,
	SMOOTH = 1,
	NONE = 2
}

var turning_type : TurningType = TurningType.SNAP
var turning_speed : float = 90.0
var turning_degrees : float = 30.0
var stick_turn_controller : String = "primary_controller"

# Variables for XR Vignette in CONTROLS options
var use_motion_sickness_vignette : bool = false

# Variables for moving viewport2din3d nodes - they start as childed to the origin and then moved as necessary
enum XR_VIEWPORT_LOCATION {
	CAMERA = 0,
	PRIMARY_CONTROLLER = 1,
	SECONDARY_CONTROLLER = 2
}
var xr_main_viewport_location : XR_VIEWPORT_LOCATION = XR_VIEWPORT_LOCATION.CAMERA
var xr_secondary_viewport_location : XR_VIEWPORT_LOCATION = XR_VIEWPORT_LOCATION.CAMERA
var xr_standard_viewport_size : Vector2i = Vector2i(1920, 1080)
var primary_viewport_size_multiplier : float = 1.0
var secondary_viewport_size_multiplier : float = 1.0

# Variable for grip deadzone
var grip_deadzone : float = 0.7

# Variables in configs but not implemented yet
# Game options config
var camera_offset : Vector3 = Vector3(0,0,0)
var primary_viewport_offset : Vector3 = Vector3(0,0,0)
var secondary_viewport_offset : Vector3 = Vector3(0,0,0)
var autosave_action_map_duration_in_secs : int = 0

# Experimental variables only - not for final mod - use to test reparenting nodes to VR controllers
var use_vostok_gun_finding_code : bool = false
var use_beton_gun_finding_code : bool = false
var use_tar_object_picker_finding_code : bool = false
var use_CRUEL_gun_finding_code : bool = false
var currentRID = null

func _ready() -> void:
	set_process(false)
	# Turn off FSR
	currentRID = get_tree().get_root().get_viewport_rid()
	RenderingServer.viewport_set_scaling_3d_mode(currentRID, RenderingServer.VIEWPORT_SCALING_3D_MODE_BILINEAR)
	
	# Set relevant node signals
	xr_start.connect("xr_started", Callable(self, "_on_xr_started"))
	xr_autosave_timer.connect("timeout", Callable(self, "_on_xr_autosave_timer_timeout"))
	xr_physical_movement_controller.connect("tree_exiting", Callable(self, "_on_xr_origin_exiting_tree"))
	xr_radial_menu.connect("entry_selected", Callable(self, "_on_xr_radial_menu_entry_selected"))
	xr_config_handler.connect("xr_game_options_cfg_loaded", Callable(self, "_on_xr_config_handler_xr_game_options_cfg_loaded"))
	xr_config_handler.connect("xr_game_control_map_cfg_loaded", Callable(self, "_on_xr_config_handler_xr_game_control_map_cfg_loaded"))
	xr_config_handler.connect("xr_game_action_map_cfg_loaded", Callable(self, "_on_xr_config_handler_xr_game_action_map_cfg_loaded"))
	xr_config_handler.connect("xr_game_options_cfg_saved", Callable(self, "_on_xr_config_handler_xr_game_options_cfg_saved"))
	xr_config_handler.connect("xr_game_control_map_cfg_saved", Callable(self, "_on_xr_config_handler_xr_game_control_map_cfg_saved"))
	xr_config_handler.connect("xr_game_action_map_cfg_saved", Callable(self, "_on_xr_config_handler_xr_game_action_map_cfg_saved"))
	xr_gui_menu.connect("setting_changed", Callable(self, "_on_xr_gui_setting_changed"))
	
	# Set up unshaded material for pointers and cursor3D objects
	unshaded_material.disable_ambient_light = true
	unshaded_material.disable_receive_shadows = true
	unshaded_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	unshaded_material.no_depth_test = true
	unshaded_material.render_priority = 2
	
	# Set up cursor3D
	cursor_3d_sphere.radius = 0.01
	cursor_3d_sphere.height = 2 * cursor_3d_sphere.radius
	cursor_3d.mesh = cursor_3d_sphere
	cursor_3d.material_override = unshaded_material
	cursor_3d.visible = false
	cursor_3d.name = "Cursor3D"
	
	# Set up long range cursor3D
	long_range_cursor_3d_sphere.radius = 0.1
	long_range_cursor_3d_sphere.height = 2 * cursor_3d_sphere.radius
	long_range_cursor_3d.mesh = cursor_3d_sphere
	long_range_cursor_3d.material_override = unshaded_material
	long_range_cursor_3d.visible = false
	long_range_cursor_3d.name = "LongRangeCursor3D"
	
	# Set up pointer materials with unshaded material
	xr_pointer.laser_material = unshaded_material
	xr_pointer.laser_hit_material = unshaded_material
	xr_pointer.target_material = unshaded_material
	
	# Set up reparenting node
	xr_reparenting_node.set_as_top_level(true)
	
	# Set up XR hand materials
	xr_left_hand.hand_material_override = xr_hand_material
	xr_right_hand.hand_material_override = xr_hand_material

func _process(_delta : float) -> void:
	# Experimental for time being, later will have handle_node_reparenting function here and any function to assign node passing its value to it
	if use_vostok_gun_finding_code:
		_set_vostok_gun(_delta)
	
	if use_beton_gun_finding_code:
		_set_beton_gun(_delta)
		
	if use_tar_object_picker_finding_code:
		_set_tar_object_picker(_delta)
	
	if use_CRUEL_gun_finding_code:
		_set_CRUEL_gun(_delta)
	
	# Trigger method to find active camera and parent XR scene to it at regular intervals
	if Engine.get_process_frames() % 90 == 0:
		if !is_instance_valid(xr_origin_3d):
			_setup_new_xr_origin(backup_xr_origin)
		
		if is_instance_valid(xr_origin_3d) and is_instance_valid(xr_camera_3d):
			_eval_tree()
	
	# If controllers aren't found, skip processing inputs
	if !is_instance_valid(xr_left_controller) or !is_instance_valid(xr_right_controller) or use_physical_gamepad_only:
		return
	# Process emulated joypad inputs
	if !ugvr_menu_showing:
		process_joystick_inputs()


# Constantly checks for current camera 3D, canvaslayers, world environment and roomscale body (if roomscale enabled)
func _eval_tree() -> void:
	# Check to make sure main viewport still uses xr; use target_xr_viewport instead of get_viewport directly to account for when roomscale xr origin is reparented under a subviewport in the flat screen game (e.g., retro FPS shooters)
	if not is_instance_valid(target_xr_viewport):
		target_xr_viewport = get_viewport()
	
	target_xr_viewport.use_xr = true
	
	# Turn off FSR
	get_tree().root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	get_tree().root.scaling_3d_scale = 1.0
	
	# Ensure Vsync stays OFF!
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# Try automatically overwriting game options to set max FPS at 144 to avoid hard caps at low frame rate
	Engine.set_max_fps(120)
	
	# Get active camera3D by looking for an array of Camera3D nodes in the scene tree
	find_and_set_active_camera_3d()
	
	# Find canvas layer and display it
	# Setting the viewport size with user configs can fix if the layer displays too small or too large
	find_and_set_canvas_layers()
	
	# Find active world environment node, if any
	var active_world_environment = find_active_world_environment_or_null()
	
	# If active world environment found, and it has camera attributes, set any blurring to false, as blurring looks bad in VR
	if active_world_environment:
		# Turn off ssao,ssil, and ssr which are performance hogs
		if active_world_environment.environment.ssil_enabled == true:
			active_world_environment.environment.ssil_enabled = false
		if active_world_environment.environment.ssao_enabled == true:
			active_world_environment.environment.ssao_enabled = false
		if active_world_environment.environment.ssr_enabled == true:
			active_world_environment.environment.ssr_enabled = false
		
		if active_world_environment.camera_attributes != null:
			active_world_environment.camera_attributes.dof_blur_near_enabled = false
			active_world_environment.camera_attributes.dof_blur_far_enabled = false
				
		# NOT PRESENTLY WORKING, NEEDS MORE THOUGHT: if user enabled passthrough mode, try to enable it by finding world environment and setting sky to passthrough color
		if experimental_passthrough and xr_interface.is_passthrough_supported():
			var passthrough_color = Color(0,0,0,0.2)
			print("trying passthrough setup")
			var environment : Environment = active_world_environment.get_environment()
			environment.set_bg_color(passthrough_color)
			environment.set_background(Environment.BG_COLOR)
		
			experimental_passthrough = xr_interface.start_passthrough()
	
	# Set XR camera 3d attributes to also disable any blurring in case this helps override any flat screen settings
	xr_camera_3d.attributes.dof_blur_near_enabled = false
	xr_camera_3d.attributes.dof_blur_far_enabled = false
	
	# If using roomscale, find current characterbody parent of camera, if any, then send to roomscale controller and enable it
	if !is_instance_valid(current_roomscale_character_body) and use_roomscale == true:
		current_roomscale_character_body = find_and_set_player_characterbody3d_or_null()
		
		# If we now found a roomscale body, reparent xr origin 3D to character body
		if is_instance_valid(current_roomscale_character_body) and xr_origin_reparented == false:
			current_camera_remote_transform.remote_path = ""
			remove_child(xr_origin_3d)
			current_roomscale_character_body.add_child(xr_origin_3d)
			xr_origin_3d.transform.origin.y = 0.0
			xr_roomscale_controller.set_characterbody3D(current_roomscale_character_body)
			if attempt_to_use_camera_to_set_roomscale_height:
				@warning_ignore("unused_variable")
				var err = xr_roomscale_controller.set_enabled(true, xr_origin_3d, reverse_roomscale_direction, current_camera, primary_controller, use_roomscale_controller_directed_movement, roomscale_height_adjustment)
			else:
				@warning_ignore("unused_variable")
				var err = xr_roomscale_controller.set_enabled(true, xr_origin_3d, reverse_roomscale_direction, null, primary_controller, use_roomscale_controller_directed_movement, roomscale_height_adjustment)
			@warning_ignore("unused_variable")
			var err2 = xr_roomscale_controller.recenter()
			current_camera = null
			current_camera_remote_transform = null
			xr_origin_reparented = true
			target_xr_viewport.use_xr = false
			target_xr_viewport = xr_origin_3d.get_viewport()
			
# Function to set up VR Controllers to emulate gamepad
func map_xr_controllers_to_action_map() -> bool:
	print("mapping controls")
	
	if primary_controller_selection.to_lower() == "right":
		primary_controller = xr_right_controller
		primary_detection_area = right_gesture_detection_area
		secondary_controller = xr_left_controller
		secondary_detection_area = left_gesture_detection_area
	elif primary_controller_selection.to_lower() == "left":
		primary_controller = xr_left_controller
		primary_detection_area = left_gesture_detection_area
		secondary_controller = xr_right_controller
		secondary_detection_area = right_gesture_detection_area
	else:
		print("Error: primary_controller_selection in control config file is neither set to right nor left, defaulting to right.")
		primary_controller = xr_right_controller
		primary_detection_area = right_gesture_detection_area
		secondary_controller = xr_left_controller
		secondary_detection_area = left_gesture_detection_area
	
	print("secondary controller: ", secondary_controller)
	print("primary controller: ", primary_controller)
	
	# Print action map for debugging - facilitate user remapping of actions as alternative to general keybinds
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
	if stick_turn_controller.to_lower() == "primary_controller":
		primary_controller.connect("input_vector2_changed", Callable(self, "primary_stick_moved"))
	else:
		print("Using secondary controller for stick turn based on user config.")
		secondary_controller.connect("input_vector2_changed", Callable(self, "secondary_stick_moved"))
	
	# Map xr button input to joypad inputs
	print("Primary action map: ", primary_action_map)
	if primary_action_map == null:
		primary_action_map = {
		"grip_click":JOY_BUTTON_RIGHT_SHOULDER,
		"primary_click":JOY_BUTTON_RIGHT_STICK,
		"ax_button":JOY_BUTTON_A,
		"by_button":JOY_BUTTON_X
		}
	print("Secondary action map: ", secondary_action_map)
	if secondary_action_map == null:
		secondary_action_map = {
		"grip_click":JOY_BUTTON_LEFT_SHOULDER,
		"primary_click":JOY_BUTTON_LEFT_STICK,
		"ax_button":JOY_BUTTON_B,
		"by_button":JOY_BUTTON_Y
		}
	
	# Map xr controller joysticks to gamepad joysticks
	secondary_x_axis.axis = JOY_AXIS_LEFT_X
	secondary_y_axis.axis = JOY_AXIS_LEFT_Y
	primary_x_axis.axis = JOY_AXIS_RIGHT_X
	primary_y_axis.axis = JOY_AXIS_RIGHT_Y
	
	# Create gamepad dpad inputs for emulation
	dpad_up.button_index = JOY_BUTTON_DPAD_UP
	dpad_down.button_index = JOY_BUTTON_DPAD_DOWN
	dpad_left.button_index = JOY_BUTTON_DPAD_LEFT
	dpad_right.button_index = JOY_BUTTON_DPAD_RIGHT
	
	
	# Return true to alert that function is completed
	return true
	
# Handle button presses on VR controller assigned as primary
func handle_primary_xr_inputs(button):
	#print("primary contoller button pressed: ", button)
	
	# Toggle pointers if user holds primary hand over their head and presses toggle button
	if button == pointer_gesture_toggle_button and gesture_area.overlaps_area(primary_detection_area):
		xr_pointer.set_enabled(!xr_pointer.enabled)
		toggle_xr_gui_menu()
	
	# (Temporary) Set user height if user presses designated button while doing gesture
	if button == gesture_set_user_height_button and gesture_area.overlaps_area(primary_detection_area):
		print("Now resetting user height")
		user_height = xr_camera_3d.transform.origin.y
		print("User height: ", user_height)
		apply_user_height(user_height)
	
	# Temporary : Try toggling active camera for xr camera to follow manually	
	if button == gesture_toggle_active_camera_button and gesture_area.overlaps_area(primary_detection_area):
		print("Now manually toggling active camera")
		manually_set_camera = true
		# Get all cameras we have found
		var active_cameras = get_tree().get_nodes_in_group("possible_xr_cameras")
		# If current index is too high wrap back around to 0
		#if manual_set_possible_xr_cameras_idx > (active_cameras.size()-1):
			#manual_set_possible_xr_cameras_idx = 0
		if manual_set_possible_xr_cameras_idx <= 0:
			manual_set_possible_xr_cameras_idx = active_cameras.size()-1
		var selected_camera = active_cameras[manual_set_possible_xr_cameras_idx]
		# Assuming camera still exists, use it
		if is_instance_valid(selected_camera):
			set_camera_as_current(selected_camera)
		# Increase index for next time button is pressed
		manual_set_possible_xr_cameras_idx -=1
	
	# Block other inputs if ugvr menu is up to prevent game actions while using ugvr menu
	if ugvr_menu_showing:
		return
	# If user just pressed activation button, activate special combo buttons
	if button == dpad_activation_button:
		dpad_toggle_active = true
		start_toggle_active = true
		select_toggle_active = true
		#print("dpad toggle active")
		
	# Finally pass through remaining gamepad emulation input
	if primary_action_map.has(button):
		var event = InputEventJoypadButton.new()
		event.button_index = primary_action_map[button]
		event.pressed = true
		Input.parse_input_event(event)
	
	
# Handle release of buttons on primary controller
func handle_primary_xr_release(button):
	# Block other inputs if ugvr menu is up to prevent game actions while using ugvr menu
	if ugvr_menu_showing:
		return
	
	#print("primary button released: ", button)
	if button == dpad_activation_button:
		dpad_toggle_active = false
		start_toggle_active = false
		select_toggle_active = false
		#print("dpad toggle off")
	
	if primary_action_map.has(button):
		var event = InputEventJoypadButton.new()
		event.button_index = primary_action_map[button]
		event.pressed = false
		Input.parse_input_event(event)
		

# Handle button presses on VR Controller assigned as secondary
func handle_secondary_xr_inputs(button):
	#print("secondary button pressed: ", button)

	# If pressing pointer activation button and making gesture, toggle UGVR menu - next step make this the chord defined in UGVR config option
	if button == pointer_gesture_toggle_button and gesture_area.overlaps_area(secondary_detection_area):
		# Hold for future use - Insert code here to make new UGVR menu or scene pop up
		if ugvr_menu_showing:
			xr_pointer.collision_mask = 4194304 # layer 23 - layer ugvr menu is now on
		else:
			xr_pointer.collision_mask = 1048576 #  layer 21 - layer the other two viewports are now on

	# If button is assigned to load action map (temporary,this should be a GUI option) and making gesture, load action map
	if button == gesture_load_action_map_button and gesture_area.overlaps_area(secondary_detection_area):
		xr_config_handler.load_action_map_file(xr_config_handler.game_action_map_cfg_path)
		if use_arm_swing_jump:
			xr_physical_movement_controller.detect_game_jump_action_events()
		if use_jog_movement:
			xr_physical_movement_controller.detect_game_sprint_events()

		# Print scene tree to game log for modding / debug purposes - this is better than doing it constantly, and makes sense since this button combo will only be used intentionally
		get_tree().current_scene.print_tree_pretty()

	
	# Block other inputs if ugvr menu is up to prevent game actions while using ugvr menu
	if ugvr_menu_showing:
		return
		
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
	# Block other inputs if ugvr menu is up to prevent game actions while using ugvr menu
	if ugvr_menu_showing:
		return
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
	# Block other inputs if ugvr menu is up to prevent game actions while using ugvr menu
	if ugvr_menu_showing:
		return
	#print(button)
	#print(value)
	if button == "trigger":
		var event = InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_TRIGGER_RIGHT
		event.axis_value = value
		Input.parse_input_event(event)
		
	if button == "grip":
		var event = InputEventJoypadButton.new()
		event.button_index = primary_action_map["grip_click"]
		if value >= grip_deadzone:
			event.pressed = true
		else:
			event.pressed=false
		Input.parse_input_event(event)

# Handle analogue button presses on VR Controller assigned as secondary	 	
func handle_secondary_xr_float(button, value):
	# Block other inputs if ugvr menu is up to prevent game actions while using ugvr menu
	if ugvr_menu_showing:
		return
	#print(button)
	#print(value)
	if button == "trigger":
		var event = InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_TRIGGER_LEFT
		event.axis_value = value
		Input.parse_input_event(event)
		
	if button == "grip":
		var event = InputEventJoypadButton.new()
		event.button_index = secondary_action_map["grip_click"]
		if value >= grip_deadzone:
			event.pressed = true
		else:
			event.pressed=false
		Input.parse_input_event(event)

# Always process joystick analogue inputs
func process_joystick_inputs():
	# For some reason xr y input values are reversed, so we have to negate those
	# Likely have to include option to turn off x axis handling for primary if stick turning used
	
	secondary_x_axis.axis_value = secondary_controller.get_vector2("primary").x
	secondary_y_axis.axis_value = -secondary_controller.get_vector2("primary").y
	
	primary_x_axis.axis_value = primary_controller.get_vector2("primary").x
	primary_y_axis.axis_value = -primary_controller.get_vector2("primary").y
	
	# If dpad toggle button is active, then send joystick inputs to dpad instead
	if dpad_toggle_active:
		if secondary_x_axis.axis_value < -0.5:
			dpad_left.pressed = true
			Input.parse_input_event(dpad_left)
		else:
			dpad_left.pressed = false
			Input.parse_input_event(dpad_left)
			
			
		if secondary_x_axis.axis_value >= 0.5:
			dpad_right.pressed = true
			Input.parse_input_event(dpad_right)
		else:
			dpad_right.pressed = false
			Input.parse_input_event(dpad_right)
			
			
		if secondary_y_axis.axis_value < -0.5:
			dpad_up.pressed = true
			Input.parse_input_event(dpad_up)
		else:
			dpad_up.pressed = false
			Input.parse_input_event(dpad_up)
			
		if secondary_y_axis.axis_value >= 0.5:
			dpad_down.pressed = true
			Input.parse_input_event(dpad_down)
		else:
			dpad_down.pressed = false
			Input.parse_input_event(dpad_down)
	
	# Otherwise process joystick like normal		
	else:
		Input.parse_input_event(secondary_x_axis)
		Input.parse_input_event(secondary_y_axis)
		if not stick_emulate_mouse_movement:
			Input.parse_input_event(primary_x_axis)
			Input.parse_input_event(primary_y_axis)

	# Allow emulation of mouse with primary (default: right) stick
	if stick_emulate_mouse_movement and (abs(primary_x_axis.axis_value) > emulated_mouse_deadzone or abs(primary_y_axis.axis_value) > emulated_mouse_deadzone):
		var mouse_move = InputEventMouseMotion.new()
		mouse_move.relative = Vector2(primary_x_axis.axis_value, primary_y_axis.axis_value) * emulated_mouse_sensitivity_multiplier
		Input.parse_input_event(mouse_move)

# ------------------------Decacis Smooth / Stick turning code ----------------------------------------------------------

# Option to use secondary stick if user config - off by default
func secondary_stick_moved(stick_name : String, value : Vector2) -> void:
	# If turning type is none, do not process stick turn movement
	if not turning_type == TurningType.NONE:
		_stick_handler(secondary_controller, stick_name, value)

# User primary controller thumbstick for stick turn (default)			
func primary_stick_moved(stick_name : String, value : Vector2) -> void:
	# If turning type is none, do not process stick turn movement
	if not turning_type == TurningType.NONE:
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
# ---------------------END OF DECASIS STICK TURNING CODE -----------------------------------------------

# Handle reparenting game elements
# Reparented node is the node passed to the function to be attached to the primary controller, use rotate if the model has z going the wrong direction, use target offset to better place the object in the XR hand
func handle_node_reparenting(delta : float, reparented_node : Node3D, rotate_reparented_node_180_degrees : bool, target_offset: Vector3 = Vector3(0,0,0)):

	if not is_instance_valid(primary_controller) or not is_instance_valid(secondary_controller):
		return
	
	if xr_reparenting_active and is_instance_valid(reparented_node):
	
		reparented_node.set_as_top_level(true)
	
		if secondary_controller.is_button_pressed("grip"):
			if (secondary_controller.global_transform.origin - primary_controller.global_transform.origin).length() <= 0.35:
				xr_two_handed_aim = true
			else:
				xr_two_handed_aim = false
		else:
			xr_two_handed_aim = false
	
		if xr_two_handed_aim == true:
			xr_reparenting_node.global_transform.origin = primary_controller.global_transform.origin
			var dir = (primary_controller.global_position - secondary_controller.global_position).normalized()
			if rotate_reparented_node_180_degrees:
				dir = (secondary_controller.global_position - primary_controller.global_position).normalized()
			xr_reparenting_node.global_transform.basis = xr_reparenting_node.global_transform.basis.looking_at(dir, Vector3.UP, true)
		else:
			xr_reparenting_node.global_transform = primary_controller.global_transform
			
		if rotate_reparented_node_180_degrees and not xr_two_handed_aim:
			xr_reparenting_node_holder.rotation_degrees = Vector3(0,180,0)
		else:
			xr_reparenting_node_holder.rotation_degrees = Vector3(0,0,0)

		xr_reparenting_node_holder.transform.origin = target_offset
		handle_reparented_node_smoothing(delta, xr_reparenting_node_holder, reparented_node, rotate_reparented_node_180_degrees)

# Try to smooth movement of reparented node to minimize jitter
func handle_reparented_node_smoothing(delta : float, source_node : Node3D, destination_node : Node3D, rotate_reparented_node_180_degrees : bool):
	if is_instance_valid(source_node) and is_instance_valid(destination_node):

		# Set lerp speed to current FPS
		var attach_lerp_speed : float = float(Performance.get_monitor(Performance.TIME_FPS))
		var lerp_speed = attach_lerp_speed * delta
		# Get target rotation and position from source node
		var new_pose_rotation = source_node.global_transform.basis.get_rotation_quaternion()
		var new_position = source_node.global_transform.origin
		# Get current destination node rotation and position
		var last_pose_rotation = destination_node.global_transform.basis.get_rotation_quaternion()
		var last_position = destination_node.global_transform.origin

		# Get dot product of destination node's rotation and source node's rotation
		# If the dot product is close to 1, it means the orientations are very similar, while if it's closer to -1, they are nearly opposite.
		var spherical_distance = new_pose_rotation.dot(last_pose_rotation)

		if (spherical_distance  < 0.0):
			spherical_distance = -spherical_distance

		# Get distance between source and destination node and scale smoothing to distance
		var lenr = maxf(1.0, (new_position - last_position).length())
		
		# Lerp destination node's rotation and postion to source node's values, scaled by amount of difference between the two
		# For some reason this does not work when we have to rotate the object by 180 degrees, so disabling for now in that circumstance
		if rotate_reparented_node_180_degrees:
			last_pose_rotation = source_node.global_transform.basis
		else:	
			last_pose_rotation = Basis(last_pose_rotation.slerp(new_pose_rotation, lerp_speed * spherical_distance))
		last_position = last_position.lerp(new_position, minf(1.0, lerp_speed * lenr))
		destination_node.global_transform.basis = last_pose_rotation
		destination_node.global_transform.origin = last_position

# Handle initiation of xr
func _on_xr_started():
	# Turn off FSR
	currentRID = get_tree().get_root().get_viewport_rid()
	RenderingServer.viewport_set_scaling_3d_mode(currentRID, RenderingServer.VIEWPORT_SCALING_3D_MODE_BILINEAR)
	get_tree().root.scaling_3d_scale = 1.0
	# Only set up once not every time user goes in and out of VR
	if already_set_up:
		return
	
	# Once set up, don't do it again during session
	already_set_up = true
	
	# Print final viewport and window of xr camera
	print("XR Camera's viewport is: ", xr_camera_3d.get_viewport())
	print("XR Camera's window is: ", xr_camera_3d.get_window()) 
	
	# Load config files; if not using XR then do not use XR config files
	var loaded : bool = false
	loaded = xr_config_handler.load_game_control_map_cfg_file(xr_config_handler.game_control_map_cfg_path)
	loaded = xr_config_handler.load_game_options_cfg_file(xr_config_handler.game_options_cfg_path)
	loaded = xr_config_handler.load_action_map_file(xr_config_handler.game_action_map_cfg_path)
	
	# Set Viewport sizes and locations for GUI
	setup_viewports()
	
	# Set XR hands
	set_xr_hands()
	
	# Print key XR stats to log for debugging purposes
	var screen_resolution = XRServer.primary_interface.get_render_target_size()
	print("Screen resolution from XRServer.primary_interface render target size: ", screen_resolution)
	var screen_aspect : float = float(screen_resolution.x) / float(screen_resolution.y)
	print("XR Projection left: ", XRServer.primary_interface.get_projection_for_view(0, screen_aspect, 0.1, 100) )
	print("XR Projection right: ", XRServer.primary_interface.get_projection_for_view(1, screen_aspect, 0.1, 100) )
	
	set_process(true)

# When autosave timer expires, save game action map to capture changes user may have made in-game remapping menu	
func _on_xr_autosave_timer_timeout():
	xr_config_handler.save_action_map_cfg_file(xr_config_handler.game_action_map_cfg_path)

# Used when user performs gesture (or later, presses GUI button) to set height. Tradeoff is that will be camera dependent.
func apply_user_height(height: float):
	print("Changing all available camera remote transforms to reflect user height")
	var cameras_available = get_tree().get_nodes_in_group("possible_xr_cameras")
	for camera in cameras_available:
		var remote_transform = camera.find_child("*XRRemoteTransform*",false,false)
		if remote_transform:
			remote_transform.transform.origin.y = 0.0
			remote_transform.transform.origin.y -= (height * xr_world_scale)
	
	# XR Origin-only approach, use if there's no active camera 3D in the scene
	if current_camera_remote_transform == null:
		print("No current remote transform. Changing xr origin height")
		xr_origin_3d.transform.origin.y = 0.0
		xr_origin_3d.transform.origin.y -= (height * xr_world_scale)
		print("xr origin 3d new height: ", xr_origin_3d.transform.origin.y)
		

# Called to try to catch xr origin before it gets deleted from tree in roomscale mode
func _on_xr_origin_exiting_tree():
	if use_roomscale and is_instance_valid(current_roomscale_character_body) and xr_origin_reparented:
		print("Calling xr origin exiting scene function")
		
		# XR hands seem to have an issue persisting through the duplication process, so handle them separately
		if is_instance_valid(xr_left_hand):
			xr_left_controller.remove_child(xr_left_hand)
			xr_left_hand.queue_free()
		if is_instance_valid(xr_right_hand):
			xr_right_controller.remove_child(xr_right_hand)
			xr_right_hand.queue_free()

		#print(xr_origin_3d)
		#print(xr_origin_3d.get_parent())
		current_roomscale_character_body.remove_child(xr_origin_3d)
		add_child(xr_origin_3d)
		#print(xr_origin_3d)
		#print(xr_origin_3d.get_parent())
		if attempt_to_use_camera_to_set_roomscale_height:
			@warning_ignore("unused_variable")
			var err = xr_roomscale_controller.set_enabled(false, null, reverse_roomscale_direction, current_camera, primary_controller, use_roomscale_controller_directed_movement, roomscale_height_adjustment)
		else:
			@warning_ignore("unused_variable")
			var err = xr_roomscale_controller.set_enabled(false, null, reverse_roomscale_direction, null, primary_controller, use_roomscale_controller_directed_movement, roomscale_height_adjustment)
		xr_roomscale_controller.set_characterbody3D(null)
		xr_origin_reparented = false
		backup_xr_origin = xr_origin_3d.duplicate()
		target_xr_viewport = get_viewport()

func _setup_new_xr_origin(new_origin : XROrigin3D):
	# Turn off FSR
	get_tree().root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	get_tree().root.scaling_3d_scale = 1.0
	
	add_child(new_origin)
	xr_origin_3d = new_origin
	xr_origin_3d.current = true
	xr_start = xr_origin_3d.get_node("StartXR")
	xr_camera_3d = xr_origin_3d.get_node("XRCamera3D")
	xr_left_controller = xr_origin_3d.get_node("XRController3D")
	xr_right_controller = xr_origin_3d.get_node("XRController3D2")
	gesture_area = xr_camera_3d.get_node("GestureArea")
	left_gesture_detection_area = xr_left_controller.get_node("GestureDetectionArea")
	right_gesture_detection_area = xr_right_controller.get_node("GestureDetectionArea")
	xr_pointer = xr_origin_3d.get_node("XRPointer")
	welcome_label_3d = xr_camera_3d.get_node("WelcomeLabel3D")
	xr_roomscale_controller = xr_origin_3d.get_node("XRRoomscaleController")
	xr_physical_movement_controller = xr_origin_3d.get_node("XRPhysicalMovementController")
	xr_radial_menu = get_node("XRRadialMenu")
	xr_black_out = xr_camera_3d.get_node("BlackOut")
	xr_vignette = xr_camera_3d.get_node("Vignette")
	
	# Set XR worldscale
	xr_origin_3d.world_scale = xr_world_scale
	
	# Setup vignette with new origin
	xr_vignette.set_enabled(use_motion_sickness_vignette)
	
	# Reset controls
	var finished = map_xr_controllers_to_action_map()
	
	# Look for viewports at their proper location, else registers as null if reparented
	if xr_main_viewport_location == XR_VIEWPORT_LOCATION.CAMERA:
		xr_main_viewport2d_in_3d = xr_camera_3d.get_node("XRMainViewport2Din3D")
	elif xr_main_viewport_location == XR_VIEWPORT_LOCATION.PRIMARY_CONTROLLER:
		xr_main_viewport2d_in_3d = primary_controller.get_node("XRViewportHolder").get_node("XRMainViewport2Din3D")
	elif xr_main_viewport_location == XR_VIEWPORT_LOCATION.SECONDARY_CONTROLLER:
		xr_main_viewport2d_in_3d = secondary_controller.get_node("XRViewportHolder").get_node("XRMainViewport2Din3D")
	xr_main_viewport2d_in_3d_subviewport = xr_main_viewport2d_in_3d.get_node("Viewport")
	
	if xr_secondary_viewport_location == XR_VIEWPORT_LOCATION.CAMERA:
		xr_secondary_viewport2d_in_3d = xr_camera_3d.get_node("XRSecondaryViewport2Din3D")
	elif xr_secondary_viewport_location == XR_VIEWPORT_LOCATION.PRIMARY_CONTROLLER:
		xr_secondary_viewport2d_in_3d = primary_controller.get_node("XRViewportHolder").get_node("XRSecondaryViewport2Din3D")
	elif xr_secondary_viewport_location == XR_VIEWPORT_LOCATION.SECONDARY_CONTROLLER:
		xr_secondary_viewport2d_in_3d = secondary_controller.get_node("XRViewportHolder").get_node("XRSecondaryViewport2Din3D")
	xr_secondary_viewport2d_in_3d_subviewport = xr_secondary_viewport2d_in_3d.get_node("Viewport")
	
	# Set up the rest of viewports
	setup_viewports()
	set_worldscale_for_xr_nodes(xr_world_scale)
	# Reset other nodes
	xr_physical_movement_controller.set_enabled(use_jog_movement, use_arm_swing_jump, primary_controller, secondary_controller, jog_triggers_sprint)
	xr_physical_movement_controller.connect("tree_exiting", Callable(self, "_on_xr_origin_exiting_tree"))
	xr_radial_menu.set_controller(primary_controller)
	
	xr_origin_reparented = false
	current_roomscale_character_body = null
	
	# Set up pointer materials with unshaded material
	xr_pointer.laser_material = unshaded_material
	xr_pointer.laser_hit_material = unshaded_material
	xr_pointer.target_material = unshaded_material
	
	# Set up XR Hands
	set_xr_hands()
	
	# Set controller for ugvr menu
	xr_gui_menu.set_xr_controller(primary_controller)
	
func setup_viewports():
	# Turn off FSR
	currentRID = get_tree().get_root().get_viewport_rid()
	RenderingServer.viewport_set_scaling_3d_mode(currentRID, RenderingServer.VIEWPORT_SCALING_3D_MODE_BILINEAR)
	
	if disable_2d_ui == false:
		print("Viewport world2d: ", get_viewport().world_2d)
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

	# Setup secondary viewport for use with canvaslayer node contents, if any found and set sizes of primary and secondary viewports
	xr_main_viewport2d_in_3d.set_viewport_size(xr_standard_viewport_size * primary_viewport_size_multiplier)
	xr_secondary_viewport2d_in_3d.set_viewport_size(xr_standard_viewport_size * secondary_viewport_size_multiplier)
	
# Used when setting viewport locations (camera, controllers)
func reparent_viewport(viewport_node, viewport_location):
	var viewport_parent = viewport_node.get_parent()
	
	# Check to see if node is already parented to the target parent, if so, nothing to do
	if viewport_location == XR_VIEWPORT_LOCATION.CAMERA and viewport_parent == xr_camera_3d:
		return
	elif viewport_location == XR_VIEWPORT_LOCATION.PRIMARY_CONTROLLER and viewport_parent.get_parent() == primary_controller:
		return
	elif viewport_location == XR_VIEWPORT_LOCATION.SECONDARY_CONTROLLER and viewport_parent.get_parent() == secondary_controller:
		return
	
	# If target is different than current parent, then reparent viewport
	viewport_parent.remove_child(viewport_node)
	
	if viewport_location == XR_VIEWPORT_LOCATION.CAMERA:
		viewport_node.set_screen_size(Vector2(3.0,2.0) * xr_world_scale)
		viewport_node.transform.origin = Vector3(0,0,0)
		xr_camera_3d.add_child(viewport_node)
		if viewport_node == xr_main_viewport2d_in_3d:
			viewport_node.transform.origin = Vector3(0,-0.3,-2.8) * xr_world_scale
		else:
			viewport_node.transform.origin = Vector3(0,-0.3,-3.2) * xr_world_scale
		
	elif viewport_location == XR_VIEWPORT_LOCATION.PRIMARY_CONTROLLER:
		viewport_node.set_screen_size(Vector2(0.5, 0.33) * xr_world_scale)
		viewport_node.transform.origin = Vector3(0,0,0)
		primary_controller.get_node("XRViewportHolder").add_child(viewport_node)
		viewport_node.transform.origin = Vector3(0,0,0)
		if viewport_node == xr_main_viewport2d_in_3d:
			viewport_node.transform.origin = Vector3(0,0.005,0) * xr_world_scale
	
	elif viewport_location == XR_VIEWPORT_LOCATION.SECONDARY_CONTROLLER:
		viewport_node.set_screen_size(Vector2(0.5, 0.33) * xr_world_scale)
		viewport_node.transform.origin = Vector3(0,0,0)
		secondary_controller.get_node("XRViewportHolder").add_child(viewport_node)
		viewport_node.transform.origin = Vector3(0,0,0)
		if viewport_node == xr_main_viewport2d_in_3d:
			viewport_node.transform.origin = Vector3(0,0.005,0) * xr_world_scale

# Function to setup radial menu
func setup_radial_menu():
	# Enable and set up radial menu if using it
	if use_xr_radial_menu:
		xr_radial_menu.set_enabled(true)
		xr_radial_menu.set_controller(primary_controller)
		xr_radial_menu.set_open_radial_menu_button(open_radial_menu_button)
		xr_radial_menu.set_menu_entries(xr_radial_menu_entries)
	else:
		xr_radial_menu.set_enabled(false)
		xr_radial_menu.set_controller(null)

# Handle selection of entries in XR Radial menu
func _on_xr_radial_menu_entry_selected(entry : String):
	if xr_radial_menu_mode == XR_RADIAL_TYPE.GAMEPAD:
		var gamepad_event : InputEventJoypadButton = InputEventJoypadButton.new()
		var gamepad_button_index = xr_config_handler.default_gamepad_button_names.find(entry)
		gamepad_event.button_index = gamepad_button_index
		gamepad_event.pressed = true
		Input.parse_input_event(gamepad_event)
		#print("Pressed gamepad event from radial menu: ", entry)
		await get_tree().create_timer(0.2).timeout
		gamepad_event.pressed = false
		Input.parse_input_event(gamepad_event)
	
	# Not presently working	because rest of code assumes entries are strings and keys only accept KEY int constants
	elif xr_radial_menu_mode == XR_RADIAL_TYPE.KEYBOARD:
		var keyboard_event : InputEventKey = InputEventKey.new()
		#keyboard_event.keycode = entry
		keyboard_event.pressed = true
		Input.parse_input_event(keyboard_event)
		#print("Pressed key from radial menu: ", str(entry))
		await get_tree().create_timer(0.2).timeout
		keyboard_event.pressed = false
		Input.parse_input_event(keyboard_event)
		
	elif xr_radial_menu_mode == XR_RADIAL_TYPE.ACTION:
		# Using parse input event with Action Events did not seem to work but this seems to
		Input.action_press(entry)
		#print("Pressed action from radial menu: ", entry)
		await get_tree().create_timer(0.2).timeout
		Input.action_release(entry)

# Function to set whether XR Hands are visible and the material
func set_xr_hands():
	# If hands are lost, bring them back, since they are just cosmetic anyway
	
	# First, if left hand or right hand are invalid, restore them
	if not is_instance_valid(xr_left_hand):
		xr_left_hand = null
		var xr_left_hand_scene = load("res://xr_injector/hands/scenes/lowpoly/left_hand_low.tscn")
		xr_left_hand = xr_left_hand_scene.instantiate()
		xr_left_controller.add_child(xr_left_hand)
	if not is_instance_valid(xr_right_hand):
		xr_right_hand = null
		var xr_right_hand_scene = load("res://xr_injector/hands/scenes/lowpoly/right_hand_low.tscn")
		xr_right_hand = xr_right_hand_scene.instantiate()
		xr_right_controller.add_child(xr_right_hand)
	
	# Second, check if hands somehow floated away (more than 1 relative game unit) unexpectedly
	# Using length_squared because per docs it is faster than Vector3.length()
	if (xr_left_hand.global_transform.origin - xr_left_controller.global_transform.origin).length_squared() > (1.0 * xr_world_scale):
		xr_left_hand.queue_free()
		xr_left_hand = null
		var xr_left_hand_scene = load("res://xr_injector/hands/scenes/lowpoly/left_hand_low.tscn")
		xr_left_hand = xr_left_hand_scene.instantiate()
		xr_left_controller.add_child(xr_left_hand)
	if (xr_right_hand.global_transform.origin - xr_right_controller.global_transform.origin).length_squared() > (1.0 * xr_world_scale):
		xr_right_hand.queue_free()
		xr_right_hand = null
		var xr_right_hand_scene = load("res://xr_injector/hands/scenes/lowpoly/right_hand_low.tscn")
		xr_right_hand = xr_right_hand_scene.instantiate()
		xr_right_controller.add_child(xr_right_hand)
	
	# Set xr hand model visibility
	if show_xr_hands:
		xr_left_hand.show()
		xr_right_hand.show()
	else:
		xr_left_hand.hide()
		xr_right_hand.hide()
	
	# Set xr hand material
	match xr_hand_material_choice:
		# Default - transparent hand
		0:
			xr_hand_material = load("res://xr_injector/hands/materials/labglove_transparent.tres")
		# Full blue glove
		1:
			xr_hand_material = load("res://xr_injector/hands/materials/labglove.tres")
		# Half glove dark skinned
		2:
			xr_hand_material = load("res://xr_injector/hands/materials/glove_african_green_camo.tres")
		# No glove light skinned
		3:
			xr_hand_material = load("res://xr_injector/hands/materials/caucasian_hand.tres")
		# No glove dark skinned
		4:
			xr_hand_material = load("res://xr_injector/hands/materials/african_hands.tres")
		# Full yellow glove
		5:
			xr_hand_material = load("res://xr_injector/hands/materials/cleaning_glove.tres") 
		# Ghost hand - half glove light skinned
		6:
			xr_hand_material = load("res://xr_injector/hands/materials/ghost_hand.tres")
		# Default to mostly tansparent if wrong or invalid value entered
		_:
			xr_hand_material = load("res://xr_injector/hands/materials/labglove_transparent.tres")
			
	xr_left_hand.hand_material_override = xr_hand_material
	xr_right_hand.hand_material_override = xr_hand_material
	
# Function used by eval_tree to find the camera3d that is presently active in the flatscreen game and use it to drive XR camera and cursor3D (if used)
func find_and_set_active_camera_3d():
	# Turn off FSR
	currentRID = get_tree().get_root().get_viewport_rid()
	RenderingServer.viewport_set_scaling_3d_mode(currentRID, RenderingServer.VIEWPORT_SCALING_3D_MODE_BILINEAR)
	
	# Set up variables used for cameras
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
				if xr_use_vehicle_mode:
					remote_t.update_rotation = true
				else:
					remote_t.update_rotation = false
				remote_t.update_scale = false
				remote_t.remote_path = ""
				camera.add_child(remote_t)
				# If user has already set height at some point in session, adjust height by same for any new cameras that enter scene later
				remote_t.transform.origin.y -= (user_height * xr_world_scale)
				# Add cursor mesh
				var cursor = cursor_3d.duplicate()
				camera.add_child(cursor)
				cursor.transform.origin.z = -roomscale_3d_cursor_distance_from_camera
				var long_range_cursor = long_range_cursor_3d.duplicate()
				camera.add_child(long_range_cursor)
				long_range_cursor.transform.origin.z = -roomscale_long_range_3d_cursor_distance_from_camera
				
			# Regardless of whether we have found it before, if it's not the current camera driving the xr camera in the scene, but it is the current 3d camera on the same viewport, activate it
			if camera != current_camera and camera.current == true and camera.get_viewport() == xr_camera_3d.get_viewport() and current_roomscale_character_body == null and not manually_set_camera:
				set_camera_as_current(camera)

	# Find the possible xr cameras for this iteration of the loop to use in subsequent calculations
	var available_cameras = get_tree().get_nodes_in_group("possible_xr_cameras")
	
	# If for some reason we haven't found a current camera after cycling through all cameras in scene, fall back to setting remote path of available cameras to xr_origin_3d
	if current_camera == null and current_roomscale_character_body == null and not manually_set_camera:
		
		for available_camera in available_cameras:
			var available_camera_remote_transform = available_camera.find_child("*XRRemoteTransform",false,false)
			available_camera_remote_transform.remote_path = xr_origin_3d.get_path()
			current_camera_remote_transform = available_camera_remote_transform
		# Set last camera as current camera to avoid running through this special loop every iteration
		if available_cameras != null and available_cameras.size() >= 1:
			current_camera = available_cameras[-1]
	
	# If using roomscale 3D cursor, make the cursor visible on the active camera (someday for performance should condense the get_tree().get_nodes_in_group("possible_xr_cameras") to only call it once and then use that variable for all the various checks		
	if use_roomscale_3d_cursor == true or use_long_range_3d_cursor == true:
		# If there's only one camera, assume it's our active camera and add the 3D cursor
		if available_cameras.size() == 1:
			if use_roomscale_3d_cursor == true:
				available_cameras[0].get_node("Cursor3D").visible = true
			if use_long_range_3d_cursor == true:
				available_cameras[0].get_node("LongRangeCursor3D").visible = true
		# Otherwise find the active camera
		else:
			for camera in available_cameras:
				if camera.current == true and camera.get_viewport() == xr_camera_3d.get_viewport():
					if use_roomscale_3d_cursor == true:
						camera.get_node("Cursor3D").visible = true
					if use_long_range_3d_cursor == true:
						camera.get_node("LongRangeCursor3D").visible = true
				else:
					camera.get_node("Cursor3D").visible = false
					camera.get_node("LongRangeCursor3D").visible = false
	
# Set current camera to follow, used by the find_and_set_active_camera_3d() function but can also be called independently, e.g., by a modder or developer, to manually set the active camera
func set_camera_as_current(camera : Camera3D):
	print("Setting a new current camera: ", camera)
	print("Camera's viewport is: ", camera.get_viewport())
	print("Camera's window is: ", camera.get_window())
	if is_instance_valid(current_camera_remote_transform):
		print("Clearing previous remote transform")
		current_camera_remote_transform.remote_path = ""
	current_camera_remote_transform = camera.find_child("*XRRemoteTransform*",false,false)
	print("Current camera remote transform: ", current_camera_remote_transform)
	current_camera_remote_transform.remote_path = xr_origin_3d.get_path()
	current_camera = camera
	# Try to turn off blur on all cameras by default
	if current_camera.attributes != null:
		current_camera.attributes.dof_blur_near_enabled = false
		current_camera.attributes.dof_blur_far_enabled = false
	# Set XR Camera properties to current flatscreen camera3d properties
	xr_camera_3d.cull_mask = current_camera.cull_mask
	xr_camera_3d.doppler_tracking = current_camera.doppler_tracking
	#xr_camera_3d.environment = current_camera.environment

# Function used to find canvas layers used in flatscreen game, which do not display in VR, and re-route their output to main viewport2din3d screen
func find_and_set_canvas_layers():
	var potential_canvas_layer_nodes : Array = get_node("/root").find_children("*", "CanvasLayer", true, false)
	#print("Potential canvas layer nodes: ", potential_canvas_layer_nodes)
	
	if potential_canvas_layer_nodes != []:
		
		for canvas_layer in potential_canvas_layer_nodes:
			if canvas_layer.visible == true and not canvas_layer.is_in_group("active_canvas_layers"):
				print("making canvas layer active: ", canvas_layer)
				canvas_layer.add_to_group("active_canvas_layers")
				canvas_layer.set_custom_viewport(xr_main_viewport2d_in_3d_subviewport)

# Tries to find the active world environment and return it, or returns null if cannot find
func find_active_world_environment_or_null():
	var world_environment = get_node("/root").find_child("*Environment*", true, false)
	# If found node is not actually the WorldEnvironment, check its children, and use the first one:
	if world_environment and not world_environment.is_class("WorldEnvironment"):
		world_environment = world_environment.find_children("*", "WorldEnvironment", true, false)[0]
	# If no node found or node is still not the WorldEnvironment, try running a search of lower case environment
	if world_environment == null or not world_environment.is_class("WorldEnvironment"):
		world_environment = get_node("/root").find_child("*environment*", true, false)
	# If we found the world environment, return it, else return null
	if world_environment and world_environment.is_class("WorldEnvironment"):
		return world_environment
	else:
		return null

# Attempts to find the characterbody3d used in the flatscreen game by various methods and return it, or null if none is found
func find_and_set_player_characterbody3d_or_null():
	# Turn off FSR
	currentRID = get_tree().get_root().get_viewport_rid()
	RenderingServer.viewport_set_scaling_3d_mode(currentRID, RenderingServer.VIEWPORT_SCALING_3D_MODE_BILINEAR)
	
	
	var potential_character_body_node = null
	# Only search for characterbody once we have a present camera in the scene driving the xr origin
	if is_instance_valid(current_camera):
		# First try non-recursive search for "typical" FPS setups
		print("Trying to find characterbody 3D for roomscale....")
		potential_character_body_node = current_camera.get_parent_node_3d()
		# if parent of active camera not a Characterbody3D continue search
		if is_instance_valid(potential_character_body_node):
			if !potential_character_body_node.is_class("CharacterBody3D"):
				print("parent of current camera is not CharacterBody3D, trying again")
				potential_character_body_node = potential_character_body_node.get_parent_node_3d()
				if is_instance_valid(potential_character_body_node) and !potential_character_body_node.is_class("CharacterBody3D"):
					print("parent of parent of current camera is not CharacterBody3D, ending simple search.")
					potential_character_body_node = null
					var potential_character_bodies : Array = get_node("/root").find_children("*", "CharacterBody3D", true, false)
					print("now checking all other character bodies")
					print(potential_character_bodies)
					if potential_character_bodies.size() == 1:
						print("Only one characterbody3d found, assuming it's our player.")
						return potential_character_bodies[0]
					elif potential_character_bodies.size() > 1:
						for body in potential_character_bodies:
							if body.is_ancestor_of(current_camera):
								print("Winning characterbody from recursive search found: ", body)
								return body
							elif body.name.to_lower().contains("player") or body.name.to_lower().contains("controller"):
								print("Winning characterbody from recursive search with name search found: ", body)
								return body
				# If we have a valid node, and it was a class character body, we have our characterbody3D
				elif is_instance_valid(potential_character_body_node):
					print("Character body found as parent of parent of current camera, sending to roomscale node: ", potential_character_body_node)
					return potential_character_body_node
				# If we don't have a valid node, then try recursive search
				else:
					var potential_character_bodies : Array = get_node("/root").find_children("*", "CharacterBody3D", true, false)
					print("now checking all other character bodies")
					print(potential_character_bodies)
					if potential_character_bodies.size() == 1:
						print("Only one characterbody3d found, assuming it's our player.")
						return potential_character_bodies[0]
					elif potential_character_bodies.size() > 1:
						for body in potential_character_bodies:
							if body.is_ancestor_of(current_camera):
								print("Winning characterbody from recursive search found: ", body)
								return body
							elif body.name.to_lower().contains("player") or body.name.to_lower().contains("controller"):
								print("Winning characterbody from recursive search with name search found: ", body)
								return body
			# If we have a valid node and it's a character body, we found our characterbody as a parent of the camera
			else:
				print("Character body found as parent to current camera, sending to roomscale node: ", potential_character_body_node)
				return potential_character_body_node
		# If camera does not have any parent node3d, just do recursive search
		else:
			var potential_character_bodies : Array = get_node("/root").find_children("*", "CharacterBody3D", true, false)
			print("now checking all other character bodies")
			print(potential_character_bodies)
			if potential_character_bodies.size() == 1:
				print("Only one characterbody3d found, assuming it's our player.")
				return potential_character_bodies[0]
			elif potential_character_bodies.size() > 1:
				for body in potential_character_bodies:
					if body.is_ancestor_of(current_camera):
						print("Winning characterbody from recursive search found: ", body)
						return body
					elif body.name.to_lower().contains("player") or body.name.to_lower().contains("controller"):
						print("Winning characterbody from recursive search with name search found: ", body)
						return body
	# If no body has been returned at the end of everything, return null instead
	return null

# Function to pull current state of config handler game options variables to set same xr scene variables based on user config
func set_xr_game_options():
	# Load camera options
	xr_world_scale = xr_config_handler.xr_world_scale
	camera_offset = xr_config_handler.camera_offset
	experimental_passthrough = xr_config_handler.experimental_passthrough
	xr_use_vehicle_mode = xr_config_handler.xr_use_vehicle_mode

	# Load viewport options
	xr_main_viewport_location = xr_config_handler.xr_main_viewport_location
	xr_secondary_viewport_location = xr_config_handler.xr_secondary_viewport_location
	primary_viewport_size_multiplier = xr_config_handler.primary_viewport_size_multiplier
	secondary_viewport_size_multiplier = xr_config_handler.secondary_viewport_size_multiplier
	primary_viewport_offset = xr_config_handler.primary_viewport_offset
	secondary_viewport_offset = xr_config_handler.secondary_viewport_offset

	# Load roomscale options
	use_roomscale = xr_config_handler.use_roomscale
	roomscale_height_adjustment = xr_config_handler.roomscale_height_adjustment
	attempt_to_use_camera_to_set_roomscale_height = xr_config_handler.attempt_to_use_camera_to_set_roomscale_height
	reverse_roomscale_direction = xr_config_handler.reverse_roomscale_direction
	use_roomscale_controller_directed_movement = xr_config_handler.use_roomscale_controller_directed_movement
	use_roomscale_3d_cursor = xr_config_handler.use_roomscale_3d_cursor
	use_long_range_3d_cursor = xr_config_handler.use_long_range_3d_cursor
	roomscale_3d_cursor_distance_from_camera = xr_config_handler.roomscale_3d_cursor_distance_from_camera
	roomscale_long_range_3d_cursor_distance_from_camera = xr_config_handler.roomscale_long_range_3d_cursor_distance_from_camera
	use_arm_swing_jump = xr_config_handler.use_arm_swing_jump
	use_jog_movement = xr_config_handler.use_jog_movement
	jog_triggers_sprint = xr_config_handler.jog_triggers_sprint
	
	# Load autosave options
	autosave_action_map_duration_in_secs = xr_config_handler.autosave_action_map_duration_in_secs
	
	# Load xr injector GUI options
	show_welcome_label = xr_config_handler.show_welcome_label
	
	# Load XR Hands options
	show_xr_hands = xr_config_handler.show_xr_hands
	xr_hand_material_choice = xr_config_handler.xr_hand_material_choice
	set_xr_hands()
	
	# Set XR worldscale based on config
	xr_origin_3d.world_scale = xr_world_scale
	set_worldscale_for_xr_nodes(xr_world_scale)
	
	# Place viewports at proper location based on user config
	reparent_viewport(xr_main_viewport2d_in_3d, xr_main_viewport_location)
	reparent_viewport(xr_secondary_viewport2d_in_3d, xr_secondary_viewport_location)
	
	# Enable arm swing jog or jump movement if enabled by the user
	xr_physical_movement_controller.set_enabled(use_jog_movement, use_arm_swing_jump, primary_controller, secondary_controller, jog_triggers_sprint)

	# Show or Clear Welcome label / Splash Screen
	if show_welcome_label and not welcome_label_already_shown:
		welcome_label_3d.show()
		await get_tree().create_timer(1.5).timeout
		var logo_audio_node = welcome_label_3d.get_node_or_null("logo_audio")
		if logo_audio_node != null:
			logo_audio_node.play()
		await get_tree().create_timer(9.0).timeout
		welcome_label_3d.hide()
		welcome_label_already_shown = true
		
	elif not show_welcome_label:
		welcome_label_3d.hide()
		welcome_label_already_shown = true
		
	# Start autosave config timer, at some point only set this in the config file loaded or created signal but just for testing for now
	# Setting to 0 will disable autosave
	if xr_config_handler.autosave_action_map_duration_in_secs != 0:
		xr_autosave_timer.wait_time = xr_config_handler.autosave_action_map_duration_in_secs
		if xr_autosave_timer.is_paused():
			xr_autosave_timer.set_paused(false)
		xr_autosave_timer.start()
	else:
		if not xr_autosave_timer.is_stopped():
			xr_autosave_timer.set_paused(true)

	# Update UGVR GUI
	update_ugvr_gui()

# Function to set proper world scale for various nodes that depend on sizes and distances
func set_worldscale_for_xr_nodes(new_xr_world_scale):
	gesture_area.transform.origin.y = 0.45 * new_xr_world_scale
	gesture_area.get_node("GestureAreaShape").shape.radius = 0.3 * new_xr_world_scale
	gesture_area.get_node("GestureAreaShape").shape.margin = 0.1 * new_xr_world_scale
	welcome_label_3d.position = Vector3(0, -0.3, -2) * new_xr_world_scale
	welcome_label_3d.scale = Vector3(1,1,1) * new_xr_world_scale
	xr_pointer.distance = 10 * new_xr_world_scale
	left_gesture_detection_area.get_node("ControllerGestureShape").shape.radius = 0.2 * new_xr_world_scale
	left_gesture_detection_area.get_node("ControllerGestureShape").shape.margin = 0.04 * new_xr_world_scale
	right_gesture_detection_area.get_node("ControllerGestureShape").shape.radius = 0.2 * new_xr_world_scale
	right_gesture_detection_area.get_node("ControllerGestureShape").shape.margin = 0.04 * new_xr_world_scale
	
# Function to pull current state of config handler control options variables to set same xr scene variables based on user config	
func set_xr_control_options():
	# Load base control maps
	primary_action_map = xr_config_handler.primary_action_map
	secondary_action_map = xr_config_handler.secondary_action_map
	
	# Load mouse emulation options
	stick_emulate_mouse_movement = xr_config_handler.stick_emulate_mouse_movement
	head_emulate_mouse_movement = xr_config_handler.head_emulate_mouse_movement
	primary_controller_emulate_mouse_movement = xr_config_handler.primary_controller_emulate_mouse_movement
	secondary_controller_emulate_mouse_movement = xr_config_handler.secondary_controller_emulate_mouse_movement
	emulated_mouse_sensitivity_multiplier = xr_config_handler.emulated_mouse_sensitivity_multiplier
	emulated_mouse_deadzone = xr_config_handler.emulated_mouse_deadzone
	
	# Load other control options
	turning_type = xr_config_handler.turning_type
	turning_speed = xr_config_handler.turning_speed
	turning_degrees = xr_config_handler.turning_degrees
	stick_turn_controller = xr_config_handler.stick_turn_controller
	grip_deadzone = xr_config_handler.grip_deadzone
	primary_controller_selection = xr_config_handler.primary_controller_selection
	ugvr_menu_toggle_combo = xr_config_handler.ugvr_menu_toggle_combo
	pointer_gesture_toggle_button = xr_config_handler.pointer_gesture_toggle_button
	gesture_load_action_map_button = xr_config_handler.gesture_load_action_map_button
	gesture_set_user_height_button = xr_config_handler.gesture_set_user_height_button
	dpad_activation_button = xr_config_handler.dpad_activation_button
	start_button = xr_config_handler.start_button
	select_button = xr_config_handler.select_button
	use_physical_gamepad_only = xr_config_handler.use_physical_gamepad_only
	use_motion_sickness_vignette = xr_config_handler.use_motion_sickness_vignette
	
	# Setup vignette
	xr_vignette.set_enabled(use_motion_sickness_vignette)
	
	# Set up xr controllers to emulate gamepad
	var finished = map_xr_controllers_to_action_map()
	
	# Update UGVR GUI
	update_ugvr_gui()

# Function to pull current state of config handler action map variables to set same xr scene variables based on user config	
func set_xr_action_map_options():
	use_xr_radial_menu = xr_config_handler.use_xr_radial_menu
	xr_radial_menu_mode = xr_config_handler.xr_radial_menu_mode
	xr_radial_menu_entries = xr_config_handler.xr_radial_menu_entries
	open_radial_menu_button = xr_config_handler.open_radial_menu_button
	setup_radial_menu()
	
	# Update UGVR GUI
	update_ugvr_gui()

	
# Receiver function for config file signal that game options have been loaded
func _on_xr_config_handler_xr_game_options_cfg_loaded(_path_to_file : String):
	set_xr_game_options()
	
# Reciever function for config file signal that control options have been loaded
func _on_xr_config_handler_xr_game_control_map_cfg_loaded(_path_to_file : String):
	set_xr_control_options()

# Reciever function for config file signal that action map options have been loaded	
func _on_xr_config_handler_xr_game_action_map_cfg_loaded(_path_to_file : String):
	set_xr_action_map_options()

# Receiver function for config file signal that game options have been saved
func _on_xr_config_handler_xr_game_options_cfg_saved(_path_to_file : String):
	set_xr_game_options()
	
# Reciever function for config file signal that control options have been saved
func _on_xr_config_handler_xr_game_control_map_cfg_saved(_path_to_file : String):
	set_xr_control_options()

# Reciever function for config file signal that action map options have been saved	
func _on_xr_config_handler_xr_game_action_map_cfg_saved(_path_to_file : String):
	set_xr_action_map_options()


# Update UGVR GUI
func update_ugvr_gui():
	var primary_controller_selection_index = 0 if primary_controller_selection == "right" else 1 
	var xr_gui_settings : Array = [
		{
			"setting_name": "primary_controller",
			"options": ["right", "left"],
			"active_index": primary_controller_selection_index
		},
		{
			"setting_name": "use_controller_dir_movement",
			"options": [false, true],
			"active_index": int(use_roomscale_controller_directed_movement)
		},
		{
			"setting_name": "turning_type",
			"options": ["snap", "smooth", "none"],
			"active_index": turning_type
		},
		{
			"setting_name": "use_arm_swing_jump",
			"options": [false, true],
			"active_index": int(use_arm_swing_jump)
		},
		{
			"setting_name": "use_jog_movement",
			"options": [false, true],
			"active_index": int(use_jog_movement)
		},
		{
			"setting_name": "use_motion_vignette",
			"options": [false, true],
			"active_index": int(use_motion_sickness_vignette)
		},
		{
			"setting_name": "show_welcome_label",
			"options": [false, true],
			"active_index": int(show_welcome_label)
		},
	]
	xr_gui_menu.set_xr_controller(primary_controller)
	xr_gui_menu.set_settings_to_populate(xr_gui_settings)

# Function to display ugvr options menu
func toggle_xr_gui_menu():
	if !is_instance_valid(xr_gui_menu):
		return
	
	#Make menu appear whenever pointer is enabled for now, change later to custom keybind	
	xr_gui_menu.visible = xr_pointer.enabled
	
	if xr_gui_menu.visible:
		ugvr_menu_showing = true
		# Get references to the nodes
		var distance = 1 * xr_world_scale
		var vertical_offset = 0.25 * xr_camera_3d.global_transform.origin.y

		# Get the camera's global transform
		var cam_transform = xr_camera_3d.global_transform
		
		# Get the camera's forward vector (-z) and remove vertical component
		var forward = -cam_transform.basis.z
		forward.y = 0
		forward = forward.normalized()
		# Set the menu's position 2 units in front of the camera
		var menu_position: Vector3 = cam_transform.origin + forward * distance
		# Offset height
		menu_position.y -= vertical_offset
		# Create a rotation so the menu faces the camera.
		# Compute the yaw angle from the flattened forward vector.
		var yaw_angle = atan2(forward.x, forward.z)
		# Add PI radians to flip by 180 degrees
		var menu_basis = Basis(Vector3.UP, yaw_angle + PI)
		# Set the global transform of the menu (rotation and position)
		xr_gui_menu.global_transform = Transform3D(menu_basis, menu_position)
	
	else:
		ugvr_menu_showing = false
		# Reset position
		xr_gui_menu.global_transform.origin = Vector3(0,0,0)

# Triggers when gui object indicates user has changed a setting by firing its setting changed signal
func _on_xr_gui_setting_changed(setting_name: String, setting_value: Variant):
	match setting_name:
		"primary_controller":
			primary_controller_selection = setting_value
			xr_config_handler.primary_controller_selection = setting_value
		"use_controller_dir_movement":
			use_roomscale_controller_directed_movement = setting_value
			xr_config_handler.use_roomscale_controller_directed_movement = setting_value
			xr_config_handler.save_game_options_cfg_file(xr_config_handler.game_options_cfg_path)
		"turning_type":
			# "snap", "smooth", "none"
			if setting_value == "snap":
				setting_value = TurningType.SNAP
			elif setting_value == "smooth":
				setting_value = TurningType.SMOOTH
			elif setting_value == "none":
				setting_value = TurningType.NONE
			turning_type = setting_value
			xr_config_handler.turning_type = setting_value
			xr_config_handler.save_game_control_map_cfg_file(xr_config_handler.game_control_map_cfg_path)
		"use_arm_swing_jump":
			use_arm_swing_jump = setting_value
			xr_config_handler.use_arm_swing_jump = setting_value
			xr_config_handler.save_game_options_cfg_file(xr_config_handler.game_options_cfg_path)
		"use_jog_movement":
			use_jog_movement = setting_value
			xr_config_handler.use_jog_movement = setting_value
			xr_config_handler.save_game_options_cfg_file(xr_config_handler.game_options_cfg_path)
		"use_motion_vignette":
			use_motion_sickness_vignette = setting_value
			xr_config_handler.use_motion_sickness_vignette = setting_value
			xr_config_handler.save_game_control_map_cfg_file(xr_config_handler.game_control_map_cfg_path)
		"show_welcome_label":
			show_welcome_label = setting_value
			xr_config_handler.show_welcome_label = setting_value
			xr_config_handler.save_game_options_cfg_file(xr_config_handler.game_options_cfg_path)
		
# -----------------------------------------------------
# EXPERIMENTAL SECTION - NOT FOR FINAL INJECTOR

# Another way of debug printing of scene tree - could be more useful if want to do something more than just print like actually operate on the nodes
#func get_nodes_in_scene(scene: Node):
	#var nodes = [scene]
	#for child in scene.get_children(true):
		#nodes.append_array(get_nodes_in_scene(child))
	
	#return nodes

#var scene_tree = get_tree().current_scene
#for node in get_nodes_in_scene(get_tree().current_scene):
	#print("node name: ", node.name)
	#print("node_path: ", node.get_path())

# Tests only for new reparenting weapon code; in the future the specific node will be set by menu or a modder could use the function above in another script
func _set_vostok_gun(delta):
	RenderingServer.viewport_set_scaling_3d_mode(currentRID, RenderingServer.VIEWPORT_SCALING_3D_MODE_BILINEAR)
	if is_instance_valid(xr_roomscale_controller) and is_instance_valid(xr_roomscale_controller.camera_3d):
		var vostok_weapons_node = xr_roomscale_controller.camera_3d.find_child("Weapons", false, false)
		if vostok_weapons_node != null:
			if vostok_weapons_node.get_child_count(true) > 0:
				var vostok_weapon = vostok_weapons_node.get_child(0, true)
				#print(vostok_weapon)
				# First see if weapon is a firearm
				var vostok_weapon_mesh = vostok_weapon.get_node_or_null("Handling/Sway/Noise/Tilt/Impulse/Recoil/Weapon")
				# if that's not valid, try to see if it's a knife instead
				if not is_instance_valid(vostok_weapon_mesh):
					vostok_weapon_mesh = vostok_weapon.get_node_or_null("Handling/Sway/Noise/Tilt/Impulse/Knife")
				# if that's still not valid, try to see if its a instrument instead
				if not is_instance_valid(vostok_weapon_mesh):
					vostok_weapon_mesh = vostok_weapon.get_node_or_null("Sway/Noise/Tilt/Impulse/Instrument")
				#print(vostok_weapon_mesh)
				if is_instance_valid(vostok_weapon_mesh):
					var vostok_arms = vostok_weapon_mesh.find_child("MS_Arms", true, false)
					if vostok_arms:
						vostok_arms.visible = false
						xr_reparenting_active = true
						var rotate_reparented_node_180_degrees = true
						handle_node_reparenting(delta, vostok_weapon_mesh, rotate_reparented_node_180_degrees, Vector3(0.0, 0.025, 0.025))
				
	elif is_instance_valid(current_camera):
		var vostok_weapons_node = current_camera.find_child("Weapons", false, false)
		if vostok_weapons_node != null:
			if vostok_weapons_node.get_child_count(true) > 0:
				var vostok_weapon = vostok_weapons_node.get_child(0, true)
				#print(vostok_weapon)
				var vostok_weapon_mesh = vostok_weapon.get_node_or_null("Handling/Sway/Noise/Tilt/Impulse/Recoil/Weapon")
				# if that's not valid, try to see if it's a knife instead
				if not is_instance_valid(vostok_weapon_mesh):
					vostok_weapon_mesh = vostok_weapon.get_node_or_null("Handling/Sway/Noise/Tilt/Impulse/Knife")
				# if that's still not valid, try to see if its a instrument instead
				if not is_instance_valid(vostok_weapon_mesh):
					vostok_weapon_mesh = vostok_weapon.get_node_or_null("Sway/Noise/Tilt/Impulse/Instrument")
				#print(vostok_weapon_mesh)
				if is_instance_valid(vostok_weapon_mesh):
					var vostok_arms = vostok_weapon_mesh.find_child("MS_Arms", true, false)
					if vostok_arms:
						vostok_arms.visible = false
						xr_reparenting_active = true
						var rotate_reparented_node_180_degrees = true
						handle_node_reparenting(delta, vostok_weapon_mesh, rotate_reparented_node_180_degrees, Vector3(0,0.025,0.025))

# Same, just experimental
func _set_beton_gun(delta : float):
	var gun_node = get_tree().get_root().get_node_or_null("LowresRoot/LowResViewport/Player/RotPoint")
	if gun_node != null and xr_origin_reparented:
		gun_node.get_node("GunHold").transform.origin = Vector3(0,0,0)
		xr_reparenting_active = true
		var rotate_reparented_node_180_degrees = false
		handle_node_reparenting(delta, gun_node, rotate_reparented_node_180_degrees)

# Same, just experimental
func _set_tar_object_picker(delta : float):
	
	if is_instance_valid(xr_roomscale_controller.current_characterbody3D):
		var object_picker_point = xr_roomscale_controller.current_characterbody3D.get_node_or_null("RotationHelper")
		if is_instance_valid(object_picker_point) and xr_origin_reparented:
			object_picker_point.get_node("PlayerEyes/obj_picker_point").transform.origin = Vector3(0,0,0)
			xr_reparenting_active = true
			var rotate_reparented_node_180_degrees = false
			handle_node_reparenting(delta, object_picker_point, rotate_reparented_node_180_degrees)


# Same, just experiemental - example of using custom code and variables with UGVR to get a specific game working better in VR after using the print tree functionality to get scene tree
# Using a game specific prefix like "CRUEL_" helps ensure there can't be conflicts from other variables in UGVR
var first_time_reparenting_CRUEL_gun : bool = true
var CRUEL_camera_node = null
var CRUEL_node3d = null
var CRUEL_weapon_container = null
var CRUEL_sway_controller = null
var CRUEL_pistol = null
var CRUEL_raycast = null
var CRUEL_melee_raycast = null
var CRUEL_interact_raycast = null
var CRUEL_melee_shapecast = null
var CRUEL_bullet_shapecast = null
var CRUEL_nearest_target = null
func _set_CRUEL_gun(delta: float):
	if is_instance_valid(xr_roomscale_controller.current_characterbody3D):
		var weapon_node = get_tree().get_root().get_node_or_null("Level/Node/Player/Head/ShakeTarget/CameraShake/Camera/Node3D/WeaponContainer/SwayController/Pistol")
		
		if weapon_node != null and xr_origin_reparented:
			
			if first_time_reparenting_CRUEL_gun or not is_instance_valid(CRUEL_camera_node):
				first_time_reparenting_CRUEL_gun = false
				weapon_node.transform.origin = Vector3(0,0,0)
				CRUEL_camera_node = get_tree().get_root().get_node_or_null("Level/Node/Player/Head/ShakeTarget/CameraShake/Camera")
				CRUEL_node3d = CRUEL_camera_node.get_node("Node3D")
				CRUEL_weapon_container = CRUEL_node3d.get_node("WeaponContainer")
				CRUEL_sway_controller = CRUEL_weapon_container.get_node("SwayController")
				CRUEL_pistol = CRUEL_sway_controller.get_node("Pistol")
				CRUEL_raycast = CRUEL_camera_node.get_node("RayCast3D")
				CRUEL_melee_raycast = CRUEL_camera_node.get_node("MeleeRaycast")
				CRUEL_interact_raycast = CRUEL_camera_node.get_node("InteractRaycast")
				CRUEL_melee_shapecast = CRUEL_camera_node.get_node("MeleeShapeCast3D")
				CRUEL_bullet_shapecast = CRUEL_camera_node.get_node("BulletDeflectShapeCast3D")
				CRUEL_nearest_target = CRUEL_camera_node.get_node("NearestTarget")
				CRUEL_node3d.transform.origin = Vector3(0,0,0)
				CRUEL_weapon_container.transform.origin = Vector3(0,0,0)
				CRUEL_sway_controller.transform.origin = Vector3(0,0,0)
				CRUEL_pistol.transform.origin = Vector3(0,0,0)
				CRUEL_raycast.transform.origin = Vector3(0,0,0)
				CRUEL_melee_raycast.transform.origin = Vector3(0,0,0)
				CRUEL_interact_raycast.transform.origin = Vector3(0,0,0)
				CRUEL_melee_shapecast.transform.origin = Vector3(0,0,0)
				CRUEL_bullet_shapecast.transform.origin = Vector3(0,0,0)
				CRUEL_nearest_target.transform.origin = Vector3(0,0,0)
				CRUEL_raycast.force_raycast_update() 
				CRUEL_melee_raycast.force_raycast_update()
				CRUEL_interact_raycast.force_raycast_update()
				CRUEL_melee_shapecast.force_shapecast_update() 
				CRUEL_bullet_shapecast.force_shapecast_update()
				# Add 3D cursor to weapon node, should be where raycasts point, for this game the closer distance seems to be more accurate
				var cursor = cursor_3d.duplicate()
				weapon_node.add_child(cursor)
				cursor.transform.origin.z = -roomscale_3d_cursor_distance_from_camera
				cursor.transform.origin.y = 0.3
				cursor.visible = true
				# reparent directly to avoid stuttering
				weapon_node.reparent(primary_controller, false)
				# now need a way to stop camera movement from controlling transform.origin of weapon node, must be hard wired somehow in code

			xr_reparenting_active = true
			#var rotate_reparented_node_180_degrees = false
			#handle_node_reparenting(delta, weapon_node, rotate_reparented_node_180_degrees, Vector3(0,0.3,0))

		if is_instance_valid(CRUEL_raycast):
			handle_node_reparenting(delta, CRUEL_raycast, false, Vector3(0,0.3,0))
			CRUEL_raycast.force_raycast_update()
		if is_instance_valid(CRUEL_bullet_shapecast):
			handle_node_reparenting(delta, CRUEL_bullet_shapecast, false, Vector3(0,0.3,0))
			CRUEL_bullet_shapecast.force_shapecast_update()
			
			#Try to cut down stuttering
			#CRUEL_pistol.bulletDeviation = 0.0
			#CRUEL_weapon_container.walkBobAmplitude = 0.0
			#CRUEL_weapon_container.bobAmplitude = 0
