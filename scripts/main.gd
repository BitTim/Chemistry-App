extends Spatial

var molecule 
var molecules
var active_molecule = 0
var atoms = []
var atom_scene
var active_atom = -1
var avail_connections = 0
var max_connections = 0
var next_atom_id = 1
var prev_active_atom = -1
var holo_atom
var atom_rotation = 0

export (float, 0.0, 1.0) var cam_sensitivity = 0
export (float, 0.0, 1.0) var cam_speed = 0

var swipe_index = -1

func _ready():
	load_data()
	
	molecule = load("res://scenes/molecule.tscn").instance()
	$Molecules.add_child(molecule)
	molecules = $Molecules.get_children()
	
	atoms = molecules[active_molecule].get_node("Atome").get_children()
	atom_scene = load("res://scenes/atom.tscn")
	
	$HUD.connect("select_atom", self, "_on_select_atom")
	$HUD.connect("rotate_atom", self, "_on_atom_rotate")
	$HUD.connect("place_atom", self, "_on_place_atom")
	$HUD.connect("delete_atom", self, "_on_atom_delete")
	$HUD.connect("hide_GUI", self, "_on_HUD_hide")
	$HUD.connect("show_GUI", self, "_on_HUD_show")
	$HUD.connect("reset_mode", self, "_on_reset_mode")
	$HUD.get_node("ConfirmationDialog").connect("confirmed", self, "_on_reset_confirm")
	
	$Swipe_Detector.connect("swipe", self, "_on_swipe")
	
	holo_atom = atom_scene.instance()
	holo_atom.init(0, -0x8FCF)
	holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 120))
	molecules[active_molecule].get_node("Holo").add_child(holo_atom)

func load_data():
	var data_file = File.new()
	if data_file.open("res://data/atoms.json", File.READ) != OK:
		print("JSON Error: Failed to read File")
		return
	
	var data_text = data_file.get_as_text()
	data_file.close()
	var data_parse = JSON.parse(data_text)
	
	if data_parse.error != OK:
		print("JSON Error: Failed to parse File")
		return
	
	ProjectSettings.set("atom_database", data_parse.result)

func _input(event):
	if atoms.size() > 0:
		if $HUD.mode != 0 or $HUD/UI.visible == false:
			atoms[active_atom].hide_outline = true
		else:
			atoms[active_atom].hide_outline = false
	
	if event is InputEventScreenTouch and event.is_pressed():
		if swipe_index == -1:
			swipe_index = event.index
	
	if event is InputEventScreenDrag and event.index == swipe_index:
		if $HUD.mode == 1:
			$Molecules.rotate_x(deg2rad(event.relative.y * cam_sensitivity))
			$Molecules.rotate_y(deg2rad(event.relative.x * cam_sensitivity))
			
		if $HUD.mode == 2:
			$Molecules.translation += Vector3(event.relative.x * cam_speed, event.relative.y * cam_speed * -1, 0)
		
		if $HUD.mode == 3:
			$HUD/Camera.translate(Vector3(0, 0, event.relative.y * cam_speed))
	
	if event is InputEventScreenTouch and not event.is_pressed():
		swipe_index = -1

func _on_swipe(dir):
	if $HUD.mode == 0:
		if atoms.size() > 0 and active_atom > -1:
			atoms[active_atom].active_connector += dir.x
			if atoms[active_atom].active_connector > atoms[active_atom].connections - 1:
				atoms[active_atom].active_connector = 0
			
			if atoms[active_atom].active_connector < 0:
				atoms[active_atom].active_connector = atoms[active_atom].connections - 1
			
			if abs(dir.y) > 0:
				atoms[active_atom].active = false
				var next_active_candidate = atoms[active_atom].atom_connections[atoms[active_atom].active_connector]
				if next_active_candidate != -1:
					active_atom = next_active_candidate
				
				if active_atom > -1 and active_atom < atoms.size():
					atoms[active_atom].active = true
			
			if atoms[active_atom].atom_connections[atoms[active_atom].active_connector] == -1:
				holo_atom.show()
				holo_atom.transform.origin = atoms[active_atom].transform.origin
				holo_atom.transform.basis = atoms[active_atom].transform.basis * atoms[active_atom].atom_connectors[atoms[active_atom].active_connector].transform.basis * Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1))
				holo_atom.translate(Vector3(0, -4, 0))
				holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 120))
			else:
				holo_atom.hide()

func _on_select_atom(atom_type):
	holo_atom.queue_free()
	holo_atom = atom_scene.instance()
	holo_atom.init(atom_type, -0x8FCF)
	
	if atoms.size() > 0:
		holo_atom.transform.origin = atoms[active_atom].transform.origin
		holo_atom.transform.basis = atoms[active_atom].transform.basis * atoms[active_atom].atom_connectors[atoms[active_atom].active_connector].transform.basis * Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1))
		holo_atom.translate(Vector3(0, -4, 0))
	
	holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 120))
	molecules[active_molecule].get_node("Holo").add_child(holo_atom)

func _on_atom_rotate():
	atom_rotation += 1
	if atom_rotation > 2:
		atom_rotation = 0
	
	if atoms.size() > 0:
		holo_atom.transform.origin = atoms[active_atom].transform.origin
		holo_atom.transform.basis = atoms[active_atom].transform.basis * atoms[active_atom].atom_connectors[atoms[active_atom].active_connector].transform.basis * Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1))
	else:
		holo_atom.transform.origin = Vector3()
		holo_atom.transform.basis = Basis()
	
	holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 120))
	$HUD/UI/Info/Rotation.text = String(atom_rotation)

func _on_place_atom(atom_type):
	if $HUD.mode == 0:
		if avail_connections > 0 and active_atom != -1 and atoms[active_atom].atom_connections[atoms[active_atom].active_connector] == -1:
			var curr_atom = atom_scene.instance()
			curr_atom.init(atom_type, next_atom_id)
			next_atom_id += 1
			curr_atom.active_connector = 0
			
			if atoms.size() < 1:
				return
			
			max_connections += curr_atom.connections
			avail_connections += curr_atom.connections - 2
			if avail_connections <= 0:
				$HUD/UI/Atom_Platzieren/Place.disabled = true
			else:
				$HUD/UI/Atom_Platzieren/Place.disabled = false
			
			$HUD.update_conn_display(avail_connections, max_connections)
			
			curr_atom.transform = holo_atom.transform
			
			atoms[active_atom].atom_connections[atoms[active_atom].active_connector] = curr_atom.atom_id
			curr_atom.atom_connections[curr_atom.active_connector] = atoms[active_atom].atom_id
			
			molecules[active_molecule].get_node("Atome").add_child(curr_atom)
			atoms.append(curr_atom)
			
			if atoms.size() > 0:
				holo_atom.transform.origin = atoms[active_atom].transform.origin
				holo_atom.transform.basis = atoms[active_atom].transform.basis * atoms[active_atom].atom_connectors[atoms[active_atom].active_connector].transform.basis * Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1))
				holo_atom.translate(Vector3(0, -4, 0))
				holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 120))
		
		if active_atom == -1:
			var curr_atom = atom_scene.instance()
			curr_atom.init(atom_type, 0)
			curr_atom.active_connector = 0
			
			max_connections += curr_atom.connections
			avail_connections += curr_atom.connections
			$HUD.update_conn_display(avail_connections, max_connections)
			
			curr_atom.transform = holo_atom.transform
			
			molecules[active_molecule].get_node("Atome").add_child(curr_atom)
			$HUD/UI/Atom_Platzieren/Delete.disabled = false
			
			active_atom += 1
			atoms.append(curr_atom)
			curr_atom.active = true
			
			if atoms.size() > 0:
				holo_atom.transform.origin = atoms[active_atom].transform.origin
				holo_atom.transform.basis = atoms[active_atom].transform.basis * atoms[active_atom].atom_connectors[atoms[active_atom].active_connector].transform.basis * Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1))
				holo_atom.translate(Vector3(0, -4, 0))
				holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 120))

func _on_atom_delete():
	var del_id = atoms[active_atom].atom_id
	
	avail_connections -= atoms[active_atom].connections - 2
	max_connections -= atoms[active_atom].connections
	atoms[active_atom].queue_free()
	atoms.remove(active_atom)
	
	if atoms.size() < 1:
		$HUD/UI/Atom_Platzieren/Delete.disabled = true
		avail_connections = 0
	
	$HUD.update_conn_display(avail_connections, max_connections)
	
	if avail_connections > 0:
		$HUD/UI/Atom_Platzieren/Place.disabled = false
	
	for a in range(0, atoms.size()):
		if atoms[a].atom_id > del_id:
			atoms[a].atom_id -= 1
		
		for c in range(0, atoms[a].connections):
			if atoms[a].atom_connections[c] == del_id:
				atoms[a].atom_connections[c] = -1
			if atoms[a].atom_connections[c] > del_id:
				atoms[a].atom_connections[c] -= 1
	
	if atoms.size() > 0:
		next_atom_id -= 1
		active_atom = atoms[0].atom_id
		atoms[active_atom].active = true
		
		holo_atom.transform.origin = atoms[active_atom].transform.origin
		holo_atom.transform.basis = atoms[active_atom].transform.basis * atoms[active_atom].atom_connectors[atoms[active_atom].active_connector].transform.basis * Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1))
		holo_atom.translate(Vector3(0, -4, 0))
		holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 120))
	else:
		active_atom = -1
		next_atom_id = 1
		holo_atom.transform.origin = Vector3()
		holo_atom.transform.basis = Basis()
		holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 120))

func _on_HUD_hide():
	atoms[active_atom].hide_outline = true
	holo_atom.hide()

func _on_HUD_show():
	atoms[active_atom].hide_outline = false
	holo_atom.show()

func _on_reset_mode(mode):
	if mode == 0:
		$HUD.get_node("ConfirmationDialog").popup_centered_ratio(0.5)
		
	if mode == 1:
		$Molecules.transform.basis = Basis()
	if mode == 2:
		$Molecules.translation = Vector3()
	if mode == 3:
		$HUD/Camera.translation = Vector3(0, 0, 15)

func _on_reset_confirm():
	active_atom = -1
	avail_connections = 0
	max_connections = 0
	atom_rotation = 0
	$HUD.update_conn_display(avail_connections, max_connections)
	
	for a in range(0, atoms.size()):
		for c in atoms[0].connections:
			atoms[0].atom_connectors[0].queue_free()
			atoms[0].atom_connectors.remove(0)
		
		atoms[0].queue_free()
		atoms.remove(0)
	
	$HUD/UI/Atom_Platzieren/Place.disabled = false
	$HUD/UI/Atom_Platzieren/Delete.disabled = true
	next_atom_id = 1
	
	holo_atom.queue_free()
	holo_atom = atom_scene.instance()
	holo_atom.init(0, -0x8FCF)
	holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 120))
	molecules[active_molecule].get_node("Holo").add_child(holo_atom)

func _process(delta):
	if atoms.size() > 0:
		$HUD/UI/Info/Active.text = String(active_atom) + " / " + String(atoms[active_atom].active_connector)