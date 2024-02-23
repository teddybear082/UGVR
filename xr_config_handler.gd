## This node handles all the saving and loading of UGVR config files for options and game action mapping
extends Node

signal xr_game_options_cfg_saved(path : String)

signal xr_game_control_map_cfg_saved(path : String)

signal xr_game_action_map_cfg_saved(path : String)

signal xr_game_options_cfg_loaded(path : String)

signal xr_game_control_map_cfg_loaded(path : String)

signal xr_game_action_map_cfg_loaded(path : String)

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

# Maybe unnecessary; maybe we always use gamepad emulation, but still might want to turn this off if someone built a more robust game-specific mod
var use_gamepad_emulation : bool = true

# Maybe just use action mapping to assign joypad binds instead of ever "emulating" keyboard?
var use_keyboard_emulation : bool = false

# Stick turning style for camera
var turning_style : TurningStyle = TurningStyle.SNAP

var ugvr_menu_toggle_combo : Dictionary = {"primary_controller" : ["primary_click"], "secondary_controller": ["primary_click"]}

var gesture_pointer_activation_button : String = "trigger_click"

var dpad_activation_button : String = "primary_touch" 

var primary_controller : String = "right"

var controller_mapping: String = "default" 

var custom_action_map : Dictionary = {}

var start_button : String = "primary_click"

var select_button : String = "by_button"

# Have to decide if these should be left/right or primary/secondary
var controller_for_dpad_activation_button : String = "right"

var controller_for_start_button : String = "left"

var controller_for_select_button : String = "left"


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

## AUTOSAVE OPTIONS
var autosave_action_map_duration_in_secs : int = 0 # Off by default


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
	else:
		var complete = load_game_options_cfg_file(game_options_cfg_path)	
	
	if not FileAccess.file_exists(game_action_map_cfg_path):
		FileAccess.open(game_action_map_cfg_path, FileAccess.WRITE)
		var complete = create_action_map_cfg_file(game_action_map_cfg_path)
	else:
		var complete = load_action_map_file(game_action_map_cfg_path)
		
	if not FileAccess.file_exists(game_control_map_cfg_path):
		FileAccess.open(game_control_map_cfg_path, FileAccess.WRITE)
		var complete = create_game_control_map_cfg_file(game_control_map_cfg_path)
	else:
		var complete = load_game_control_map_cfg_file(game_control_map_cfg_path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func load_game_options_cfg_file(file_path: String) -> bool:
	var game_options_cfg_file = ConfigFile.new()
	err = game_options_cfg_file.load(file_path)

	if err != OK:
		printerr("Error loading game options config file! Error: ", err)
		return false

	# Load camera options
	vr_world_scale = game_options_cfg_file.get_value("CAMERA_OPTIONS", "vr_world_scale", vr_world_scale)
	camera_offset = game_options_cfg_file.get_value("CAMERA_OPTIONS", "camera_offset", camera_offset)
	experimental_passthrough = game_options_cfg_file.get_value("CAMERA_OPTIONS", "experimental_passthrough", experimental_passthrough)

	# Load viewport options
	primary_viewport_location = game_options_cfg_file.get_value("VIEWPORTS_OPTIONS", "primary_viewport_location", primary_viewport_location)
	secondary_viewport_location = game_options_cfg_file.get_value("VIEWPORTS_OPTIONS", "secondary_viewport_location", secondary_viewport_location)
	primary_viewport_size_multiplier = game_options_cfg_file.get_value("VIEWPORTS_OPTIONS", "primary_viewport_size_multiplier", primary_viewport_size_multiplier)
	secondary_viewport_size_multiplier = game_options_cfg_file.get_value("VIEWPORTS_OPTIONS", "secondary_viewport_size_multiplier", secondary_viewport_size_multiplier)
	primary_viewport_offset = game_options_cfg_file.get_value("VIEWPORTS_OPTIONS", "primary_viewport_offset", primary_viewport_offset)
	secondary_viewport_offset = game_options_cfg_file.get_value("VIEWPORTS_OPTIONS", "secondary_viewport_offset", secondary_viewport_offset)

	# Load autosave options
	autosave_action_map_duration_in_secs = game_options_cfg_file.get_value("AUTOSAVE_OPTIONS", "autosave_action_map_duration_in_secs", autosave_action_map_duration_in_secs)
	
	emit_signal("xr_game_options_cfg_loaded", file_path)
	print("Xr game options config loaded")
	return true


func save_game_options_cfg_file(file_path):
	var game_options_cfg_file = ConfigFile.new()
	err = game_options_cfg_file.load(file_path)

	if err != OK:
		printerr("Error saving game options config file!  Error: ", err)
		return false

	game_options_cfg_file.set_value("CAMERA_OPTIONS", "vr_world_scale", vr_world_scale)

	game_options_cfg_file.set_value("CAMERA_OPTIONS", "camera_offset", camera_offset)

	game_options_cfg_file.set_value("CAMERA_OPTIONS", "experimental_passthrough", experimental_passthrough)

	game_options_cfg_file.set_value("VIEWPORTS_OPTIONS", "primary_viewport_location", primary_viewport_location)

	game_options_cfg_file.set_value("VIEWPORTS_OPTIONS", "secondary_viewport_location", secondary_viewport_location)

	game_options_cfg_file.set_value("VIEWPORTS_OPTIONS", "primary_viewport_size_multiplier", primary_viewport_size_multiplier)

	game_options_cfg_file.set_value("VIEWPORTS_OPTIONS", "secondary_viewport_size_multiplier", secondary_viewport_size_multiplier)

	game_options_cfg_file.set_value("VIEWPORTS_OPTIONS", "primary_viewport_offset", primary_viewport_offset)

	game_options_cfg_file.set_value("VIEWPORTS_OPTIONS", "secondary_viewport_offset", secondary_viewport_offset)

	game_options_cfg_file.set_value("AUTOSAVE_OPTIONS", "autosave_action_map_duration_in_secs", autosave_action_map_duration_in_secs)
	
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

	emit_signal("xr_game_action_map_cfg_loaded", file_path)
	
	print("finished loading action map")
	
	return true

func save_game_control_map_cfg_file(file_path):
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

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "ugvr_menu_toggle_combo", ugvr_menu_toggle_combo)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "gesture_pointer_activation_button", gesture_pointer_activation_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "controller_for_dpad_activation_button", controller_for_dpad_activation_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "dpad_activation_button", dpad_activation_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "controller_for_start_button", controller_for_start_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "start_button", start_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "controller_for_select_button", controller_for_select_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "select_button", select_button)

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
			# Need to set analogue values for triggers and sticks separately
			elif button_name == "Joypad RightTrigger" and key != "thumbstick":
				pass
			elif button_name == "Joypad LeftTrigger" and key != "thumbstick":
				pass
			elif button_name == "Joypad RightStick" and key == "thumbstick":
				pass
			elif button_name == "Joypad LeftStick" and key == "thumbstick":
				pass
			else:	
				printerr("Primary controller button mapping error, assigned key not recognized: ", button_name)

	# Load secondary controller mappings
	for key in secondary_action_map.keys():
		if game_control_map_cfg_file.has_section_key("SECONDARY_CONTROLLER", key):
			var button_name = game_control_map_cfg_file.get_value("SECONDARY_CONTROLLER", key)
			var button_index = default_gamepad_button_names.find(button_name)
			if button_index != -1:
				secondary_action_map[key] = button_index
			# Need to set analogue values for triggers and sticks separately
			elif button_name == "Joypad RightTrigger" and key != "thumbstick":
				pass
			elif button_name == "Joypad LeftTrigger" and key != "thumbstick":
				pass
			elif button_name == "Joypad RightStick" and key == "thumbstick":
				pass
			elif button_name == "Joypad LeftStick" and key == "thumbstick":
				pass
			else:
				printerr("Secondary controller button mapping error, assigned key not recognized: ", button_name)
	
	# Load other control options
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "turning_style"):
		turning_style = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "turning_style")

	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "primary_controller"):
		primary_controller = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "primary_controller")

	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "ugvr_menu_toggle_combo"):
		ugvr_menu_toggle_combo = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "ugvr_menu_toggle_combo")
	
	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "gesture_pointer_activation_button"):
		gesture_pointer_activation_button = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "gesture_pointer_activation_button")

	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "controller_for_dpad_activation_button"):
		controller_for_dpad_activation_button = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "controller_for_dpad_activation_button")

	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "dpad_activation_button"):
		dpad_activation_button = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "dpad_activation_button")

	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "controller_for_start_button"):
		controller_for_start_button = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "controller_for_start_button")

	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "start_button"):
		start_button = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "start_button")

	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "controller_for_select_button"):
		controller_for_select_button = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "controller_for_select_button")

	if game_control_map_cfg_file.has_section_key("OTHER_CONTROL_OPTIONS", "select_button"):
		select_button = game_control_map_cfg_file.get_value("OTHER_CONTROL_OPTIONS", "select_button")

	emit_signal("xr_game_control_map_cfg_loaded", file_path)
	print("xr game control map cfg loaded")
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

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "ugvr_menu_toggle_combo", ugvr_menu_toggle_combo)
	
	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "gesture_pointer_activation_button", gesture_pointer_activation_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "controller_for_dpad_activation_button", controller_for_dpad_activation_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "dpad_activation_button", dpad_activation_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "controller_for_start_button", controller_for_start_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "start_button", start_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "controller_for_select_button", controller_for_select_button)

	game_control_map_cfg_file.set_value("OTHER_CONTROL_OPTIONS", "select_button", select_button)

	err = game_control_map_cfg_file.save(file_path)

	emit_signal("xr_game_control_map_cfg_saved", file_path)
	
	return true
