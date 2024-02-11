# This is the main VR Scene that is injected into the 3D game.
# The method for this was developed by Decacis (creator of Badaboom on AppLab)
# Then JulianTodd (creator of TunnelVR on AppLab/Sidequest) developed a way to allow VR pointers to be used in the game's 2D UI
# Along with the code in injector.gd developed by Decacis, these form the core parts of injecting VR into a Godot 3D game

extends Node3D

# Core XR Scene Components
@onready var xr_origin_3d : XROrigin3D = $XROrigin3D
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

var xr_interface : XRInterface
var active_canvas_layer : CanvasLayer

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

		# Add scene under secondary viewport
		#var node_2d = Control.new()
		xr_secondary_viewport2d_in_3d.set_viewport_size(xr_main_viewport2d_in_3d.viewport_size)
		#node_2d.size = xr_secondary_viewport2d_in_3d.viewport_size
		#xr_secondary_viewport2d_in_3d_subviewport.add_child(node_2d, true)
		# Set up xr controllers to emulate gamepad
		map_xr_controllers_to_action_map()
		
		set_process(true)
	else:
		print("OpenXR not initialized, please check if your headset is connected")

	# Clear Welcome label (probably someday can make it a config not to show again)
	await get_tree().create_timer(12.0).timeout
	welcome_label_3d.hide()

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
					
	# second attempt to find canvas layer and display it
	var potential_canvas_layer_nodes : Array = get_node("/root").find_children("*", "CanvasLayer", true, false)
	print("Potential canvas layer nodes: ", potential_canvas_layer_nodes)
	
	if potential_canvas_layer_nodes == []:
		return
	
	for canvas_layer in potential_canvas_layer_nodes:
		if canvas_layer.visible == true and active_canvas_layer != canvas_layer:
			print("making canvas layer active: ", canvas_layer)
			active_canvas_layer = canvas_layer
			canvas_layer.set_custom_viewport(xr_main_viewport2d_in_3d_subviewport)
			
			#var canvas_layer_children = canvas_layer.get_children()
			#for child in canvas_layer_children:
				#print("Canvas layer child found: ", child)
				#xr_secondary_viewport2d_in_3d_subviewport.get_child(0).add_child(child.duplicate())
			#xr_secondary_viewport2d_in_3d._update_render()
	# First attempt below
	# find out if there is a CanvasLayer node and if so try to display its contents on secondary viewport screen
		
	#var potential_canvas_layer_nodes : Array = get_node("/root").find_children("*", "CanvasLayer", true, false)
	#print("Potential canvas layer nodes: ", potential_canvas_layer_nodes)
	#if potential_canvas_layer_nodes == []:
		#return
	#
	#for canvas_layer in potential_canvas_layer_nodes:
		#if canvas_layer.visible == true and active_canvas_layer != canvas_layer:
			#print("making canvas layer active: ", canvas_layer)
			#active_canvas_layer = canvas_layer
			#var canvas_layer_children = canvas_layer.get_children()
			#for child in canvas_layer_children:
				#print("Canvas layer child found: ", child)
				#xr_secondary_viewport2d_in_3d_subviewport.get_child(0).add_child(child.duplicate())
			#xr_secondary_viewport2d_in_3d._update_render()
			#
	## if we have an active canvas layer identified, check whether its visible to determine whether to show secondary viewport
	#if active_canvas_layer:
		#print(active_canvas_layer.visible)
		#if active_canvas_layer.visible == false:
			#xr_secondary_viewport2d_in_3d.hide()
		#else:
			#xr_secondary_viewport2d_in_3d.show()
		
		
			#var canvas_layer_viewport = canvas_layer.get_custom_viewport()
			#print(canvas_layer_viewport)
			#xr_secondary_viewport2d_in_3d.set_viewport_size(canvas_layer_viewport.get_visible_rect().size)
			#xr_secondary_viewport2d_in_3d_subviewport.world_2d = canvas_layer_viewport.world_2d
			#print(canvas_layer_viewport.world2d)
			#print(xr_main_viewport2d_in_3d_subviewport.world2d)
			#xr_secondary_viewport2d_in_3d.get_node("StaticBody3D")._viewport = canvas_layer_viewport
			#print(xr_secondary_viewport2d_in_3d.get_node("StaticBody3D")._viewport)
			#break
	#for ui_node in potential_ui_nodes:
		#if ui_node.is_class("Container") or ui_node.is_class("ColorRect") or ui_node.is_class("Panel") or ui_node.get_class() == "Control":
			## Check if we've found ui_node  before by determining if its in our custom group, if not add it to group
			#if not ui_node.is_in_group("possible_xr_uis"):
				#ui_node.add_to_group("possible_xr_uis")
				#ui_node_final_candidates.append(ui_node)
	
	
	# Do we need to do something to remove the remote transforms from other cameras here? Remains to be seen.
	# If so could cycle through group of possible cameras and remove.
	
	# Get active menu scene / UI - old approach, probably unnecesary but leaving in case needed someday as possible fallback option
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

# Temporary signals for now for debugging and fine tuning
func _on_gesture_area_area_entered(area):
	print("detected user's hand in gesture activation area")


func _on_gesture_area_area_exited(area):
	print("detected user's hand left gesture activation area")
