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
				atom_connectors[i].rotate(Vector3(0, 0, 1), deg2rad(120))
			if i == 2:
				atom_connectors[i].rotate(Vector3(0, 0, 1), deg2rad(120))
				atom_connectors[i].rotate(Vector3(0, 1, 0), deg2rad(120))
			if i == 3:
				atom_connectors[i].rotate(Vector3(0, 0, 1), deg2rad(120))
				atom_connectors[i].rotate(Vector3(0, 1, 0), deg2rad(120))
				atom_connectors[i].rotate(Vector3(0, 1, 0), deg2rad(120))

func _set_bond(bond_type, to_id):
	var passes = 0
	
	if bond_type <= connections:
		if atom_connections[active_connector] == -1 or atom_connections[active_connector] == to_id:
			atom_connections[active_connector] = to_id
			if bond_type > 1:
				for c in connections:
					c += active_connector
					if c > connections - 1:
						c -= connections - 1
					
					if (atom_connections[c] == -1 or atom_connections[c] == to_id) and c != active_connector:
						passes += 1
						atom_connections[c] = to_id
						if passes == 1:
							atom_connectors[c].transform = atom_connectors[active_connector].transform
							atom_connectors[active_connector].translate_object_local(Vector3(-0.5, 0, 0))
							atom_connectors[c].translate_object_local(Vector3(0.5, 0, 0))
						if passes == 2:
							atom_connectors[c].transform = atom_connectors[active_connector].transform
							atom_connectors[active_connector].translate_object_local(Vector3(0.5, 0, 0))
						
						if (passes == 1 and bond_type < 3) or passes == 2:
							break

func _get_free_conns():
	var free_conns = []
	for c in atom_connections:
		if c == -1:
			free_conns.append(c)
	return free_conns

func _reset_bonds():
	for c in atom_connections.size():
		if atom_connections[c] == -1:
			atom_connectors[c].transform.basis = Basis()
			atom_connectors[c].transform.origin = Vector3()
			
			if c > 0:
				if c == 1:
					atom_connectors[c].rotate(Vector3(0, 0, 1), deg2rad(120))
				if c == 2:
					atom_connectors[c].rotate(Vector3(0, 0, 1), deg2rad(120))
					atom_connectors[c].rotate(Vector3(0, 1, 0), deg2rad(120))
				if c == 3:
					atom_connectors[c].rotate(Vector3(0, 0, 1), deg2rad(120))
					atom_connectors[c].rotate(Vector3(0, 1, 0), deg2rad(120))
					atom_connectors[c].rotate(Vector3(0, 1, 0), deg2rad(120))

func _reset_all_bonds():
	for c in atom_connections.size():
		atom_connections[c] = -1
		atom_connectors[c].transform.basis = Basis()
		atom_connectors[c].transform.origin = Vector3()
		
		if c > 0:
			if c == 1:
				atom_connectors[c].rotate(Vector3(0, 0, 1), deg2rad(120))
			if c == 2:
				atom_connectors[c].rotate(Vector3(0, 0, 1), deg2rad(120))
				atom_connectors[c].rotate(Vector3(0, 1, 0), deg2rad(120))
			if c == 3:
				atom_connectors[c].rotate(Vector3(0, 0, 1), deg2rad(120))
				atom_connectors[c].rotate(Vector3(0, 1, 0), deg2rad(120))
				atom_connectors[c].rotate(Vector3(0, 1, 0), deg2rad(120))

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