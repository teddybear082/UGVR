extends Node3D

signal activated(node: Node3D, new_value: Variant)

@export var setting_name : String = "SettingName"
@export var options: Array = []  # List of options
@export var current_value_index: int = 0  # Tracks the index of the current value
@export var active_color: Color = Color(0.529, 0.808, 0.98)  # light blue
@export var deactivated_color: Color = Color(0.8, 0.8, 0.8)  # light gray

var current_value: Variant
var input_timer: Timer
var update_allowed: bool = true

func _ready():
	update_label()
	$Area3D.area_entered.connect(_on_area3d_entered)
	$Area3D.area_exited.connect(_on_area3d_exited)

	# Initialize the timer to stop repeated accidental inputs
	input_timer = Timer.new()
	input_timer.wait_time = 1.0  # Wait for 1 second
	input_timer.one_shot = true    # Only run once
	input_timer.timeout.connect(_on_input_timer_timeout)
	add_child(input_timer)

func update_label():
	if is_valid_index(current_value_index):
		current_value = options[current_value_index]
		$SettingNameLabel3D.text = str(setting_name)
		$SettingValueLabel3D.text = str(current_value)
		update_color()

func update_color():
	if typeof(current_value) == TYPE_BOOL:
		$SettingValueLabel3D.modulate = active_color if current_value else deactivated_color

func activate():
	if is_valid_index(current_value_index):
		current_value_index = (current_value_index + 1) % options.size()
		emit_signal("activated", self, options[current_value_index])
		update_label()

func is_valid_index(index: int) -> bool:
	return index >= 0 and index < options.size()

# Getter for current value
func get_current_value() -> Variant:
	return current_value

func set_setting_name(new_name : String):
	setting_name = new_name
	update_label()

# Setter for current value (useful when setting from other scripts)
func set_current_value(index: int):
	if is_valid_index(index):
		current_value_index = index
		update_label()

func set_available_options(new_setting_name : String, new_options: Array, active_index: int = 0):
	setting_name = new_setting_name
	options = new_options
	if is_valid_index(active_index):
		current_value_index = active_index
	else:
		current_value_index = 0  # Reset to 0 if the index is not valid
	update_label()  # Update the label with the new current value

func _on_area3d_entered(area: Area3D):
	if !update_allowed:
		return
	update_allowed = false
	activate()  # Trigger the activate function

func _on_area3d_exited(area: Area3D):
	if !update_allowed:
		input_timer.start()  # Start the timer to prevent rapid input

func _on_input_timer_timeout():
	update_allowed = true
