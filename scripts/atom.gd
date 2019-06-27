extends Spatial

export (String) var atom_name
export (int) var connections
export (Color) var color

var atom_connection_scene = preload("res://scenes/atom_connection.tscn")
var atom_id = -1
var atom_type = -1
var atom_connections = []
var atom_connectors = []
var active_connector = 0
var active = false
var hide_outline = false

func init(type, id):
	atom_type = type
	atom_id = id
	atom_name = String(ProjectSettings.get("atom_database")[String(type)].name)
	connections = int(ProjectSettings.get("atom_database")[String(type)].connections)
	color = Color(ProjectSettings.get("atom_database")[String(type)].color)
	
	for i in range(0, connections):
		var atom_connection = atom_connection_scene.instance()
		atom_connection.get_node("Atom_Connection/Outline").hide()
		$Connections.add_child(atom_connection)
		atom_connections.append(-1)
	
	atom_connectors = $Connections.get_children()
	
	var material
	if atom_id != -0x8FCF:
		material = $Atom_Body.get_node("Atom_Body").get_surface_material(0)
		material.albedo_color = color
		$Atom_Body.get_node("Atom_Body").set_surface_material(0, material)
	else:
		$Atom_Body.get_node("Atom_Body").hide()
		$Atom_Body/Holo.show()
	
	for i in range(0, connections):
		if atom_id == -0x8FCF:
			atom_connectors[i].get_node("Atom_Connection").hide()
			atom_connectors[i].get_node("Holo").show()
		
		if i > 0:
			if i == 1:
				atom_connectors[i].rotate_z(deg2rad(120))
			if i == 2:
				atom_connectors[i].rotate_z(deg2rad(120))
				atom_connectors[i].rotate_y(deg2rad(120))
				pass
			if i == 3:
				atom_connectors[i].rotate_z(deg2rad(120))
				atom_connectors[i].rotate_y(deg2rad(120))
				atom_connectors[i].rotate_y(deg2rad(120))
				pass

func _process(delta):
	if !hide_outline and active and atom_id != -0x8FCF:
		$Atom_Body.get_node("Atom_Body/Outline").visible = true
		
		var i = 0
		for c in atom_connectors:
			if active_connector == i:
				c.get_node("Atom_Connection/Outline").show()
			else:
				c.get_node("Atom_Connection/Outline").hide()
			i += 1
	else:
		$Atom_Body.get_node("Atom_Body/Outline").hide()
		
		for c in atom_connectors:
			c.get_node("Atom_Connection/Outline").hide()