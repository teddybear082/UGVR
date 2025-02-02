extends Node3D

signal setting_changed(setting_name: String, setting_value: Variant)

var active_xr_controller : XRController3D

var interactive_gui_object_scene = preload("res://xr_injector/xr_gui/xr_interactive_gui_object.tscn")

# This should be set by UGVR code
var settings_to_populate : Array 
# Format expected is as follows: 
#[
	#{
	#	"setting_name": "snap_turn",
	#	"options": [true, false],
	#	"active_index": 0
	#},
	#{
	#	"setting_name": "primary_controller",
	#	"options": ["left", "right"],
	#	"active_index": 1
	#},
#]

func _ready():
	#populate_gui_menu(settings_to_populate) # Test purposes only
	# Set as top level so menu can pop into correct position when required
	self.set_as_top_level(true)
	var label_child : Label3D = Label3D.new()
	label_child.pixel_size = 0.0001
	label_child.font_size = 256
	label_child.outline_size = 64
	label_child.text = "Hold Primary Controller In Box + Trigger To Change Options"
	add_child(label_child)
	

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
		
		# Connect active xr controller to gui onject
		connect_xr_controller_to_interactive_gui_object(active_xr_controller, interactive_gui_object)
		
func set_settings_to_populate(new_settings: Array):
	settings_to_populate = new_settings
	await clear_gui_options()
	
	# Recreate settings GUI
	populate_gui_menu(settings_to_populate)

func clear_gui_options():
	# Delete all previous settings boxes
	for child in get_children():
		if child is Label3D:
			continue
		else:
			child.queue_free()

func set_xr_controller(xr_controller: XRController3D):
	active_xr_controller = xr_controller
	for gui_object in get_children():
		if gui_object is Label3D:
			continue
		else:
			connect_xr_controller_to_interactive_gui_object(active_xr_controller, gui_object)

func connect_xr_controller_to_interactive_gui_object(xr_controller: XRController3D, xr_gui_object: Node3D):
	if is_instance_valid(xr_controller):
		xr_controller.button_pressed.connect(xr_gui_object._on_xr_controller_button_pressed)
	
func _on_interactive_gui_object_setting_changed(interactive_gui_object: Node3D, new_setting_value: Variant):
	emit_signal("setting_changed", interactive_gui_object.setting_name, new_setting_value)
