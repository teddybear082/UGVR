# used to capture XR Pointer event signal and forward it to the Interactive GUI object parent
# The XR pointer automatically fires the signal on its collider if it exists
extends Area3D
signal pointer_event(event)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
