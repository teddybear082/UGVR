## Types of pointer events
enum Type {
	## Pointer entered target
	ENTERED,

	## Pointer exited target
	EXITED,

	## Pointer pressed target
	PRESSED,

	## Pointer released target
	RELEASED,

	## Pointer moved on target
	MOVED
}

## Type of pointer event
var event_type : Type

## Pointer generating event
var pointer : Node3D

## Target of pointer
var target : Node3D

## Point position
var position : Vector3

## Last point position
var last_position : Vector3

class XRToolsPointerEvent:
	var event_type
	var pointer
	var target
	var position
	var last_position

## Report a pointer entered event
static func entered(
		pointer : Node3D,
		target : Node3D,
		at : Vector3) -> void:
	report(Type.ENTERED,pointer,target,at,at)

## Report pointer moved event
static func moved(
		pointer : Node3D,
		target : Node3D,
		to : Vector3,
		from : Vector3) -> void:
	report(Type.MOVED,pointer,target,to,from)


## Report pointer pressed event
static func pressed(
		pointer : Node3D,
		target : Node3D,
		at : Vector3) -> void:
	report(Type.PRESSED,pointer,target,at,at)


## Report pointer released event
static func released(
		pointer : Node3D,
		target : Node3D,
		at : Vector3) -> void:
	report(Type.RELEASED,pointer,target,at,at)

## Report a pointer exited event
static func exited(
		pointer : Node3D,
		target : Node3D,
		last : Vector3) -> void:
	report(Type.EXITED,pointer,target,last,last)


## Report a pointer event
static func report(event_type, pointer, target, position, last_position) -> void:
	var new_event = XRToolsPointerEvent.new()
	new_event.event_type = event_type
	new_event.pointer = pointer
	new_event.target = target
	new_event.position = position
	new_event.last_position = last_position
	# Fire event on pointer
	if is_instance_valid(pointer):
		if pointer.has_signal("pointing_event"):
			pointer.emit_signal("pointing_event", new_event)

	# Fire event/method on the target if it's valid
	if is_instance_valid(target):
		if target.has_signal("pointer_event"):
			target.emit_signal("pointer_event", new_event)
		elif target.has_method("pointer_event"):
			target.pointer_event(new_event)
