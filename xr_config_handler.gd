extends Node

## This node handles all the saving and loading of UGVR config files for options and game action mapping
var needs_mapping_phrase = "needs_joypad_mapping"

var default_action_map_actions = [
	"ui_accept",
	"ui_select", 
	"ui_cancel", 
	"ui_focus_next",
	"ui_focus_prev",
	"ui_left",
	"ui_right",
	"ui_up",
	"ui_down",
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

var default_gamepad_button_maps : Dictionary = {}

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
enum TurningStyle {
	SNAP = 0,
	SMOOTH = 1,
	NONE = 2
}
var use_gamepad_emulation : bool = true

# Maybe just use action mapping to assign joypad binds instead of ever "emulating" keyboard?
var use_keyboard_emulation : bool = false

var turning_style : TurningStyle = TurningStyle.SNAP

#UGVR menu toggle combo (maybe by on both?)

var gesture_pointer_activation_button : String = "trigger_click"

var dpad_activation_button : String = "primary_touch" 

var primary_controller : String = "right"

var controller_mapping: String = "default" 

var custom_action_map : Dictionary = {}

var start_button : String = "primary_click"

var select_button : String = "by_button"

var controller_for_dpad_activation_button : String = "right"

var controller_for_start_button : String = "left"

var controller_for_select_button : String = "left"

#If custom mapping:
#Set click events to buttons mapped by user

#if keyboard+mouse- trigger keyboard / mouse input? How to distinguish? Use special API?  Depends on how ConfigFile parses values


## CAMERA Config Options

var vr_world_scale : float = 1.0

var camera_offset : Vector3 = Vector3(0,0,0)

var experimental_passthrough : bool = false

##VIEWPORTS Config options
enum ViewportLocation {
	CAMERA = 0,
	PRIMARY_CONTROLLER = 1,
	SECONDARY_CONTROLLER = 2
}

var primary_viewport_location : ViewportLocation = ViewportLocation.CAMERA

var secondary_viewport_location : ViewportLocation = ViewportLocation.CAMERA

var primary_viewport_size_multiplier : float = 1.0

var secondary_viewport_size_multiplier : float = 1.0

var primary_viewport_resolution_scale_multiplier : float = 1.0

var secondary_viewport_resolution_scale_multiplier : float = 1.0

var primary_viewport_offset : Vector3 = Vector3(0,0,0)

var secondary_viewport_offset : Vector3 = Vector3(0,0,0)


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


# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Determine where to put file, then save it
	if OS.has_feature("editor"):
		cfg_base_path = "user://XRConfigs"
	else:
		cfg_base_path = OS.get_executable_path().get_base_dir() + "/XRConfigs" 
	
	game_options_cfg_path = cfg_base_path + "/" + "xr_game_options.cfg"
	game_action_map_cfg_path = cfg_base_path + "/" + "xr_game_action_map.cfg"
	game_control_map_cfg_path = cfg_base_path + "/" + "xr_game_control_map.cfg"
	
	if not DirAccess.dir_exists_absolute(cfg_base_path):
		DirAccess.make_dir_recursive_absolute(cfg_base_path)	
		
	if not FileAccess.file_exists(game_options_cfg_path):
		FileAccess.open(game_options_cfg_path, FileAccess.WRITE)
		var complete = save_game_options_cfg_file(game_options_cfg_path)	
	
	if not FileAccess.file_exists(game_action_map_cfg_path):
		FileAccess.open(game_action_map_cfg_path, FileAccess.WRITE)
		var complete = create_action_map_cfg_file(game_action_map_cfg_path)
		
	if not FileAccess.file_exists(game_control_map_cfg_path):
		FileAccess.open(game_control_map_cfg_path, FileAccess.WRITE)
		var complete = create_game_control_map_cfg_file(game_control_map_cfg_path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func load_game_options_cfg_file(file_path):
	pass
	return true
	
func save_game_options_cfg_file(file_path):
	var game_options_cfg_file = ConfigFile.new()
	err = game_options_cfg_file.load(file_path)
	
	if err != OK:
		printerr("Error saving game options config file!  Error: ", err)
		return false
	
	game_options_cfg_file.set_value("Camera_Options", "vr_world_scale", vr_world_scale)
	
	game_options_cfg_file.set_value("Camera_Options", "camera_offset", camera_offset)

	game_options_cfg_file.set_value("Camera_Options", "experimental_passthrough", experimental_passthrough)
	
	game_options_cfg_file.set_value("Viewports_Options", "primary_viewport_location", primary_viewport_location)

	game_options_cfg_file.set_value("Viewports_Options", "secondary_viewport_location", secondary_viewport_location)

	game_options_cfg_file.set_value("Viewports_Options", "primary_viewport_size_multiplier", primary_viewport_size_multiplier)

	game_options_cfg_file.set_value("Viewports_Options", "secondary_viewport_size_multiplier", secondary_viewport_size_multiplier)

	game_options_cfg_file.set_value("Viewports_Options", "primary_viewport_offset", primary_viewport_offset)

	game_options_cfg_file.set_value("Viewports_Options", "secondary_viewport_offset", secondary_viewport_offset)
	
	err = game_options_cfg_file.save(file_path)
	return true

func create_action_map_cfg_file(file_path):
	var action_map_cfg_file = ConfigFile.new()
	err = action_map_cfg_file.load(file_path)
	
	if err != OK:
		printerr("Error creating action map config file!  Error: ", err)
		return false
	
	var flat_screen_actions = InputMap.get_actions()
	for action in flat_screen_actions:
		var game_action_events = InputMap.action_get_events(action)
		for event in game_action_events:
			if not event in default_action_map_actions:
				if not event is InputEventJoypadButton and not event is InputEventJoypadMotion:
					action_map_cfg_file.set_value("GAME_ACTIONS", action, needs_mapping_phrase)
				elif event is InputEventJoypadButton:
					action_map_cfg_file.set_value("GAME_ACTIONS", action, default_gamepad_button_names[event.button_index])
				elif event is InputEventJoypadMotion:
					action_map_cfg_file.set_value("GAME_ACTIONS", action, [default_joystick_axis_names[event.axis], event.axis_value])
	err = action_map_cfg_file.save(file_path)
	return true
	
func save_action_map_cfg_file(file_path):
	pass
	return true
	
func load_action_map_file(file_path):
	pass
	return true

func save_game_control_map_cfg_file(file_path):
	pass
	return true

func load_game_control_map_cfg_file(file_path):
	pass
	return true
	
func create_game_control_map_cfg_file(file_path):
	var game_control_map_cfg_file = ConfigFile.new()
	err = game_control_map_cfg_file.load(file_path)
	
	if err != OK:
		printerr("Error saving game control map config: ", err)
		return
	
	for key in primary_action_map:	
		game_control_map_cfg_file.set_value("PRIMARY_CONTROLLER", key, default_gamepad_button_names[primary_action_map[key]])
	
	game_control_map_cfg_file.set_value("PRIMARY_CONTROLLER", "trigger", "Joypad RightTrigger")
	
	game_control_map_cfg_file.set_value("PRIMARY_CONTROLLER", "thumbstick", "Joypad RightStick")
	
	for key in secondary_action_map:
		game_control_map_cfg_file.set_value("SECONDARY_CONTROLLER", key, default_gamepad_button_names[secondary_action_map[key]])
	
	game_control_map_cfg_file.set_value("SECONDARY_CONTROLLER", "trigger", "Joypad LeftTrigger")
	
	game_control_map_cfg_file.set_value("SECONDARY_CONTROLLER", "thumbstick", "Joypad LeftStick")
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "turning_style", turning_style)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "primary_controller", primary_controller)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "gesture_pointer_activation_button", gesture_pointer_activation_button)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "controller_for_dpad_activation_button", controller_for_dpad_activation_button)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "dpad_activation_button", dpad_activation_button)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "controller_for_start_button", controller_for_start_button)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "start_button", start_button)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "controller_for_select_button", controller_for_select_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "select_button", select_button)
	
	err = game_control_map_cfg_file.save(file_path)
	
	return true
