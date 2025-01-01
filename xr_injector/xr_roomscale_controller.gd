# Credit to demo by Bastiaan Olij: https://github.com/godotengine/godot-demo-projects/tree/master/xr/openxr_character_centric_movement
# This script enables room scale VR movement when there is a valid characterbody3D and the user has enabled roomscale option

extends Node

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Helper variables to keep our code readable
var xr_origin_3D : XROrigin3D = null
var xr_camera_3D : XRCamera3D = null
var xr_neck_position_3D : Node3D = null
var camera_3d : Camera3D = null
var xr_controller : XRController3D = null
# Node for blacking out screen when player walks to where they should not in roomscale
var black_out : Node3D = null
# Node driving the player movement
var current_characterbody3D : CharacterBody3D = null

# Whether roomscale movement is presently enabled
var enabled : bool = false

# Whether to reverse roomscale character direction for when dev has the characterbody facing 180 degrees opposite, e.g., in Drift
var reverse_roomscale_direction : bool = false

# Height adjustment set by user if any
var roomscale_height_adjustment : float = 0.0

# Whether to use controller directed movement
var roomscale_controller_directed_movement = false

# `recenter` is called when the user has requested their view to be recentered.
# The code here assumes the player has walked into an area they shouldn't be
# and we return the player back to the character body.

func _ready():
	set_enabled(false, null)
	print("Current gravity detected in xr roomscale node is: ", gravity)
	
func recenter() -> bool:
	# Calculate where our camera should be, we start with our global transform
	var new_camera_transform : Transform3D = current_characterbody3D.global_transform

	# Set to the height of our neck joint
	new_camera_transform.origin.y = xr_neck_position_3D.global_position.y

	# Apply transform our our next position to get our desired camera transform
	new_camera_transform = new_camera_transform * xr_neck_position_3D.transform.inverse()

	# Remove tilt from camera transform
	var camera_transform : Transform3D = xr_camera_3D.transform
	var forward_dir : Vector3 = camera_transform.basis.z
	forward_dir.y = 0.0
	camera_transform = camera_transform.looking_at(camera_transform.origin + forward_dir.normalized(), Vector3.UP, true)

	# Update our XR location
	xr_origin_3D.global_transform = new_camera_transform * camera_transform.inverse()

	# Return true in case calling code needs to know when we are done (could also use a signal here, but given the speed at which this needs to be done returning true instead)
	return true

	
# `_process_on_physical_movement` handles the physical movement of the player
# adjusting our character body position to "catch up to" the player.

func _process_on_physical_movement(delta) -> bool:
	# If we don't have a current character body, current xr_origin or xr_camera, return
	if !is_instance_valid(current_characterbody3D) or !is_instance_valid(xr_origin_3D) or !is_instance_valid(xr_camera_3D):
		return false
	
	# Remember our current velocity, we'll apply that later
	var current_velocity = current_characterbody3D.velocity

	# Start by rotating the player to face the same way our real player is
	var directed_basis : Basis
	
	# If controller directed use controller as forward basis, otherwise use camera
	if roomscale_controller_directed_movement and is_instance_valid(xr_controller):
		directed_basis = xr_origin_3D.transform.basis * xr_controller.transform.basis
	else:
		directed_basis = xr_origin_3D.transform.basis * xr_camera_3D.transform.basis
	var forward: Vector2 = Vector2(directed_basis.z.x, directed_basis.z.z)
	if reverse_roomscale_direction:
		forward = -forward
	var angle: float = forward.angle_to(Vector2(0.0, 1.0))

	# Rotate our character body
	current_characterbody3D.transform.basis = current_characterbody3D.transform.basis.rotated(Vector3.UP, angle)

	# Reverse this rotation our origin node
	xr_origin_3D.transform = Transform3D().rotated(Vector3.UP, -angle) * xr_origin_3D.transform

	# Now apply movement, first move our player body to the right location
	var org_player_body: Vector3 = current_characterbody3D.global_transform.origin
	var player_body_location: Vector3 = xr_origin_3D.transform * xr_camera_3D.transform * xr_neck_position_3D.transform.origin
	player_body_location.y = 0.0
	player_body_location = current_characterbody3D.global_transform * player_body_location

	current_characterbody3D.velocity = (player_body_location - org_player_body) / delta
	current_characterbody3D.move_and_slide()

	# Now move our XROrigin back
	var delta_movement = current_characterbody3D.global_transform.origin - org_player_body
	xr_origin_3D.global_transform.origin -= delta_movement

	# Negate any height change in local space due to player hitting ramps etc.
	xr_origin_3D.transform.origin.y = 0.0
	
	# If user has set a further offset, apply that here; also use relative camera offset if enabled
	if is_instance_valid(camera_3d):
		xr_origin_3D.transform.origin.y = (camera_3d.transform.origin.y - current_characterbody3D.transform.origin.y) - xr_camera_3D.transform.origin.y + roomscale_height_adjustment
	else:
		xr_origin_3D.transform.origin.y += roomscale_height_adjustment
		
	# Return our value
	current_characterbody3D.velocity = current_velocity

	# Check if we managed to move where we wanted to
	var location_offset = (player_body_location - current_characterbody3D.global_transform.origin).length()
	if location_offset > 0.1:
		# We couldn't go where we wanted to, black out our screen
		black_out.fade = clamp((location_offset - 0.1) / 0.1, 0.0, 1.0)
		return true
	else:
		black_out.fade = 0.0
		return false

# _physics_process handles our player movement.
func _physics_process(delta):
	var is_colliding = _process_on_physical_movement(delta)

# Function used to set current flat screen game camera3D in case it isn't available yet at the time roomscale mode is activated	
func set_current_camera(new_camera3D : Camera3D):
	camera_3d = new_camera3D

# Function to allow changing of the relevant characterbody3D that drives the xr origin's movement	
func set_characterbody3D(new_characterbody3D : CharacterBody3D):
	if new_characterbody3D == null:
		print("Game sent null characterbody3d to roomscale")
		current_characterbody3D = null
	elif !is_instance_valid(new_characterbody3D):
		print("Game sent invalid instance of characterbody3D to roomscale")
		current_characterbody3D = null
	else:
		current_characterbody3D = new_characterbody3D

# Function to enable or disable roomscale movement
func set_enabled(value:bool, new_origin, reverse_roomscale:bool = false, current_camera : Camera3D = null, primary_controller : XRController3D = null, use_controller_directed_movement : bool = false, height_adjustment : float = 0.0) -> bool:
	if value == true and (current_characterbody3D == null or !is_instance_valid(current_characterbody3D)):
		print("Tried to enable roomscale but characterbody3D still not set or is set to an invalid instance.")
		return false
	if value == true and new_origin.is_class("XROrigin3D"):
		print("setting new origin3d in roomscale node")
		xr_origin_3D = new_origin
		xr_camera_3D = new_origin.get_node("XRCamera3D")
		xr_neck_position_3D = xr_camera_3D.get_node("Neck")
		black_out = xr_camera_3D.get_node("BlackOut")
		camera_3d = current_camera
		xr_controller = primary_controller
		roomscale_controller_directed_movement = use_controller_directed_movement
		roomscale_height_adjustment = height_adjustment
	enabled = value
	set_process(value)
	set_physics_process(value)
	reverse_roomscale_direction = reverse_roomscale
	if enabled == false:
		current_characterbody3D = null
		camera_3d = null
	# Return true in case calling method needs to know we finished; again could use signal here but this is simpler
	return true
