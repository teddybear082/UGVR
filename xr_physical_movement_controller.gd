# Provides experimental support for alternative physical movement options to trigger game actions
# Code adapted from Godot XR Tools

## XR Tools Movement Provider for Jog Movement
##
## This script provides jog-in-place movement for the player. This script
## works with the [XRToolsPlayerBody] attached to the players [XROrigin3D].
##
## The implementation uses filtering of the controller Y velocities to measure
## the approximate frequency of jog arm-swings; and uses that to
## switch between stopped, slow, and fast movement speeds.
#https://github.com/GodotVR/godot-xr-tools/blob/master/addons/godot-xr-tools/functions/movement_jog.gd

## XR Tools Movement Provider for Player Physical Jump Detection
##
## This script can detect jumping based on either the players body jumping,
## or by the player swinging their arms up.
##
## The player body jumping is detected by putting the cameras instantaneous
## Y velocity (in the tracking space) into a sliding-window averager. If the
## average Y velocity exceeds a threshold parameter then the player has
## jumped.
##
## The player arms jumping is detected by putting both controllers instantaneous
## Y velocity (in the tracking space) into a sliding-window averager. If both
## average Y velocities exceed a threshold parameter then the player has
## jumped.
#https://github.com/GodotVR/godot-xr-tools/blob/master/addons/godot-xr-tools/functions/movement_physical_jump.gd

extends Node

## Speed mode enumeration
enum SpeedMode {
	STOPPED,	## Not jogging
	SLOW,		## Jogging slowly
	FAST		## Jogging fast
}

## Jog arm-swing frequency in Hz to trigger slow movement
const JOG_SLOW_FREQ := 3.5

## Jog arm-swing frequency in Hz to trigger fast movement
const JOG_FAST_FREQ := 5.5

## Slow jogging speed in simulated joystick move distance
var slow_speed : float = -0.4

## Fast jogging speed in simulated joystick move distance
var fast_speed : float = -1.0


# Jog arm-swing "stroke" detector "confidence-hat" signal
var _conf_hat := 0.0

# Current jog arm-swing "stroke" duration
var _current_stroke := 0.0

# Last jog arm-swing "stroke" total duration
var _last_stroke := 0.0

# Current jog-speed mode
var _speed_mode := SpeedMode.STOPPED

# XR Origin node
var xr_origin_3D : XROrigin3D = null

# XR Camera node
var xr_camera_3D : XRCamera3D = null

# Primary controller
var primary_controller : XRController3D = null

# Secondary controller
var secondary_controller : XRController3D = null

# Input event for simulated joystick motion
var joypad_left_y_axis : InputEventJoypadMotion = InputEventJoypadMotion.new()

# Variable to determine whether jog movement enabled
var jog_enabled : bool = false

# Variable to determine if arm swing jog should also try to trigger a sprint action
var jog_triggers_sprint : bool = false

# Variable to determine whether arm swing jump movement enabled
var arm_swing_jump_enabled : bool = false

# Sprint action event variable
var sprint_action : InputEventJoypadButton = null

# Track whether currently sprinting
var physically_sprinting : bool = false

# Arms jump detection threshold (M/S^2)
var arms_jump_threshold : float = 5.0

# Node Positions for Arm Swing Jump
var _xr_camera_3D_position : float = 0.0
var _secondary_controller_position : float = 0.0
var _primary_controller_position : float = 0.0

# Node Velocities for Arm Swing Jump
var _xr_camera_3D_velocity : SlidingAverage = SlidingAverage.new(5)
var _secondary_controller_velocity : SlidingAverage = SlidingAverage.new(5)
var _primary_controller_velocity : SlidingAverage = SlidingAverage.new(5)

# Jump action event variable
var jump_action : InputEventJoypadButton = null

# Determing if already jumping
var physically_jumping : bool = false

# Sliding Average class
class SlidingAverage:
	# Sliding window size
	var _size: int

	# Sum of items in the window
	var _sum := 0.0

	# Position
	var _pos := 0

	# Data window
	var _data := Array()

	# Constructor
	func _init(size: int):
		# Set the size and fill the array
		_size = size
		for i in size:
			_data.push_back(0.0)

	# Update the average
	func update(entry: float) -> float:
		# Add the new entry and subtract the old
		_sum += entry
		_sum -= _data[_pos]

		# Store the new entry in the array and circularly advance the index
		_data[_pos] = entry;
		_pos = (_pos + 1) % _size

		# Return the average
		return _sum / _size

func _ready():
	set_process(false)

# Detect jog movement and arm jump movement if enabled
func physics_movement(delta: float):
	# Skip if the either controller is inactive
	if !primary_controller.get_is_active() or !secondary_controller.get_is_active():
		_speed_mode = SpeedMode.STOPPED
		return
	
	# If jog movement enabled, perform calculations
	if jog_enabled:
		# Get the arm-swing stroke frequency in Hz
		var freq := _get_stroke_frequency(delta)

		# Transition between stopped/slow/fast speed-modes based on thresholds.
		# This thresholding has some hysteresis to make speed changes smoother.
		if freq == 0:
			_speed_mode = SpeedMode.STOPPED
		elif freq < JOG_SLOW_FREQ:
			_speed_mode = min(_speed_mode, SpeedMode.SLOW)
		elif freq < JOG_FAST_FREQ:
			_speed_mode = max(_speed_mode, SpeedMode.SLOW)
		else:
			_speed_mode = SpeedMode.FAST

		# Pick the speed in meters-per-second based on the current speed-mode.
		var speed := 0.0
		if _speed_mode == SpeedMode.SLOW:
			print("slow speed detected")
			speed = slow_speed
			if physically_sprinting:
				sprint_action.pressed = false
				Input.parse_input_event(sprint_action)
				physically_sprinting = false
		elif _speed_mode == SpeedMode.FAST:
			print("fast speed detected")
			speed = fast_speed
			if sprint_action != null and physically_sprinting == false:
				sprint_action.pressed = true
				Input.parse_input_event(sprint_action)
				physically_sprinting = true
		elif _speed_mode == SpeedMode.STOPPED:
			if physically_sprinting:
				sprint_action.pressed = false
				Input.parse_input_event(sprint_action)
				physically_sprinting = false

		# Trigger simulated input event
		joypad_left_y_axis.axis = JOY_AXIS_LEFT_Y
		joypad_left_y_axis.axis_value = clamp(-secondary_controller.get_vector2("primary").y + speed, -1.0, 1.0)
		Input.parse_input_event(joypad_left_y_axis)
		
	
	# If arm swing jump enabled, perform calculations
	if arm_swing_jump_enabled:
		_detect_arms_jump(delta)
		
# Get the frequency of the last arm-swing "stroke" in Hz.
func _get_stroke_frequency(delta : float) -> float:
	# Get the controller velocities
	var vl = secondary_controller.get_pose().linear_velocity.y
	var vr = primary_controller.get_pose().linear_velocity.y

	# Calculate the arm-swing "stroke" confidence. This is done by multiplying
	# the left and right controller vertical velocities. As these velocities
	# are highly anti-correlated while "jogging" the result is a confidence
	# signal with a high "peak" on every jog "stroke".
	var conf = vl * -vr

	# Test for the confidence valley between strokes. This is used to signal
	# when to measure the duration between strokes.
	var valley = conf < _conf_hat

	# Update confidence-hat. The confidence-hat signal has a fast-rise and
	# slow-decay. Rising with each jog arm-swing "stroke" and then taking time
	# to decay. The magnitude of the "confidence-hat" can be used as a good
	# indicator of when the user is jogging; and the difference between the
	# "confidence" and "confidence-hat" signals can be used to identify the
	# duration of a jog arm-swing "stroke".
	if valley:
		# Gently decay when in the confidence valley.
		_conf_hat = lerpf(_conf_hat, 0.0, delta * 2)
	else:
		# Quickly ramp confidence-hat to confidence
		_conf_hat = lerpf(_conf_hat, conf, delta * 20)

	# If the "confidence-hat" signal is too low then the user is not jogging.
	# The stroke date-data is cleared and a stroke frequency of 0Hz is returned.
	if _conf_hat < 0.5:
		_current_stroke = 0.0
		_last_stroke = 0.0
		return 0.0

	# Track the jog arm-swing "stroke" duration.
	if valley:
		# In the valley between jog arm-swing "strokes"
		_current_stroke += delta
	elif _current_stroke > 0.1:
		# Save the measured jog arm-swing "stroke" duration.
		_last_stroke = _current_stroke
		_current_stroke = 0.0

	# If no previous jog arm-swing "stroke" duration to report, so return 0Hz.
	if _last_stroke < 0.1:
		return 0.0

	# If the current jog arm-swing "stroke" is taking longer (slower) than 2Hz
	# then truncate to 0Hz.
	if _current_stroke > 0.75:
		return 0.0

	# Return the last jog arm-swing "stroke" in Hz.
	return 1.0 / _last_stroke
	
# Function used to detect arm swing jump movement
func _detect_arms_jump(delta):
	# Skip if either of the controllers is disabled
	if !primary_controller.get_is_active() or !secondary_controller.get_is_active():
		return
	
	# Skip if we don't have a jump action to trigger
	if jump_action == null:
		return

	# Get the controllers instantaneous velocity
	var new_controller_secondary_pos = secondary_controller.transform.origin.y
	var new_controller_primary_pos = primary_controller.transform.origin.y
	var controller_secondary_vel = (new_controller_secondary_pos - _secondary_controller_position) / delta
	var controller_primary_vel = (new_controller_primary_pos - _primary_controller_position) / delta
	_secondary_controller_position = new_controller_secondary_pos
	_primary_controller_position = new_controller_primary_pos

	# Ignore zero moves (either not tracking, or no update since last physics)
	if abs(controller_secondary_vel) <= 0.001 and abs(controller_primary_vel) <= 0.001:
		return

	# Correct for world-scale (convert to player units)
	controller_secondary_vel /= XRServer.world_scale
	controller_primary_vel /= XRServer.world_scale

	# Clamp the controller instantaneous velocity to +/- 2x the jump threshold
	controller_secondary_vel = clamp(
			controller_secondary_vel,
			-2.0 * arms_jump_threshold,
			2.0 * arms_jump_threshold)
	controller_primary_vel = clamp(
			controller_primary_vel,
			-2.0 * arms_jump_threshold,
			2.0 * arms_jump_threshold)

	# Get the averaged velocity
	controller_secondary_vel = _secondary_controller_velocity.update(controller_secondary_vel)
	controller_primary_vel = _primary_controller_velocity.update(controller_primary_vel)

	# Detect a jump
	if controller_secondary_vel >= arms_jump_threshold and controller_primary_vel >= arms_jump_threshold:
		print("jump detected!")
		jump_action.pressed = true
		Input.parse_input_event(jump_action)
		physically_jumping = true
	# If no jump detected and were already jumping with arm swing, reset state
	elif physically_jumping:
		jump_action.pressed = false
		Input.parse_input_event(jump_action)
		physically_jumping = false

func detect_game_jump_action_events():
	var game_actions = InputMap.get_actions()

	for action in game_actions:
		if action.to_lower() == "jump":
			var action_events = InputMap.action_get_events(action)
			for action_event in action_events:
				if action_event.is_class("InputEventJoypadButton"):
					jump_action = action_event
		if jump_action == null and action.to_lower().contains("jump"):
			var action_events = InputMap.action_get_events(action)
			for action_event in action_events:
				if action_event.is_class("InputEventJoypadButton"):
					jump_action = action_event
	if jump_action == null:
		print("No jump action found in physical movement controller")
	else:
		print("Jump action found in physical movement controller")

func detect_game_sprint_events():
	if jog_triggers_sprint == false:
		return
	
	var game_actions = InputMap.get_actions()
	
	for action in game_actions:
		if action.to_lower() == "sprint":
			var action_events = InputMap.action_get_events(action)
			for action_event in action_events:
				if action_event.is_class("InputEventJoypadButton"):
					sprint_action = action_event
		if sprint_action == null and action.to_lower().contains("sprint"):
			var action_events = InputMap.action_get_events(action)
			for action_event in action_events:
				if action_event.is_class("InputEventJoypadButton"):
					sprint_action = action_event
	if sprint_action == null:
		print("No sprint action found in physical movement controller")
	else:
		print("Sprint action found in physical movement controller")

func set_enabled(jog_value: bool, jump_value: bool, pri_controller : XRController3D, sec_controller : XRController3D, use_jog_for_sprint : bool):
	jog_enabled = jog_value
	print("Jog enabled: ", jog_enabled)
	arm_swing_jump_enabled = jump_value
	print("Arm swing enabled: ", arm_swing_jump_enabled)
	primary_controller = pri_controller
	secondary_controller = sec_controller
	if jog_enabled or arm_swing_jump_enabled:
		set_process(true)
	else:
		set_process(false)
	if arm_swing_jump_enabled:
		detect_game_jump_action_events()
	if jog_enabled:
		jog_triggers_sprint = use_jog_for_sprint
		detect_game_sprint_events()

func _process(delta):
	if !is_instance_valid(primary_controller) or !is_instance_valid(secondary_controller):
		_speed_mode = SpeedMode.STOPPED
		return
		
	physics_movement(delta)
