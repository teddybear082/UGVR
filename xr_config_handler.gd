extends Node

## This node handles all the saving and loading of UGVR config files for options and game action mapping



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

#If custom mapping:
#Set click events to buttons mapped by user

#if keyboard+mouse- trigger keyboard / mouse input? How to distinguish? Use special API?  Depends on how ConfigFile parses values


## CAMERA Config Options

var vr_world_scale : float = 1.0

var camera_offset : Vector3 = Vector3(0,0,0)

var experimental_passthrough : bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func load_config_file(file_path):
	pass
	
	
func save_config_file(file_path):
	pass


func create_action_input_map_file(file_path):
	pass
	#var flat_screen_actions = InputMap.get_actions()
	#for action in flat_screen_actions:
		#var action_events = InputMap.action_get_events(action)
		#print("Action: ", action, " Events: ", action_events)
		#for event in action_events:
			#if event is InputEventJoypadButton:
				#print(event)
	
func load_action_input_map_file(file_path):
	pass
