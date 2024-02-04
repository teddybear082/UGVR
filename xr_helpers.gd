extends Node
# All credit to Godot XR Tools

## XR Tools Helper Rountines
##
## This script contains static functions to help find XR player nodes.
##
## As these functions are static, the caller must pass in a node located
## somewhere under the players [XROrigin3D].


## Find the [XROrigin3D] node.
##
## This function searches for the [XROrigin3D] from the provided node.
## The caller may provide an optional path (relative to the node) to the
## [XROrigin3D] to support out-of-tree searches.
##
## The search is performed assuming the node is under the [XROrigin3D].
static func get_xr_origin(node: Node, path: NodePath = NodePath()) -> XROrigin3D:
	var origin: XROrigin3D

	# Try using the node path first
	if path:
		origin = node.get_node(path) as XROrigin3D
		if origin:
			return origin

	# Walk up the tree from the provided node looking for the origin
	origin = find_xr_ancestor(node, "*", "XROrigin3D")
	if origin:
		return origin

	# We check our children but only one level
	origin = find_xr_child(node, "*", "XROrigin3D", false)
	if origin:
		return origin

	# Could not find origin
	return null

## Find the [XRCamera3D] node.
##
## This function searches for the [XRCamera3D] from the provided node.
## The caller may provide an optional path (relative to the node) to the
## [XRCamera3D] to support out-of-tree searches.
##
## The search is performed assuming the node is under the [XROrigin3D].
static func get_xr_camera(node: Node, path: NodePath = NodePath()) -> XRCamera3D:
	var camera: XRCamera3D

	# Try using the node path first
	if path:
		camera = node.get_node(path) as XRCamera3D
		if camera:
			return camera

	# Get the origin
	var origin := get_xr_origin(node)
	if !origin:
		return null

	# Attempt to get by the default name
	camera = origin.get_node_or_null("Camera") as XRCamera3D
	if camera:
		return camera

	# Search all children of the origin for the camera
	camera = find_xr_child(origin, "*", "XRCamera3D", false)
	if camera:
		return camera

	# Could not find camera
	return null

## Find the [XRController3D] node.
##
## This function searches for the [XRController3D] from the provided node.
## The caller may provide an optional path (relative to the node) to the
## [XRController3D] to support out-of-tree searches.
##
## The search is performed assuming the node is under the [XRController3D].
static func get_xr_controller(node: Node, path: NodePath = NodePath()) -> XRController3D:
	var controller: XRController3D

	# Try using the node path first
	if path:
		controller = node.get_node(path) as XRController3D
		if controller:
			return controller

	# Search up from the node for the controller
	return find_xr_ancestor(node, "*", "XRController3D") as XRController3D

## Find the Left Hand [XRController3D] from a player node and an optional path
static func get_left_controller(node: Node, path: NodePath = NodePath()) -> XRController3D:
	return _get_controller(node, "LeftHandController", "left_hand", path)


## Find the Right Hand [XRController3D] from a player node and an optional path
static func get_right_controller(node: Node, path: NodePath = NodePath()) -> XRController3D:
	return _get_controller(node, "RightHandController", "right_hand", path)


## Find an [XRController3D] given some search parameters
static func _get_controller(
		node: Node,
		default_name: String,
		tracker: String,
		path: NodePath) -> XRController3D:
	var controller: XRController3D

	# Try using the node path first
	if path:
		controller = node.get_node(path) as XRController3D
		if controller:
			return controller

	# Get the origin
	var origin := get_xr_origin(node)
	if !origin:
		return null

	# Attempt to get by the default name
	controller = origin.get_node_or_null(default_name) as XRController3D
	if controller:
		return controller

	# Search all children of the origin for the controller
	for child in origin.get_children():
		controller = child as XRController3D
		if controller and controller.tracker == tracker:
			return controller

	# Could not find the controller
	return null

## Find all children of the specified node matching the given criteria
##
## This function returns an array containing all children of the specified
## node matching the given criteria. This function can be slow and find_child
## is faster if only one child is needed.
##
## The pattern argument specifies the match pattern to check against the
## node name. Use "*" to match anything.
##
## The type argument specifies the type of node to find. Use "" to match any
## type.
##
## The recursive argument specifies whether the search deeply though all child
## nodes, or whether to only check the immediate children.
##
## The owned argument specifies whether the node must be owned.
static func find_xr_children(
		node : Node,
		pattern : String,
		type : String = "",
		recursive : bool = true,
		owned : bool = true) -> Array:
	# Find the children
	var found := []
	if node:
		_find_xr_children(found, node, pattern, type, recursive, owned)
	return found

## Find a child of the specified node matching the given criteria
##
## This function finds the first child of the specified node matching the given
## criteria.
##
## The pattern argument specifies the match pattern to check against the
## node name. Use "*" to match anything.
##
## The type argument specifies the type of node to find. Use "" to match any
## type.
##
## The recursive argument specifies whether the search deeply though all child
## nodes, or whether to only check the immediate children.
##
## The owned argument specifies whether the node must be owned.
static func find_xr_child(
		node : Node,
		pattern : String,
		type : String = "",
		recursive : bool = true,
		owned : bool = true) -> Node:
	# Find the child
	if node:
		return _find_xr_child(node, pattern, type, recursive, owned)

	# Invalid node
	return null

## Find an ancestor of the specified node matching the given criteria
##
## This function finds the first ancestor of the specified node matching the
## given criteria.
##
## The pattern argument specifies the match pattern to check against the
## node name. Use "*" to match anything.
##
## The type argument specifies the type of node to find. Use "" to match any
## type.
static func find_xr_ancestor(
		node : Node,
		pattern : String,
		type : String = "") -> Node:
	# Loop finding ancestor
	while node:
		# If node matches filter then break
		if (node.name.match(pattern) and
			(type == "" or is_xr_class(node, type))):
			break

		# Advance to parent
		node = node.get_parent()

	# Return found node (or null)
	return node

# Recursive helper function for find_children.
static func _find_xr_children(
		found : Array,
		node : Node,
		pattern : String,
		type : String,
		recursive : bool,
		owned : bool) -> void:
	# Iterate over all children
	for i in node.get_child_count():
		# Get the child
		var child := node.get_child(i)

		# If child matches filter then add it to the array
		if (child.name.match(pattern) and
			(type == "" or is_xr_class(child, type)) and
			(not owned or child.owner)):
			found.push_back(child)

		# If recursive is enabled then descend into children
		if recursive:
			_find_xr_children(found, child, pattern, type, recursive, owned)

# Recursive helper functiomn for find_child
static func _find_xr_child(
		node : Node,
		pattern : String,
		type : String,
		recursive : bool,
		owned : bool) -> Node:
	# Iterate over all children
	for i in node.get_child_count():
		# Get the child
		var child := node.get_child(i)

		# If child matches filter then return it
		if (child.name.match(pattern) and
			(type == "" or is_xr_class(child, type)) and
			(not owned or child.owner)):
			return child

		# If recursive is enabled then descend into children
		if recursive:
			var found := _find_xr_child(child, pattern, type, recursive, owned)
			if found:
				return found

	# Not found
	return null

# Test if a given node is of the specified class
static func is_xr_class(node : Node, type : String) -> bool:
	if node.has_method("is_xr_class"):
		if node.is_xr_class(type):
			return true

	return node.is_class(type)
