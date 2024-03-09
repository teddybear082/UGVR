extends Node3D

#This code was developed by lejar, https://github.com/lejar and adapted for this project


signal entry_selected(entry)

var anchor : Node3D = Node3D.new()
var enabled : bool = true
var xr_controller : XRController3D = null
var open_radial_menu_button : String = "by_button"
var menu_entries : Array = []
var distance_to_follow : float = .30
var radial_menu_open_position : Transform3D
var menu_quads : Array = []
var last_selected = null
var handling_input : bool = false
var menu_entry_material : StandardMaterial3D = StandardMaterial3D.new()
var selected_material : StandardMaterial3D = StandardMaterial3D.new()
var already_added_meshes : bool = false

func _ready():
	hide()
	add_child(anchor)
	
	# Set default menu entry background material
	menu_entry_material.albedo_color = Color.BLACK
	menu_entry_material.disable_ambient_light = true
	menu_entry_material.disable_receive_shadows = true
	menu_entry_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Set color for selected radial menu items
	selected_material.albedo_color = Color.GRAY
	selected_material.disable_ambient_light = true
	selected_material.disable_receive_shadows = true
	selected_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	#print("Made it to after hide function in xr radial menu")

func set_menu_entries(entries : Array) -> void:
	# Prevent doing this more than once per session
	if already_added_meshes:
		return
	# Set up menu entries list and associated meshes around radial menu
	menu_entries = entries
	for entry in menu_entries:
		add_entry(entry)
	already_added_meshes = true

func add_entry(entry : String) -> void:
	#print("Made it to add entry function in xr radial menu")
	var mesh_instance : MeshInstance3D = MeshInstance3D.new()
	var mesh : QuadMesh = QuadMesh.new()
	mesh_instance.material_override = menu_entry_material
	mesh.size = Vector2(0.15, 0.15)
	mesh_instance.mesh = mesh
	var mesh_label : Label3D = Label3D.new()
	mesh_label.text = entry
	mesh_label.font_size = 32
	mesh_label.outline_size = 8
	mesh_label.pixel_size = 0.0005
	mesh_label.width = 100.0
	mesh_label.autowrap_mode = 2
	mesh_instance.add_child(mesh_label)
	mesh_label.transform.origin.z = 0.001
	mesh_instance.show()
	anchor.add_child(mesh_instance)
	menu_quads.append(mesh_instance)
	#print("Made it to after menu quads append in xr radial menu")
	# Calculate the new layout.
	var arc_size = 2 * PI / len(menu_entries)
	var menu_scale : float = 0.2
	for i in range(len(menu_quads)):
		menu_quads[i].transform.origin = transform.origin + Vector3(sin(arc_size * i) * menu_scale, cos(arc_size * i) * menu_scale, 0)
		#print("Made it to end of add entry script in radial menu")

func unselect(entry: String) -> void:
	var index = menu_entries.find(entry)
	var mesh = menu_quads[index]
	mesh.material_override = menu_entry_material

func select(entry: String) -> void:
	if last_selected != null:
		unselect(last_selected)
		last_selected = null

	var index = menu_entries.find(entry)
	var mesh = menu_quads[index]
	mesh.material_override = selected_material
	last_selected = entry

func entry_from_position(position: Vector3) -> String:
	# Get the vector to the controller and to the first entry, and make them be in the menu plane.
	var inverse_transform = radial_menu_open_position.inverse()

	var controller_vector = (inverse_transform * position - inverse_transform * radial_menu_open_position.origin)
	var first_entry_vector = (inverse_transform * menu_quads[0].global_transform.origin - inverse_transform * radial_menu_open_position.origin)

	var radians = controller_vector.angle_to(first_entry_vector)
	# If the controller is left of the middle, then adjust the angle so that we
	# get the angle clockwise from the first entry.
	if controller_vector.x < 0:
		radians = 2 * PI - radians

	var arc_size = 2 * PI / len(menu_entries)

	var index = int(round(radians / arc_size))
	return menu_entries[index % len(menu_entries)]

func _process(delta) -> void:
	if xr_controller == null:
		return
	
	if !enabled:
		return
		
	# Anchor the menu to the current controller position and display the menu.
	if xr_controller.is_button_pressed(open_radial_menu_button) and not handling_input:
		handling_input = true
		radial_menu_open_position = xr_controller.global_transform
		anchor.global_transform = radial_menu_open_position
		show()

	elif not xr_controller.is_button_pressed(open_radial_menu_button) and handling_input:
		handling_input = false
		hide()
		var entry = entry_from_position(xr_controller.global_transform.origin)
		if entry != null:
			emit_signal("entry_selected", entry)
			#print("Emitted radial menu signal for entry: ", entry)

	# Update the menu with the controller position.
	elif handling_input:
#		$Anchor.global_transform = radial_menu_open_position
		if (anchor.global_transform.origin - xr_controller.global_transform.origin).length() >= distance_to_follow:
			anchor.global_transform.origin = lerp(anchor.global_transform.origin, xr_controller.global_transform.origin, delta)
			radial_menu_open_position = anchor.global_transform
		else:
			anchor.global_transform = radial_menu_open_position
		var entry = entry_from_position(xr_controller.global_transform.origin)
		if entry != null:
			select(entry)

func set_controller(controller_node : XRController3D):
	xr_controller = controller_node

func set_open_radial_menu_button(new_button : String):
	open_radial_menu_button = new_button

func set_enabled(setting : bool):
	enabled = setting
