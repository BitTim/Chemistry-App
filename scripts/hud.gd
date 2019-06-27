extends Control

signal select_atom(atom_type)
signal place_atom(atom_type)
signal delete_atom
signal rotate_atom
signal reset_mode(mode)
signal hide_GUI
signal show_GUI

var mode = 0
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
	
	$UI/Atom_Drehen/Rotate.connect("button_down", self, "_on_atom_rotate")
	
	$UI/Mode_Select/Place.connect("button_down", self, "_on_mode_place_down")
	$UI/Mode_Select/Rotate.connect("button_down", self, "_on_mode_rotate_down")
	$UI/Mode_Select/Move.connect("button_down", self, "_on_mode_move_down")
	$UI/Mode_Select/Zoom.connect("button_down", self, "_on_mode_zoom_down")

	$GUI_Control/Hide.connect("button_down", self, "_on_hide")
	$GUI_Control/Reset_Mode.connect("button_down", self, "_on_reset_mode")
	
	$ConfirmationDialog.get_label().autowrap = true
	$ConfirmationDialog.get_close_button().hide()

func update_conn_display(avail, maxi):
	$UI/Info/Conns.text = String(avail) + " / " + String(maxi) 

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
	else:
		emit_signal("hide_GUI")
		$UI.hide()

func _on_reset_mode():
	emit_signal("reset_mode", mode)

func _process(delta):
	var curr_window_size = OS.get_window_size()
	if curr_window_size != prev_win_size:
			rect_scale = Vector2(OS.get_window_size().x / 1024, OS.get_window_size().y / 600)