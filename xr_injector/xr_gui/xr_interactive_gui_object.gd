extends Node3D
signal activated(node: Node3D, new_value: Variant)

@export var setting_name : String = "SettingName"
@export var options: Array = []  # List of options
@export var current_value_index: int = 0  # Tracks the index of the current value
@export var activation_button: String = "trigger_click"
@onready var area3D: Area3D = get_node("Area3D")
var current_value: Variant
var update_allowed: bool = false
var active_color_material: StandardMaterial3D = StandardMaterial3D.new()
var deactivated_color_material: StandardMaterial3D = StandardMaterial3D.new()
var selected_color_material: StandardMaterial3D = StandardMaterial3D.new()
var already_activating = false

func _ready():
	# Subscribe to pointer events
	area3D.pointer_event.connect(_on_pointer_event)
	
	# Set label colors and text
	update_label()
	
	# Setup trigger area signals
	$Area3D.area_entered.connect(_on_area3d_entered)
	$Area3D.area_exited.connect(_on_area3d_exited)
	
	# Set up materials for different statuses
	for material in [active_color_material, deactivated_color_material, selected_color_material]:
		material.disable_ambient_light = true
		material.disable_receive_shadows = true
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		#material.no_depth_test = true
		#material.render_priority = 1
	deactivated_color_material.albedo_color = Color.LIGHT_GRAY
	active_color_material.albedo_color = Color.LIGHT_BLUE
	selected_color_material.albedo_color = Color.LIGHT_GOLDENROD
	
func update_label():
	if is_valid_index(current_value_index):
		current_value = options[current_value_index]
		$SettingNameLabel3D.text = str(setting_name)
		$SettingValueLabel3D.text = str(current_value)
		update_color()

func update_color():
	if typeof(current_value) == TYPE_BOOL:
		$Area3D/MeshInstance3D.set_surface_override_material(0, active_color_material if current_value else deactivated_color_material)
	else:
		$Area3D/MeshInstance3D.set_surface_override_material(0, deactivated_color_material)

# Select next available option
func activate():
	if not already_activating:
		already_activating = true
		if is_valid_index(current_value_index):
			current_value_index = (current_value_index + 1) % options.size()
			emit_signal("activated", self, options[current_value_index])
			update_label()
		already_activating = false

# Check if selection is valid
func is_valid_index(index: int) -> bool:
	return index >= 0 and index < options.size()

# Getter for current value
func get_current_value() -> Variant:
	return current_value

# Include title for setting
func set_setting_name(new_name : String):
	setting_name = new_name
	update_label()

# Setter for current value (useful when setting from other scripts)
func set_current_value(index: int):
	if is_valid_index(index):
		current_value_index = index
		update_label()

# Set settings controlled by button
func set_available_options(new_setting_name : String, new_options: Array, active_index: int = 0):
	setting_name = new_setting_name
	options = new_options
	if is_valid_index(active_index):
		current_value_index = active_index
	else:
		current_value_index = 0  # Reset to 0 if the index is not valid
	update_label()  # Update the label with the new current value

# Allow setting to be changed if controller is inside activation area
func _on_area3d_entered(area: Area3D):
	update_allowed = true
	$Area3D/MeshInstance3D.set_surface_override_material(0, selected_color_material)

# If hand leaves activation area dont allow changing of setting
func _on_area3d_exited(area: Area3D):
	update_allowed = false
	update_color()
	
# If controller is imside activation zone and button pressed, trigger setting
func _on_xr_controller_button_pressed(button_name):
	# If not visible there's no way we want to trigger a setting change, so don't
	if !self.visible or !get_parent().visible:
		return
	if button_name == activation_button and update_allowed and not already_activating:
		activate()

# Pointer event handler
func _on_pointer_event(event) -> void:
	# Get the pointer, event type, and button type
	var type = event.event_type
	if type == 2 and not already_activating: # This is the XRToolsPointerEventType.PRESSED enum value
		activate()
	elif type == 0: # This is the XRToolsPointerEventType.ENTERED
		$Area3D/MeshInstance3D.set_surface_override_material(0, selected_color_material)
	elif type == 1: # This is the XRToolsPointerEventType.EXITED
		update_color()
		
