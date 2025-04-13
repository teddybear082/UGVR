## This node handles all the saving and loading of UGVR config files for options and game action mapping
extends Node

signal xr_game_options_cfg_saved(path : String)

signal xr_game_control_map_cfg_saved(path : String)

signal xr_game_action_map_cfg_saved(path : String)

signal xr_game_options_cfg_loaded(path : String)

signal xr_game_control_map_cfg_loaded(path : String)

signal xr_game_action_map_cfg_loaded(path : String)

var needs_mapping_phrase = "needs_joypad_mapping"

# Removed some key UI actions to allow motion controls to work in some game menus that don't have native controller support
var default_action_map_actions = [
	#"ui_accept",
	#"ui_select", 
	#"ui_cancel", 
	"ui_focus_next",
	"ui_focus_prev",
	#"ui_left",
	#"ui_right",
	#"ui_up",
	#"ui_down",
	"ui_page_up",
	"ui_page_down", 
	"ui_home",
	"ui_end",
	"ui_cut",
	"ui_copy",
	"ui_paste",
	"ui_undo",
	"ui_redo",
	"ui_text_completion_query",
	"ui_text_completion_accept",
	"ui_text_completion_replace",
	"ui_text_newline",
	"ui_text_newline_blank",
	"ui_text_newline_above",
	"ui_text_indent",
	"ui_text_dedent",
	"ui_text_backspace",
	"ui_text_backspace_word",
	"ui_text_backspace_word.macos",
	"ui_text_backspace_all_to_left",
	"ui_text_backspace_all_to_left.macos",
	"ui_text_delete",
	"ui_text_delete_word",
	"ui_text_delete_word.macos",
	"ui_text_delete_all_to_right",
	"ui_text_delete_all_to_right.macos",
	"ui_text_caret_left", 
	"ui_text_caret_word_left",
	"ui_text_caret_word_left.macos",
	"ui_text_caret_right",
	"ui_text_caret_word_right", 
	"ui_text_caret_word_right.macos",
	"ui_text_caret_up",
	"ui_text_caret_down",
	"ui_text_caret_line_start",
	"ui_text_caret_line_start.macos",
	"ui_text_caret_line_end",
	"ui_text_caret_line_end.macos",
	"ui_text_caret_page_up",
	"ui_text_caret_page_down",
	"ui_text_caret_document_start",
	"ui_text_caret_document_start.macos", 
	"ui_text_caret_document_end",
	"ui_text_caret_document_end.macos",
	"ui_text_caret_add_below",
	"ui_text_caret_add_below.macos",
	"ui_text_caret_add_above",
	"ui_text_caret_add_above.macos",
	"ui_text_scroll_up",
	"ui_text_scroll_up.macos",
	"ui_text_scroll_down",
	"ui_text_scroll_down.macos",
	"ui_text_select_all",
	"ui_text_select_word_under_caret",
	"ui_text_select_word_under_caret.macos",
	"ui_text_add_selection_for_next_occurrence",
	"ui_text_clear_carets_and_selection",
	"ui_text_toggle_insert_mode",
	"ui_menu",
	"ui_text_submit",
	"ui_graph_duplicate",
	"ui_graph_delete",
	"ui_filedialog_up_one_level",
	"ui_filedialog_refresh",
	"ui_filedialog_show_hidden",
	"ui_swap_input_direction" 
]

var default_gamepad_button_names : Array = [
	"Joypad A/Cross",
	"Joypad B/Circle",
	"Joypad X/Square",
	"Joypad Y/Triangle",
	"Joypad Back/Select",
	"Joypad Home/PS",
	"Joypad Start",
	"Joypad L3",
	"Joypad R3",
	"Joypad LB",
	"Joypad RB",
	"Joypad DpadUp",
	"Joypad DpadDown",
	"Joypad DpadLeft",
	"Joypad DpadRight"
]

var default_joystick_axis_names: Array = [
	"Joypad LeftStickX",
	"Joypad LeftStickY",
	"Joypad RightStickX",
	"Joypad RightStickY",
	"Joypad LeftTrigger",
	"Joypad RightTrigger"
]

var primary_action_map = {
		"grip_click":JOY_BUTTON_RIGHT_SHOULDER,
		"primary_click":JOY_BUTTON_RIGHT_STICK,
		"ax_button":JOY_BUTTON_A,
		"by_button":JOY_BUTTON_X
	}

var secondary_action_map = {
		"grip_click":JOY_BUTTON_LEFT_SHOULDER,
		"primary_click":JOY_BUTTON_LEFT_STICK,
		"ax_button":JOY_BUTTON_B,
		"by_button":JOY_BUTTON_Y
	}

##CONTROLS Config Options
enum XR_RADIAL_TYPE {
	GAMEPAD = 0,
	KEYBOARD = 1,
	ACTION = 2
}

enum TurningType {
	SNAP = 0,
	SMOOTH = 1,
	NONE = 2
}

# option if user will use only a physical gamepad, deactivates rest of motion control emulation
var use_physical_gamepad_only : bool = false

# Maybe unnecessary; maybe we always use gamepad emulation, but still might want to turn this off if someone built a more robust game-specific mod
var use_gamepad_emulation : bool = true

# Maybe just use action mapping to assign joypad binds instead of ever "emulating" keyboard? LIKELY DELETE
var use_keyboard_emulation : bool = false

# Mouse emulation options
var stick_emulate_mouse_movement : bool = false
var head_emulate_mouse_movement : bool = false
var primary_controller_emulate_mouse_movement : bool = false
var secondary_controller_emulate_mouse_movement : bool = false
var emulated_mouse_sensitivity_multiplier : int = 10
var emulated_mouse_deadzone : float = 0.25

# Grip deazone
var grip_deadzone : float = 0.7

# Stick turning style for camera
var turning_type : TurningType = TurningType.SNAP

# Stick turning options
var turning_speed : float = 90.0
var turning_degrees : float = 30.0
var stick_turn_controller : String = "primary_controller"

# Motion sickness vignette options
var use_motion_sickness_vignette : bool = false

# UGVR specific special button maps
var ugvr_menu_toggle_combo : Dictionary = {"primary_controller" : ["primary_click"], "secondary_controller": ["primary_click"]}

var pointer_gesture_toggle_button : String = "trigger_click"

var gesture_load_action_map_button : String = "by_button"

var gesture_set_user_height_button : String = "by_button"

var dpad_activation_button : String = "primary_touch" 

# Primary controller: controller that is mapped by default to right thumbstick, A & X buttons, right trigger and right RB; controller has dpad/start/select activation button and is used for set height gesture toggle
var primary_controller_selection : String = "right"

var start_button : String = "primary_click"

var select_button : String = "by_button"


# Radial menu options in ACTION MAP options
var use_xr_radial_menu : bool = false
var xr_radial_menu_mode : XR_RADIAL_TYPE = XR_RADIAL_TYPE.GAMEPAD
var xr_radial_menu_entries : Array = ["Joypad Y/Triangle", "Joypad B/Circle", "Joypad A/Cross", "Joypad X/Square"]
var open_radial_menu_button : String = "by_button"

# Haptics options in ACTION MAP options
var game_actions_triggering_primary_haptics = [] # e.g., ['reload', 'fire', 'kick', 'melee']
var game_actions_triggering_secondary_haptics = []
# Gesture based commands in ACTION MAP options
var primary_controller_melee_velocity = 15.0 # set to 0 to disable
var secondary_controller_melee_velocity = 15.0 # set to 0 to disable
var primary_controller_melee_cooldown_secs = 0.50
var secondary_controller_melee_cooldown_secs = 0.50
var primary_controller_melee_action = ""
var secondary_controller_melee_action = ""

## GAME OPTIONS CONFIG
# Roomscale menu options in GAME options
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

# XR Hands Options in GAME options
var show_xr_hands : bool = true
var xr_hand_material_choice : int = 0

# CAMERA Config Options in GAME options

var xr_world_scale : float = 1.0

var camera_offset : Vector3 = Vector3(0,0,0)

var experimental_passthrough : bool = false

var xr_use_vehicle_mode : bool = false

# VIEWPORTS Config Options in GAME options

enum XR_VIEWPORT_LOCATION {
	CAMERA = 0,
	PRIMARY_CONTROLLER = 1,
	SECONDARY_CONTROLLER = 2
}

var xr_main_viewport_location : XR_VIEWPORT_LOCATION = XR_VIEWPORT_LOCATION.CAMERA

var xr_secondary_viewport_location : XR_VIEWPORT_LOCATION = XR_VIEWPORT_LOCATION.CAMERA

var primary_viewport_size_multiplier : float = 1.0

var secondary_viewport_size_multiplier : float = 1.0

var primary_viewport_resolution_scale_multiplier : float = 1.0

var secondary_viewport_resolution_scale_multiplier : float = 1.0

var primary_viewport_offset : Vector3 = Vector3(0,0,0)

var secondary_viewport_offset : Vector3 = Vector3(0,0,0)

# AUTOSAVE Options in GAME options
var autosave_action_map_duration_in_secs : int = 0 # Off by default

# XR INJECTOR GUI options in GAME options
var show_welcome_label : bool = true


## ConfigFile variables

# Capture errors in saving and loading
var err : int

# Used to determine file name for game options config
var game_options_cfg_path : String

# Used to determine file path for control mapping config
var game_control_map_cfg_path : String

# Used to determine file path for action mapping config
var game_action_map_cfg_path : String

# Used to store config base path
var cfg_base_path : String


# Set up files for configs
func _ready():
	var game_name : String = ProjectSettings.get_setting("application/config/name")
	
	if game_name == "":
		game_name = "default"
	
	game_name = game_name.to_lower().validate_filename()
		
	# Determine where to put file, then save it
	if OS.has_feature("editor"):
		cfg_base_path = "user://XRConfigs"
	else:
		cfg_base_path = OS.get_executable_path().get_base_dir() + "/XRConfigs" 
	
	game_options_cfg_path = cfg_base_path + "/" + game_name + "_" + "xr_game_options.cfg"
	game_action_map_cfg_path = cfg_base_path + "/" + game_name + "_" + "xr_game_action_map.cfg"
	game_control_map_cfg_path = cfg_base_path + "/" + game_name + "_" + "xr_game_control_map.cfg"
	
	if not DirAccess.dir_exists_absolute(cfg_base_path):
		DirAccess.make_dir_recursive_absolute(cfg_base_path)	
		
	if not FileAccess.file_exists(game_options_cfg_path):
		FileAccess.open(game_options_cfg_path, FileAccess.WRITE)
		var complete = save_game_options_cfg_file(game_options_cfg_path)
	#else:
		#var complete = load_game_options_cfg_file(game_options_cfg_path)	
	
	if not FileAccess.file_exists(game_action_map_cfg_path):
		FileAccess.open(game_action_map_cfg_path, FileAccess.WRITE)
		var complete = create_action_map_cfg_file(game_action_map_cfg_path)
	#else:
		#var complete = load_action_map_file(game_action_map_cfg_path)
		
	if not FileAccess.file_exists(game_control_map_cfg_path):
		FileAccess.open(game_control_map_cfg_path, FileAccess.WRITE)
		var complete = create_game_control_map_cfg_file(game_control_map_cfg_path)
	#else:
		#var complete = load_game_control_map_cfg_file(game_control_map_cfg_path)


func load_game_options_cfg_file(file_path: String) -> bool:
	var game_options_cfg_file = ConfigFile.new()
	err = game_options_cfg_file.load(file_path)

	if err != OK:
		printerr("Error loading game options config file! Error: ", err)
		return false

	# Load camera options
	xr_world_scale = game_options_cfg_file.get_value("CAMERA_OPTIONS", "xr_world_scale", xr_world_scale)
	camera_offset = game_options_cfg_file.get_value("CAMERA_OPTIONS", "camera_offset", camera_offset)
	experimental_passthrough = game_options_cfg_file.get_value("CAMERA_OPTIONS", "experimental_passthrough", experimental_passthrough)
	xr_use_vehicle_mode = game_options_cfg_file.get_value("CAMERA_OPTIONS", "xr_use_vehicle_mode", xr_use_vehicle_mode)

	# Load viewport options
	xr_main_viewport_location = game_options_cfg_file.get_value("VIEWPORTS_OPTIONS", "xr_main_viewport_location", xr_main_viewport_location)
	xr_secondary_viewport_location = game_options_cfg_file.get_value("VIEWPORTS_OPTIONS", "xr_secondary_viewport_location", xr_secondary_viewport_location)
	primary_viewport_size_multiplier = game_options_cfg_file.get_value("VIEWPORTS_OPTIONS", "primary_viewport_size_multiplier", primary_viewport_size_multiplier)
	secondary_viewport_size_multiplier = game_options_cfg_file.get_value("VIEWPORTS_OPTIONS", "secondary_viewport_size_multiplier", secondary_viewport_size_multiplier)
	primary_viewport_offset = game_options_cfg_file.get_value("VIEWPORTS_OPTIONS", "primary_viewport_offset", primary_viewport_offset)
	secondary_viewport_offset = game_options_cfg_file.get_value("VIEWPORTS_OPTIONS", "secondary_viewport_offset", secondary_viewport_offset)

	# Load roomscale options
	use_roomscale = game_options_cfg_file.get_value("ROOMSCALE_OPTIONS", "use_roomscale", use_roomscale)
	roomscale_height_adjustment = game_options_cfg_file.get_value("ROOMSCALE_OPTIONS", "roomscale_height_adjustment", roomscale_height_adjustment)
	attempt_to_use_camera_to_set_roomscale_height = game_options_cfg_file.get_value("ROOMSCALE_OPTIONS", "attempt_to_use_camera_to_set_roomscale_height", attempt_to_use_camera_to_set_roomscale_height)
	reverse_roomscale_direction = game_options_cfg_file.get_value("ROOMSCALE_OPTIONS", "reverse_roomscale_direction", reverse_roomscale_direction)
	use_roomscale_controller_directed_movement = game_options_cfg_file.get_value("ROOMSCALE_OPTIONS", "use_roomscale_controller_directed_movement", use_roomscale_controller_directed_movement)
	use_roomscale_3d_cursor = game_options_cfg_file.get_value("ROOMSCALE_OPTIONS", "use_roomscale_3d_cursor", use_roomscale_3d_cursor)
	use_long_range_3d_cursor = game_options_cfg_file.get_value("ROOMSCALE_OPTIONS", "use_long_range_3d_cursor", use_long_range_3d_cursor)
	roomscale_3d_cursor_distance_from_camera = game_options_cfg_file.get_value("ROOMSCALE_OPTIONS", "roomscale_3d_cursor_distance_from_camera", roomscale_3d_cursor_distance_from_camera)
	roomscale_long_range_3d_cursor_distance_from_camera = game_options_cfg_file.get_value("ROOMSCALE_OPTIONS", "roomscale_long_range_3d_cursor_distance_from_camera", roomscale_long_range_3d_cursor_distance_from_camera)
	use_arm_swing_jump = game_options_cfg_file.get_value("ROOMSCALE_OPTIONS", "use_arm_swing_jump", use_arm_swing_jump)
	use_jog_movement = game_options_cfg_file.get_value("ROOMSCALE_OPTIONS", "use_jog_movement", use_jog_movement)
	jog_triggers_sprint = game_options_cfg_file.get_value("ROOMSCALE_OPTIONS", "jog_triggers_sprint", jog_triggers_sprint)
	
	# Load autosave options
	autosave_action_map_duration_in_secs = game_options_cfg_file.get_value("AUTOSAVE_OPTIONS", "autosave_action_map_duration_in_secs", autosave_action_map_duration_in_secs)
	
	# Load xr injector GUI options
	show_welcome_label = game_options_cfg_file.get_value("XR_INJECTOR_GUI_OPTIONS", "show_welcome_label", show_welcome_label)
	
	# Load XR Hands options
	show_xr_hands = game_options_cfg_file.get_value("XR_HANDS_OPTIONS", "show_xr_hands", show_xr_hands)
	xr_hand_material_choice = game_options_cfg_file.get_value("XR_HANDS_OPTIONS", "xr_hand_material_choice", xr_hand_material_choice)
	
	emit_signal("xr_game_options_cfg_loaded", file_path)
	print("Xr game options config loaded")
	return true


func save_game_options_cfg_file(file_path):
	var game_options_cfg_file = ConfigFile.new()
	err = game_options_cfg_file.load(file_path)

	if err != OK:
		printerr("Error saving game options config file!  Error: ", err)
		return false

	
	# Save camera options
	
	game_options_cfg_file.set_value("CAMERA_OPTIONS", "xr_world_scale", xr_world_scale)
	game_options_cfg_file.set_value("CAMERA_OPTIONS", "camera_offset", camera_offset)
	game_options_cfg_file.set_value("CAMERA_OPTIONS", "experimental_passthrough", experimental_passthrough)
	game_options_cfg_file.set_value("CAMERA_OPTIONS", "xr_use_vehicle_mode", xr_use_vehicle_mode)

	# Save viewport options
	
	game_options_cfg_file.set_value("VIEWPORTS_OPTIONS", "xr_main_viewport_location", xr_main_viewport_location)
	game_options_cfg_file.set_value("VIEWPORTS_OPTIONS", "xr_secondary_viewport_location", xr_secondary_viewport_location)
	game_options_cfg_file.set_value("VIEWPORTS_OPTIONS", "primary_viewport_size_multiplier", primary_viewport_size_multiplier)
	game_options_cfg_file.set_value("VIEWPORTS_OPTIONS", "secondary_viewport_size_multiplier", secondary_viewport_size_multiplier)
	game_options_cfg_file.set_value("VIEWPORTS_OPTIONS", "primary_viewport_offset", primary_viewport_offset)
	game_options_cfg_file.set_value("VIEWPORTS_OPTIONS", "secondary_viewport_offset", secondary_viewport_offset)

	# Save roomscale options
	
	game_options_cfg_file.set_value("ROOMSCALE_OPTIONS", "use_roomscale", use_roomscale)
	game_options_cfg_file.set_value("ROOMSCALE_OPTIONS", "roomscale_height_adjustment", roomscale_height_adjustment)
	game_options_cfg_file.set_value("ROOMSCALE_OPTIONS", "attempt_to_use_camera_to_set_roomscale_height", attempt_to_use_camera_to_set_roomscale_height)
	game_options_cfg_file.set_value("ROOMSCALE_OPTIONS", "reverse_roomscale_direction", reverse_roomscale_direction)
	game_options_cfg_file.set_value("ROOMSCALE_OPTIONS", "use_roomscale_controller_directed_movement", use_roomscale_controller_directed_movement)
	game_options_cfg_file.set_value("ROOMSCALE_OPTIONS", "use_roomscale_3d_cursor", use_roomscale_3d_cursor)
	game_options_cfg_file.set_value("ROOMSCALE_OPTIONS", "use_long_range_3d_cursor", use_long_range_3d_cursor)
	game_options_cfg_file.set_value("ROOMSCALE_OPTIONS", "roomscale_3d_cursor_distance_from_camera", roomscale_3d_cursor_distance_from_camera)
	game_options_cfg_file.set_value("ROOMSCALE_OPTIONS", "roomscale_long_range_3d_cursor_distance_from_camera", roomscale_long_range_3d_cursor_distance_from_camera)
	game_options_cfg_file.set_value("ROOMSCALE_OPTIONS", "use_arm_swing_jump", use_arm_swing_jump)
	game_options_cfg_file.set_value("ROOMSCALE_OPTIONS", "use_jog_movement", use_jog_movement)
	game_options_cfg_file.set_value("ROOMSCALE_OPTIONS", "jog_triggers_sprint", jog_triggers_sprint)
	
	# Save autosave options
	game_options_cfg_file.set_value("AUTOSAVE_OPTIONS", "autosave_action_map_duration_in_secs", autosave_action_map_duration_in_secs)
	
	# Save XR Injector GUI options
	game_options_cfg_file.set_value("XR_INJECTOR_GUI_OPTIONS", "show_welcome_label", show_welcome_label)
	
	# Save XR Hands options
	game_options_cfg_file.set_value("XR_HANDS_OPTIONS", "show_xr_hands", show_xr_hands)
	game_options_cfg_file.set_value("XR_HANDS_OPTIONS", "xr_hand_material_choice", xr_hand_material_choice)
	
	# Now save config file itself
	err = game_options_cfg_file.save(file_path)
	
	emit_signal("xr_game_options_cfg_saved", file_path)
	
	return true

func create_action_map_cfg_file(file_path):
	var action_map_cfg_file = ConfigFile.new()
	err = action_map_cfg_file.load(file_path)

	if err != OK:
		printerr("Error creating action map config file!  Error: ", err)
		return false
	# Get a list of the input actions the game dev used
	var flat_screen_actions = InputMap.get_actions()

	# Only try to remap custom actions, so check if default first
	for action in flat_screen_actions:
		if not action in default_action_map_actions:
			# Get input events assigned to each action
			var game_action_events = InputMap.action_get_events(action)
			# Some actions may have multiple events assigned, set this variable to prevent overwriting valid actions with "needs mapping"
			var event_already_set_for_action = false
			for event in game_action_events:
				# If not mapped to a joypad input let user know otherwise show mapping
				if event_already_set_for_action:
					break
				if not event is InputEventJoypadButton and not event is InputEventJoypadMotion:
					action_map_cfg_file.set_value("GAME_ACTIONS", action, needs_mapping_phrase)
				elif event is InputEventJoypadButton:
					action_map_cfg_file.set_value("GAME_ACTIONS", action, default_gamepad_button_names[event.button_index])
					event_already_set_for_action = true
				elif event is InputEventJoypadMotion:
					action_map_cfg_file.set_value("GAME_ACTIONS", action, [default_joystick_axis_names[event.axis], event.axis_value])
					event_already_set_for_action = true
	
	# Now create radial menu options
	action_map_cfg_file.set_value("RADIAL_MENU_OPTIONS", "use_xr_radial_menu", use_xr_radial_menu)
	action_map_cfg_file.set_value("RADIAL_MENU_OPTIONS", "xr_radial_menu_mode", xr_radial_menu_mode)
	action_map_cfg_file.set_value("RADIAL_MENU_OPTIONS", "xr_radial_menu_entries", xr_radial_menu_entries)
	action_map_cfg_file.set_value("RADIAL_MENU_OPTIONS", "open_radial_menu_button", open_radial_menu_button)
	
	# Now create haptic and melee options
	action_map_cfg_file.set_value("RADIAL_MENU_OPTIONS", "use_xr_radial_menu", use_xr_radial_menu)
	action_map_cfg_file.set_value("RADIAL_MENU_OPTIONS", "xr_radial_menu_mode", xr_radial_menu_mode)
	action_map_cfg_file.set_value("RADIAL_MENU_OPTIONS", "xr_radial_menu_entries", xr_radial_menu_entries)
	action_map_cfg_file.set_value("RADIAL_MENU_OPTIONS", "open_radial_menu_button", open_radial_menu_button)
	action_map_cfg_file.set_value("HAPTICS", "game_actions_triggering_primary_haptics", game_actions_triggering_primary_haptics)
	action_map_cfg_file.set_value("HAPTICS", "game_actions_triggering_secondary_haptics", game_actions_triggering_secondary_haptics)
	action_map_cfg_file.set_value("MELEE", "primary_controller_melee_velocity", primary_controller_melee_velocity)
	action_map_cfg_file.set_value("MELEE", "secondary_controller_melee_velocity", secondary_controller_melee_velocity)
	action_map_cfg_file.set_value("MELEE", "primary_controller_melee_cooldown_secs", primary_controller_melee_cooldown_secs)
	action_map_cfg_file.set_value("MELEE", "secondary_controller_melee_cooldown_secs", secondary_controller_melee_cooldown_secs)
	action_map_cfg_file.set_value("MELEE", "primary_controller_melee_action", primary_controller_melee_action)
	action_map_cfg_file.set_value("MELEE", "secondary_controller_melee_action", secondary_controller_melee_action)

	# Save config file
	err = action_map_cfg_file.save(file_path)
	
	emit_signal("xr_game_action_map_cfg_saved", file_path)
	
	return true

func save_action_map_cfg_file(file_path):
	var action_map_cfg_file = ConfigFile.new()
	err = action_map_cfg_file.load(file_path)

	if err != OK:
		printerr("Error creating action map config file!  Error: ", err)
		return false
	# Get a list of the input actions the game dev used
	var flat_screen_actions = InputMap.get_actions()

	# Only try to remap custom actions, so check if default first
	for action in flat_screen_actions:
		if not action in default_action_map_actions:
			# Get input events assigned to each action
			var game_action_events = InputMap.action_get_events(action)
			# Some actions may have multiple events assigned, set this variable to prevent overwriting valid actions with "needs mapping"
			var event_already_set_for_action = false
			for event in game_action_events:
				# If not mapped to a joypad input let user know otherwise show mapping
				if event_already_set_for_action:
					break
				if not event is InputEventJoypadButton and not event is InputEventJoypadMotion:
					action_map_cfg_file.set_value("GAME_ACTIONS", action, needs_mapping_phrase)
				elif event is InputEventJoypadButton:
					action_map_cfg_file.set_value("GAME_ACTIONS", action, default_gamepad_button_names[event.button_index])
					event_already_set_for_action = true
				elif event is InputEventJoypadMotion:
					action_map_cfg_file.set_value("GAME_ACTIONS", action, [default_joystick_axis_names[event.axis], event.axis_value])
					event_already_set_for_action = true
	
	# Now save radial menu options
	action_map_cfg_file.set_value("RADIAL_MENU_OPTIONS", "use_xr_radial_menu", use_xr_radial_menu)
	action_map_cfg_file.set_value("RADIAL_MENU_OPTIONS", "xr_radial_menu_mode", xr_radial_menu_mode)
	action_map_cfg_file.set_value("RADIAL_MENU_OPTIONS", "xr_radial_menu_entries", xr_radial_menu_entries)
	action_map_cfg_file.set_value("RADIAL_MENU_OPTIONS", "open_radial_menu_button", open_radial_menu_button)
	action_map_cfg_file.set_value("HAPTICS", "game_actions_triggering_primary_haptics", game_actions_triggering_primary_haptics)
	action_map_cfg_file.set_value("HAPTICS", "game_actions_triggering_secondary_haptics", game_actions_triggering_secondary_haptics)
	action_map_cfg_file.set_value("MELEE", "primary_controller_melee_velocity", primary_controller_melee_velocity)
	action_map_cfg_file.set_value("MELEE", "secondary_controller_melee_velocity", secondary_controller_melee_velocity)
	action_map_cfg_file.set_value("MELEE", "primary_controller_melee_cooldown_secs", primary_controller_melee_cooldown_secs)
	action_map_cfg_file.set_value("MELEE", "secondary_controller_melee_cooldown_secs", secondary_controller_melee_cooldown_secs)
	action_map_cfg_file.set_value("MELEE", "primary_controller_melee_action", primary_controller_melee_action)
	action_map_cfg_file.set_value("MELEE", "secondary_controller_melee_action", secondary_controller_melee_action)

	# Save config file
	err = action_map_cfg_file.save(file_path)
	
	emit_signal("xr_game_action_map_cfg_saved", file_path)
	
	return true

func load_action_map_file(file_path: String) -> bool:
	print("Loading user config action map file")
	var action_map_cfg_file = ConfigFile.new()
	err = action_map_cfg_file.load(file_path)

	if err != OK:
		printerr("Error loading action map config file: ", err)
		return false

	var game_action_events = InputMap.get_actions()

	for action in game_action_events:
		if action_map_cfg_file.has_section_key("GAME_ACTIONS", action):
			var value = action_map_cfg_file.get_value("GAME_ACTIONS", action)
			if typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME:
				# Button mapping
				var button_index = default_gamepad_button_names.find(value)
				if button_index != -1:
					# If we have a valid button to assign, check whether there are already joypad events assigned to this action,and if so, delete them to avoid conflicting inputs
					for original_event in InputMap.action_get_events(action):
						if original_event.is_class("InputEventJoypadButton") or original_event.is_class("InputEventJoypadMotion"):
							print("Original action map had joypad event assigned, deleting for new event")
							InputMap.action_erase_event(action, original_event)
					# Now add our new joypad event
					var event = InputEventJoypadButton.new()
					event.button_index = button_index
					InputMap.action_add_event(action, event)

			elif typeof(value) == TYPE_ARRAY:
				if value.size() != 2:
					printerr("Array used for action map for action is wrong size!", action, value)
					continue
				# Axis mapping
				var axis_name = value[0]
				var axis_value = value[1]
				var axis_index = default_joystick_axis_names.find(axis_name)
				if axis_index != -1:
					# If we have a valid input to assign, check whether there are already joypad events assigned to this action,and if so, delete them to avoid conflicting inputs
					for original_event in InputMap.action_get_events(action):
						if original_event.is_class("InputEventJoypadButton") or original_event.is_class("InputEventJoypadMotion"):
							print("Original action map had joypad event assigned, deleting for new event")
							InputMap.action_erase_event(action, original_event)
					# Now add our fresh joypad event
					var event = InputEventJoypadMotion.new()
					event.axis = axis_index
					event.axis_value = axis_value
					#event.deadzone = 0.1
					InputMap.action_add_event(action, event)
			else:
				printerr("Error in user action map config file - value is not recognized: ", value)

	# Now load radial menu options
	use_xr_radial_menu = action_map_cfg_file.get_value("RADIAL_MENU_OPTIONS", "use_xr_radial_menu", use_xr_radial_menu)
	xr_radial_menu_mode = action_map_cfg_file.get_value("RADIAL_MENU_OPTIONS", "xr_radial_menu_mode", xr_radial_menu_mode)
	xr_radial_menu_entries = action_map_cfg_file.get_value("RADIAL_MENU_OPTIONS", "xr_radial_menu_entries", xr_radial_menu_entries)
	open_radial_menu_button = action_map_cfg_file.get_value("RADIAL_MENU_OPTIONS", "open_radial_menu_button", open_radial_menu_button)
	
	# Now load haptics and melee options
	game_actions_triggering_primary_haptics = action_map_cfg_file.get_value("HAPTICS", "game_actions_triggering_primary_haptics", game_actions_triggering_primary_haptics)
	game_actions_triggering_secondary_haptics = action_map_cfg_file.get_value("HAPTICS", "game_actions_triggering_secondary_haptics", game_actions_triggering_secondary_haptics)
	primary_controller_melee_velocity = action_map_cfg_file.get_value("MELEE", "primary_controller_melee_velocity", primary_controller_melee_velocity)
	secondary_controller_melee_velocity = action_map_cfg_file.get_value("MELEE", "secondary_controller_melee_velocity", secondary_controller_melee_velocity)
	primary_controller_melee_cooldown_secs = action_map_cfg_file.get_value("MELEE", "primary_controller_melee_cooldown_secs", primary_controller_melee_cooldown_secs)
	secondary_controller_melee_cooldown_secs = action_map_cfg_file.get_value("MELEE", "secondary_controller_melee_cooldown_secs", secondary_controller_melee_cooldown_secs)
	primary_controller_melee_action = action_map_cfg_file.get_value("MELEE", "primary_controller_melee_action", primary_controller_melee_action)
	secondary_controller_melee_action = action_map_cfg_file.get_value("MELEE", "secondary_controller_melee_action", secondary_controller_melee_action)

	emit_signal("xr_game_action_map_cfg_loaded", file_path)
	
	print("finished loading action map")
	
	return true

func save_game_control_map_cfg_file(file_path):
	var game_control_map_cfg_file = ConfigFile.new()
	err = game_control_map_cfg_file.load(file_path)

	if err != OK:
		printerr("Error saving game control map config: ", err)
		return

	# Set primary control map buttons

	for key in primary_action_map:	
		game_control_map_cfg_file.set_value("PRIMARY_CONTROLLER", key, default_gamepad_button_names[primary_action_map[key]])

	# Set secondary control map buttons
	
	for key in secondary_action_map:
		game_control_map_cfg_file.set_value("SECONDARY_CONTROLLER", key, default_gamepad_button_names[secondary_action_map[key]])

	# Set mouse emulation options
	
	game_control_map_cfg_file.set_value("MOUSE_EMULATION_OPTIONS", "stick_emulate_mouse_movement", stick_emulate_mouse_movement)
	
	game_control_map_cfg_file.set_value("MOUSE_EMULATION_OPTIONS", "head_emulate_mouse_movement", head_emulate_mouse_movement)
	
	game_control_map_cfg_file.set_value("MOUSE_EMULATION_OPTIONS", "primary_controller_emulate_mouse_movement", primary_controller_emulate_mouse_movement)
	
	game_control_map_cfg_file.set_value("MOUSE_EMULATION_OPTIONS", "secondary_controller_emulate_mouse_movement", secondary_controller_emulate_mouse_movement)
	
	game_control_map_cfg_file.set_value("MOUSE_EMULATION_OPTIONS", "emulated_mouse_sensitivity_multiplier", emulated_mouse_sensitivity_multiplier)
	
	game_control_map_cfg_file.set_value("MOUSE_EMULATION_OPTIONS", "emulated_mouse_deadzone", emulated_mouse_deadzone)
	
	# Set other control options
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "turning_type", turning_type)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "turning_speed", turning_speed)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "turning_degrees", turning_degrees)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "stick_turn_controller", stick_turn_controller)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "grip_deadzone", grip_deadzone)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "primary_controller_selection", primary_controller_selection)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "ugvr_menu_toggle_combo", ugvr_menu_toggle_combo)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "pointer_gesture_toggle_button", pointer_gesture_toggle_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "gesture_load_action_map_button", gesture_load_action_map_button) 
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "gesture_set_user_height_button", gesture_set_user_height_button)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "dpad_activation_button", dpad_activation_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "start_button", start_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "select_button", select_button)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "use_physical_gamepad_only", use_physical_gamepad_only)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "use_motion_sickness_vignette", use_motion_sickness_vignette)

	err = game_control_map_cfg_file.save(file_path)

	emit_signal("xr_game_control_map_cfg_saved", file_path)
	
	return true

func load_game_control_map_cfg_file(file_path: String) -> bool:
	var game_control_map_cfg_file = ConfigFile.new()
	err = game_control_map_cfg_file.load(file_path)

	if err != OK:
		printerr("Error loading game control map config: ", err)
		return false

	# Load primary controller mappings
	for key in primary_action_map.keys():
		if game_control_map_cfg_file.has_section_key("PRIMARY_CONTROLLER", key):
			var button_name = game_control_map_cfg_file.get_value("PRIMARY_CONTROLLER", key)
			var button_index = default_gamepad_button_names.find(button_name)
			if button_index != -1:
				primary_action_map[key] = button_index
			else:	
				printerr("Primary controller button mapping error, assigned key not recognized: ", button_name)

	# Load secondary controller mappings
	for key in secondary_action_map.keys():
		if game_control_map_cfg_file.has_section_key("SECONDARY_CONTROLLER", key):
			var button_name = game_control_map_cfg_file.get_value("SECONDARY_CONTROLLER", key)
			var button_index = default_gamepad_button_names.find(button_name)
			if button_index != -1:
				secondary_action_map[key] = button_index
			else:
				printerr("Secondary controller button mapping error, assigned key not recognized: ", button_name)
	
	# Load mouse emulation options
	stick_emulate_mouse_movement = game_control_map_cfg_file.get_value("MOUSE_EMULATION_OPTIONS", "stick_emulate_mouse_movement", stick_emulate_mouse_movement)
	
	head_emulate_mouse_movement = game_control_map_cfg_file.get_value("MOUSE_EMULATION_OPTIONS", "head_emulate_mouse_movement", head_emulate_mouse_movement)
	
	primary_controller_emulate_mouse_movement = game_control_map_cfg_file.get_value("MOUSE_EMULATION_OPTIONS", "primary_controller_emulate_mouse_movement", primary_controller_emulate_mouse_movement)
	
	secondary_controller_emulate_mouse_movement = game_control_map_cfg_file.get_value("MOUSE_EMULATION_OPTIONS", "secondary_controller_emulate_mouse_movement", secondary_controller_emulate_mouse_movement)
	
	emulated_mouse_sensitivity_multiplier = game_control_map_cfg_file.get_value("MOUSE_EMULATION_OPTIONS", "emulated_mouse_sensitivity_multiplier", emulated_mouse_sensitivity_multiplier)
	
	emulated_mouse_deadzone = game_control_map_cfg_file.get_value("MOUSE_EMULATION_OPTIONS", "emulated_mouse_deadzone", emulated_mouse_deadzone)
	
	
	# Load other control options
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "turning_type"):
		turning_type = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "turning_type")
	
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "turning_speed"):
		turning_speed = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "turning_speed")
	
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "turning_degrees"):
		turning_degrees = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "turning_degrees")
	
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "stick_turn_controller"):
		stick_turn_controller = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "stick_turn_controller")
	
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "grip_deadzone"):
		grip_deadzone = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "grip_deadzone")
		
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "primary_controller_selection"):
		primary_controller_selection = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "primary_controller_selection")

	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "ugvr_menu_toggle_combo"):
		ugvr_menu_toggle_combo = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "ugvr_menu_toggle_combo")
	
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "pointer_gesture_toggle_button"):
		pointer_gesture_toggle_button = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "pointer_gesture_toggle_button")
	
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "gesture_load_action_map_button"):
		gesture_load_action_map_button = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "gesture_load_action_map_button")
	
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "gesture_set_user_height_button"):
		gesture_set_user_height_button = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "gesture_set_user_height_button")
	
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "dpad_activation_button"):
		dpad_activation_button = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "dpad_activation_button")

	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "start_button"):
		start_button = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "start_button")

	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "select_button"):
		select_button = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "select_button")
	
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "use_physical_gamepad_only"):
		use_physical_gamepad_only = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "use_physical_gamepad_only")
	
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "use_motion_sickness_vignette"):
		use_motion_sickness_vignette = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "use_motion_sickness_vignette")

	emit_signal("xr_game_control_map_cfg_loaded", file_path)
	print("xr game control map cfg loaded")
	return true


func create_game_control_map_cfg_file(file_path):
	var game_control_map_cfg_file = ConfigFile.new()
	err = game_control_map_cfg_file.load(file_path)

	if err != OK:
		printerr("Error saving game control map config: ", err)
		return
	
	# Create primary control map buttons
	for key in primary_action_map:	
		game_control_map_cfg_file.set_value("PRIMARY_CONTROLLER", key, default_gamepad_button_names[primary_action_map[key]])

	# Create secondary control map buttons
	for key in secondary_action_map:
		game_control_map_cfg_file.set_value("SECONDARY_CONTROLLER", key, default_gamepad_button_names[secondary_action_map[key]])

	# Create mouse emulation options
	game_control_map_cfg_file.set_value("MOUSE_EMULATION_OPTIONS", "stick_emulate_mouse_movement", stick_emulate_mouse_movement)
	
	game_control_map_cfg_file.set_value("MOUSE_EMULATION_OPTIONS", "head_emulate_mouse_movement", head_emulate_mouse_movement)
	
	game_control_map_cfg_file.set_value("MOUSE_EMULATION_OPTIONS", "primary_controller_emulate_mouse_movement", primary_controller_emulate_mouse_movement)
	
	game_control_map_cfg_file.set_value("MOUSE_EMULATION_OPTIONS", "secondary_controller_emulate_mouse_movement", secondary_controller_emulate_mouse_movement)
	
	game_control_map_cfg_file.set_value("MOUSE_EMULATION_OPTIONS", "emulated_mouse_sensitivity_multiplier", emulated_mouse_sensitivity_multiplier)
	
	game_control_map_cfg_file.set_value("MOUSE_EMULATION_OPTIONS", "emulated_mouse_deadzone", emulated_mouse_deadzone)
	
	# Create other control options
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "turning_type", turning_type)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "turning_speed", turning_speed)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "turning_degrees", turning_degrees)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "stick_turn_controller", stick_turn_controller)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "grip_deadzone", grip_deadzone)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "primary_controller_selection", primary_controller_selection)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "ugvr_menu_toggle_combo", ugvr_menu_toggle_combo)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "pointer_gesture_toggle_button", pointer_gesture_toggle_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "gesture_load_action_map_button", gesture_load_action_map_button)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "gesture_set_user_height_button", gesture_set_user_height_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "dpad_activation_button", dpad_activation_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "start_button", start_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "select_button", select_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "use_physical_gamepad_only", use_physical_gamepad_only)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "use_motion_sickness_vignette", use_motion_sickness_vignette)
	
	err = game_control_map_cfg_file.save(file_path)

	emit_signal("xr_game_control_map_cfg_saved", file_path)
	
	return true
