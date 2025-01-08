extends Node3D

signal setting_changed(setting_name: String, setting_value: Variant)

var interactive_gui_object_scene = preload("res://xr_injector/xr_gui/xr_interactive_gui_object.tscn")

# Just for testing purposes presently; this should be set by UGVR code later
var settings_to_populate : Array = [
	{
		"setting_name": "snap_turn",
		"options": [true, false],
		"active_index": 0
	},
	{
		"setting_name": "primary_controller",
		"options": ["left", "right"],
		"active_index": 1
	},
]

func _ready():
	populate_gui_menu(settings_to_populate) # Test purposes only
	pass

# Function to populate the GUI menu
func populate_gui_menu(settings: Array):
	var rows: int = ceil(sqrt(settings.size()))
	var cols: int = ceil(settings.size() / float(rows))
	
	var button_size: Vector3 = Vector3(0.3, 0.15, 0.15)  # Size of each button
	var spacing: float = 0.1  # Space between buttons

	for index in range(settings.size()):
		var setting = settings[index]
		# Creating a new InteractiveGUIObject
		var interactive_gui_object = interactive_gui_object_scene.instantiate()
		add_child(interactive_gui_object)  # Add the instantiated object as a child
		interactive_gui_object.set_available_options(setting["setting_name"], setting["options"], setting["active_index"])
		
		# Calculate position for the grid layout
		var row: int = index / cols
		var col: int = index % cols
		interactive_gui_object.transform.origin = Vector3(
			col * (button_size.x + spacing),
			row * (button_size.z + spacing),
			0
		)
		
		# Connect activated signal of each gui object to receiver function which will then connect up with config handler
		interactive_gui_object.activated.connect(_on_interactive_gui_object_setting_changed)

func set_settings_to_populate(new_settings: Array):
	settings_to_populate = new_settings
	await clear_gui_options()
	
	# Recreate settings GUI
	populate_gui_menu(settings_to_populate)

func clear_gui_options():
	# Delete all previous settings boxes
	for child in get_children():
		child.queue_free()

func _on_interactive_gui_object_setting_changed(interactive_gui_object: Node3D, new_setting_value: Variant):
	emit_signal("setting_changed", interactive_gui_object.setting_name, new_setting_value)
