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

var num_prefixes = []

export (float, 0.0, 1.0) var cam_sensitivity = 0
export (float, 0.0, 1.0) var cam_speed = 0

var swipe_index = -1

func _ready():
	num_prefixes = {1: "Mono", 2: "Di", 3: "Tri", 4: "Tetra", 5: "Penta", 6: "Hexa", 7: "Hepta", 8: "Octa", 9: "Nona", 10: "Deca", 11: "Undeca", 12: "Dodeca", 13: "Trideca", 14: "Tetradeca", 15: "Pentadeca", 16: "Hexadeca", 17: "Heptadeca", 18: "Octadeca", 19: "Nonadeca", 20: "Eicosa", 21: "Heneicosa", 22: "Docosa", 23: "Tricosa", 24: "Tetracosa", 25: "Pentacosa", 26: "Hexacosa", 27: "Heptacosa", 28: "Octacosa", 29: "Nonacosa", 30: "triaconta", 31: "Hentriaconta", 32: "Dotriaconta"}
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
	$HUD.connect("bond_change", self, "_on_bond_change")
	$HUD.connect("hide_GUI", self, "_on_HUD_hide")
	$HUD.connect("show_GUI", self, "_on_HUD_show")
	$HUD.connect("reset_mode", self, "_on_reset_mode")
	$HUD.get_node("ConfirmationDialog").connect("confirmed", self, "_on_reset_confirm")
	
	$Swipe_Detector.connect("swipe", self, "_on_swipe")
	
	holo_atom = atom_scene.instance()
	holo_atom.init(0, -0x8FCF)
	holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 60))
	molecules[active_molecule].get_node("Holo").add_child(holo_atom)
	
	$HUD/UI/Atom_Platzieren/Place.disabled = true
	_on_place_atom(0)
	_on_reset_confirm()

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
			
			if atoms[active_atom].atom_connections[atoms[active_atom].active_connector] == -1 and atoms[active_atom]._get_free_conns().size() >= $HUD.bond_type:
				
				holo_atom._reset_all_bonds()
				holo_atom.transform.origin = atoms[active_atom].transform.origin
				holo_atom.transform.basis = atoms[active_atom].transform.basis * atoms[active_atom].atom_connectors[atoms[active_atom].active_connector].transform.basis * Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1))
				holo_atom.translate(Vector3(0, -4, 0))
				holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 60))
				holo_atom._set_bond($HUD.bond_type, active_atom)
				atoms[active_atom]._reset_bonds()
				atoms[active_atom]._set_bond($HUD.bond_type, -1)
			else:
				$HUD/UI/Atom_Platzieren/Place.disabled = true
				holo_atom.hide()

func _on_select_atom(atom_type):
	holo_atom.queue_free()
	holo_atom = atom_scene.instance()
	holo_atom.init(atom_type, -0x8FCF)
	holo_atom.active_connector = 0
	if atoms.size() > 0:
		if holo_atom.connections >= $HUD.bond_type and atoms[active_atom]._get_free_conns().size() >= $HUD.bond_type:
			holo_atom._reset_all_bonds()
			holo_atom._set_bond($HUD.bond_type, active_atom)
			holo_atom.transform.origin = atoms[active_atom].transform.origin
			holo_atom.transform.basis = atoms[active_atom].transform.basis * atoms[active_atom].atom_connectors[atoms[active_atom].active_connector].transform.basis * Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1))
			holo_atom.translate(Vector3(0, -4, 0))
			atoms[active_atom]._reset_bonds()
			atoms[active_atom]._set_bond($HUD.bond_type, -1)
		else:
			$HUD/UI/Atom_Platzieren/Place.disabled = true
			holo_atom.hide()
	else:
		holo_atom._reset_all_bonds()
		holo_atom._set_bond($HUD.bond_type, -1)
	
	holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 60))
	molecules[active_molecule].get_node("Holo").add_child(holo_atom)

func _on_atom_rotate():
	atom_rotation += 1
	if atom_rotation > 5:
		atom_rotation = 0
	
	if atoms.size() > 0:
		holo_atom.transform.origin = atoms[active_atom].transform.origin
		holo_atom.transform.basis = atoms[active_atom].transform.basis * atoms[active_atom].atom_connectors[atoms[active_atom].active_connector].transform.basis * Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1))
	else:
		holo_atom.transform.origin = Vector3()
		holo_atom.transform.basis = Basis()
	
	holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 60))
	$HUD/UI/Info/Rotation.text = "Drehung: " + String(atom_rotation * 60) + "°"

func _on_place_atom(atom_type):
	if $HUD.mode == 0:
		if avail_connections > 0 and active_atom != -1 and atoms[active_atom].atom_connections[atoms[active_atom].active_connector] == -1:
			var curr_atom = atom_scene.instance()
			curr_atom.init(atom_type, next_atom_id)
			next_atom_id += 1
			curr_atom.active_connector = 0
			
			if atoms.size() < 1:
				return
			
			atoms[active_atom]._reset_bonds()
			atoms[active_atom]._set_bond($HUD.bond_type, curr_atom.atom_id)
			curr_atom._reset_bonds()
			curr_atom._set_bond($HUD.bond_type, atoms[active_atom].atom_id)
			
			max_connections += curr_atom.connections
			avail_connections += curr_atom.connections - (2 * $HUD.bond_type)
			if avail_connections <= 0 or (holo_atom.connections < $HUD.bond_type or atoms[active_atom].connections < $HUD.bond_type):
				$HUD/UI/Atom_Platzieren/Place.disabled = true
			
			$HUD.update_conn_display(avail_connections, max_connections)
			
			curr_atom.transform = holo_atom.transform
			
			molecules[active_molecule].get_node("Atome").add_child(curr_atom)
			atoms.append(curr_atom)
			
			if atoms.size() > 0:
				holo_atom.transform.origin = atoms[active_atom].transform.origin
				holo_atom.transform.basis = atoms[active_atom].transform.basis * atoms[active_atom].atom_connectors[atoms[active_atom].active_connector].transform.basis * Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1))
				holo_atom.translate(Vector3(0, -4, 0))
				holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 60))
				
				if atoms[active_atom]._get_free_conns().size() >= $HUD.bond_type:
					
					holo_atom._reset_all_bonds()
					holo_atom._set_bond($HUD.bond_type, active_atom)
					atoms[active_atom]._reset_bonds()
					atoms[active_atom]._set_bond($HUD.bond_type, -1)
				else:
					$HUD/UI/Atom_Platzieren/Place.disabled = true
					holo_atom.hide()
				
				# Check for un connected connections
				for c in curr_atom.connections:
					if curr_atom.atom_connections[c] == -1:
						holo_atom.transform.origin = curr_atom.transform.origin
						holo_atom.transform.basis = curr_atom.transform.basis * curr_atom.atom_connectors[c].transform.basis * Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1))
						holo_atom.translate(Vector3(0, -4, 0))
						holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 60))
						
						for a in atoms.size():
							if a != curr_atom.atom_id:
								var diff_origin = Vector3(abs(holo_atom.transform.origin.x - atoms[a].transform.origin.x), abs(holo_atom.transform.origin.y - atoms[a].transform.origin.y), abs(holo_atom.transform.origin.z - atoms[a].transform.origin.z))
								if diff_origin < Vector3(0.01, 0.01, 0.01):
									for c2 in atoms[a].connections:
										if atoms[a].atom_connections[c2] == -1:
											holo_atom.transform.origin = atoms[a].transform.origin
											holo_atom.transform.basis = atoms[a].transform.basis * atoms[a].atom_connectors[c2].transform.basis * Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1))
											holo_atom.translate(Vector3(0, -4, 0))
											holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 60))
											
											var diff_origin2 = Vector3(abs(holo_atom.transform.origin.x - curr_atom.transform.origin.x), abs(holo_atom.transform.origin.y - curr_atom.transform.origin.y), abs(holo_atom.transform.origin.z - curr_atom.transform.origin.z))
											if diff_origin2 < Vector3(0.01, 0.01, 0.01):
												atoms[a].atom_connections[c2] = curr_atom.atom_id
												curr_atom.atom_connections[c] = a
												avail_connections -= 2
												$HUD.update_conn_display(avail_connections, max_connections)
												return
		
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
				holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 60))
				
				if atoms[active_atom]._get_free_conns().size() >= $HUD.bond_type:
					
					holo_atom._reset_all_bonds()
					holo_atom._set_bond($HUD.bond_type, -1)
					atoms[active_atom]._reset_bonds()
					atoms[active_atom]._set_bond($HUD.bond_type, -1)
				else:
					$HUD/UI/Atom_Platzieren/Place.disabled = true
					holo_atom.hide()

func _on_atom_delete():
	var del_id = atoms[active_atom].atom_id
	
	max_connections -= atoms[active_atom].connections
	atoms[active_atom].queue_free()
	atoms.remove(active_atom)
	
	if atoms.size() < 1:
		$HUD/UI/Atom_Platzieren/Delete.disabled = true
		avail_connections = 0
	
	for a in range(0, atoms.size()):
		if atoms[a].atom_id > del_id:
			atoms[a].atom_id -= 1
		
		for c in range(0, atoms[a].connections):
			if atoms[a].atom_connections[c] == del_id:
				atoms[a].atom_connections[c] = -1
			
			atoms[a]._reset_bonds()
				
			if atoms[a].atom_connections[c] > del_id:
				atoms[a].atom_connections[c] -= 1
	
	if atoms.size() > 0:
		next_atom_id -= 1
		active_atom = atoms[0].atom_id
		atoms[active_atom].active = true
		
		holo_atom.transform.origin = atoms[active_atom].transform.origin
		holo_atom.transform.basis = atoms[active_atom].transform.basis * atoms[active_atom].atom_connectors[atoms[active_atom].active_connector].transform.basis * Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1))
		holo_atom.translate(Vector3(0, -4, 0))
		holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 60))
	else:
		active_atom = -1
		next_atom_id = 1
		holo_atom._reset_bonds()
		holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 60))
	
	avail_connections = 0
	for a in atoms:
		for c in a.atom_connections:
			if c == -1:
				avail_connections += 1
	$HUD.update_conn_display(avail_connections, max_connections)

func _on_bond_change(bond_type):
	if atoms.size() > 0:
		if holo_atom.connections < $HUD.bond_type or atoms[active_atom].connections < $HUD.bond_type:
			$HUD/UI/Atom_Platzieren/Place.disabled = true
		
		if atoms[active_atom]._get_free_conns().size() >= bond_type:
			
			holo_atom._reset_all_bonds()
			holo_atom._set_bond(bond_type, active_atom)
			atoms[active_atom]._reset_bonds()
			atoms[active_atom]._set_bond(bond_type, -1)
		else:
			$HUD/UI/Atom_Platzieren/Place.disabled = true
			holo_atom.hide()
	else:
		if holo_atom.connections >= bond_type:
			
			holo_atom._reset_all_bonds()
			holo_atom._set_bond(bond_type, -1)
		else:
			$HUD/UI/Atom_Platzieren/Place.disabled = true
			holo_atom.hide()

func _on_HUD_hide():
	if atoms.size() > 0:
		atoms[active_atom].hide_outline = true
	
	holo_atom.hide()

func _on_HUD_show():
	if atoms.size():
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
	
	$HUD/UI/Info/Proportion.text = "Verhältnis: "
	
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
	holo_atom.rotate_object_local(Vector3(0, 1, 0), deg2rad((atom_rotation) * 60))
	holo_atom._reset_bonds()
	molecules[active_molecule].get_node("Holo").add_child(holo_atom)

func get_prop_label():
	var proportion = [0, 0, 0, 0, 0]
	var prop_label = ""
	
	for a in atoms:
		proportion[a.atom_type] += 1
	
	var tmp
	tmp = proportion[0]
	proportion[0] = proportion[1]
	proportion[1] = proportion[4]
	proportion[4] = proportion[2]
	proportion[2] = tmp
	
	for p in proportion.size():
		if proportion[p] != 0:
			if p == 0:
				prop_label += "C"
			if p == 1:
				prop_label += "Cl"
			if p == 2:
				prop_label += "H"
			if p == 3:
				prop_label += "N"
			if p == 4:
				prop_label += "O"
			
			if proportion[p] > 1:
				prop_label += "{" + String(proportion[p]) + "}"
	
	prop_label = prop_label.format({"0": "\u2080"})
	prop_label = prop_label.format({"1": "\u2081"})
	prop_label = prop_label.format({"2": "\u2082"})
	prop_label = prop_label.format({"3": "\u2083"})
	prop_label = prop_label.format({"4": "\u2084"})
	prop_label = prop_label.format({"5": "\u2085"})
	prop_label = prop_label.format({"6": "\u2086"})
	prop_label = prop_label.format({"7": "\u2087"})
	prop_label = prop_label.format({"8": "\u2088"})
	prop_label = prop_label.format({"9": "\u2089"})
	
	return prop_label

func get_sys_name_label():
	var proportion = [0, 0, 0, 0, 0]
	var sys_name = ""
	
	for a in atoms:
		proportion[a.atom_type] += 1
	
	var tmp
	tmp = proportion[0]
	proportion[0] = proportion[1]
	proportion[1] = proportion[4]
	proportion[4] = proportion[2]
	proportion[2] = tmp
	
	for p in proportion.size():
		if proportion[p] != 0:
			sys_name += num_prefixes.get(proportion[p])
			
			if p == 0:
				sys_name += "carbon-"
			if p == 1:
				sys_name += "chlorin-"
			if p == 2:
				sys_name += "hydrogen-"
			if p == 3:
				sys_name += "nitrogen-"
			if p == 4:
				if proportion[p] > 1:
					sys_name += "oxid"
				else:
					sys_name += "xid"
	
	return sys_name

func _process(delta):
	if atoms.size() > 0:
		$HUD/UI/Info/Active.text = "Aktives Atom / Bindung: " + String(active_atom) + " / " + String(atoms[active_atom].active_connector)
		
		$HUD/UI/Info/Proportion.text = "Verhältnis: " + get_prop_label()
		$HUD/UI/Info/Systematic_Name.text = "Systematischer Name: " + get_sys_name_label()
		
		if atoms[active_atom].atom_connections[atoms[active_atom].active_connector] == -1 and atoms[active_atom]._get_free_conns().size() >= $HUD.bond_type and avail_connections > 0 and atoms[active_atom].connections >= $HUD.bond_type and holo_atom.connections >= $HUD.bond_type:
			$HUD/UI/Atom_Platzieren/Place.disabled = false
			holo_atom.show()
	else:
		if holo_atom.connections >= $HUD.bond_type:
			$HUD/UI/Atom_Platzieren/Place.disabled = false
			holo_atom.show()