extends Control

signal select_atom(atom_type)
signal place_atom(atom_type)
signal delete_atom
signal rotate_atom
signal bond_change(bond_type)
signal reset_mode(mode)
signal hide_GUI
signal show_GUI

var mode = 0
var bond_type = 1
var selected_type = 0
onready var prev_win_size = OS.get_window_size()

func _ready():
	rect_scale = Vector2(OS.get_window_size().x / 1024, OS.get_window_size().y / 600)
	
	$UI/Atom_Auswahl/Wasserstoff.connect("button_down", self, "_on_h_btn_down")
	$UI/Atom_Auswahl/Kohlenstoff.connect("button_down", self, "_on_c_btn_down")
	$UI/Atom_Auswahl/Sauerstoff.connect("button_down", self, "_on_o_btn_down")
	$UI/Atom_Auswahl/Stickstoff.connect("button_down", self, "_on_n_btn_down")
	$UI/Atom_Auswahl/Chlor.connect("button_down", self, "_on_cl_btn_down")
	
	$UI/Atom_Platzieren/Delete.connect("button_down", self, "_on_delete_btn_down")
	$UI/Atom_Platzieren/Place.connect("button_down", self, "_on_atom_place_down")
	
	$UI/Atom_Manipulieren/Rotate.connect("button_down", self, "_on_atom_rotate")
	$UI/Atom_Manipulieren/Bond.connect("button_down", self, "_on_bond_change")
	
	$UI/Mode_Select/Place.connect("button_down", self, "_on_mode_place_down")
	$UI/Mode_Select/Rotate.connect("button_down", self, "_on_mode_rotate_down")
	$UI/Mode_Select/Move.connect("button_down", self, "_on_mode_move_down")
	$UI/Mode_Select/Zoom.connect("button_down", self, "_on_mode_zoom_down")

	$GUI_Control/Hide.connect("button_down", self, "_on_hide")
	$GUI_Control/Reset_Mode.connect("button_down", self, "_on_reset_mode")
	
	$UI/Info_Control/i.connect("button_down", self, "_on_i_down")
	$UI/Info_Control/iplus.connect("button_down", self, "_on_iplus_down")
	
	$ConfirmationDialog.get_label().autowrap = true
	$ConfirmationDialog.get_close_button().hide()

func update_conn_display(avail, maxi):
	$UI/Info/Conns.text = "Freie Bindungen: " + String(avail) + " / " + String(maxi) 

func _on_h_btn_down():
	emit_signal("select_atom", 0)
	selected_type = 0

func _on_c_btn_down():
	emit_signal("select_atom", 1)
	selected_type = 1

func _on_o_btn_down():
	emit_signal("select_atom", 2)
	selected_type = 2

func _on_n_btn_down():
	emit_signal("select_atom", 3)
	selected_type = 3

func _on_cl_btn_down():
	emit_signal("select_atom", 4)
	selected_type = 4

func _on_atom_place_down():
	emit_signal("place_atom", selected_type)

func _on_delete_btn_down():
	emit_signal("delete_atom")

func _on_atom_rotate():
	emit_signal("rotate_atom")

func _on_bond_change():
	bond_type += 1
	if bond_type > 3:
		bond_type = 1
	
	if bond_type == 1:
		$UI/Atom_Manipulieren/Bond.texture_normal = load("res://assets/icons/connections/Single_Bond_Normal.png")
		$UI/Atom_Manipulieren/Bond.texture_pressed = load("res://assets/icons/connections/Single_Bond_Pressed.png")
		$UI/Atom_Manipulieren/Bond.texture_hover = load("res://assets/icons/connections/Single_Bond_Hover.png")
	if bond_type == 2:
		$UI/Atom_Manipulieren/Bond.texture_normal = load("res://assets/icons/connections/Double_Bond_Normal.png")
		$UI/Atom_Manipulieren/Bond.texture_pressed = load("res://assets/icons/connections/Double_Bond_Pressed.png")
		$UI/Atom_Manipulieren/Bond.texture_hover = load("res://assets/icons/connections/Double_Bond_Hover.png")
	if bond_type == 3:
		$UI/Atom_Manipulieren/Bond.texture_normal = load("res://assets/icons/connections/Tripple_Bond_Normal.png")
		$UI/Atom_Manipulieren/Bond.texture_pressed = load("res://assets/icons/connections/Tripple_Bond_Pressed.png")
		$UI/Atom_Manipulieren/Bond.texture_hover = load("res://assets/icons/connections/Tripple_Bond_Hover.png")
	
	emit_signal("bond_change", bond_type)

func _on_mode_place_down():
	if mode == 0:
		$UI/Mode_Select/Place.pressed = false
	else:
		mode = 0
		$UI/Mode_Select/Rotate.pressed = false
		$UI/Mode_Select/Move.pressed = false
		$UI/Mode_Select/Zoom.pressed = false

func _on_mode_rotate_down():
	if mode == 1:
		$UI/Mode_Select/Rotate.pressed = false
	else:
		mode = 1
		$UI/Mode_Select/Place.pressed = false
		$UI/Mode_Select/Move.pressed = false
		$UI/Mode_Select/Zoom.pressed = false

func _on_mode_move_down():
	if mode == 2:
		$UI/Mode_Select/Move.pressed = false
	else:
		mode = 2
		$UI/Mode_Select/Place.pressed = false
		$UI/Mode_Select/Rotate.pressed = false
		$UI/Mode_Select/Zoom.pressed = false

func _on_mode_zoom_down():
	if mode == 3:
		$UI/Mode_Select/Zoom.pressed = false
	else:
		mode = 3
		$UI/Mode_Select/Place.pressed = false
		$UI/Mode_Select/Rotate.pressed = false
		$UI/Mode_Select/Move.pressed = false

func _on_hide():
	if $GUI_Control/Hide.is_pressed():
		emit_signal("show_GUI")
		$UI.show()
		$GUI_Control/Placeholder.hide()
		$GUI_Control/Reset_Mode.show()
	else:
		emit_signal("hide_GUI")
		$UI.hide()
		$GUI_Control/Placeholder.show()
		$GUI_Control/Reset_Mode.hide()

func _on_reset_mode():
	emit_signal("reset_mode", mode)

func _on_i_down():
	if $UI/Info_Control/i.pressed:
		$UI/Info/Proportion.hide()
		$UI/Info/Systematic_Name.hide()
	else:
		$UI/Info/Proportion.show()
		$UI/Info/Systematic_Name.show()

func _on_iplus_down():
	if $UI/Info_Control/iplus.pressed:
		$UI/Info/Active.hide()
		$UI/Info/Conns.hide()
		$UI/Info/Rotation.hide()
	else:
		$UI/Info/Active.show()
		$UI/Info/Conns.show()
		$UI/Info/Rotation.show()

func _process(delta):
	var curr_window_size = OS.get_window_size()
	if curr_window_size != prev_win_size:
			rect_scale = Vector2(OS.get_window_size().x / 1024, OS.get_window_size().y / 600)