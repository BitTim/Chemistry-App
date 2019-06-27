extends Node

signal swipe(direction)
signal swipe_canceled(start_position)
export(float, 1.0, 1.5) var MAX_DIAG_SLOPE = 1.3

var swipe_start_pos = Vector2()

func _ready():
	$Timer.connect("timeout", self, "_on_timer_timeout")

func _input(event):
	if not event is InputEventScreenTouch:
		return
	if event.pressed:
		_start_detection(event.position)
	elif not $Timer.is_stopped():
		_end_detection(event.position)

func _start_detection(pos):
	swipe_start_pos = pos
	$Timer.start()

func _end_detection(pos):
	$Timer.stop()
	var dir = (pos - swipe_start_pos).normalized()
	
	if abs(dir.x) + abs(dir.y) >= MAX_DIAG_SLOPE:
		return
	
	if abs(dir.x) > abs(dir.y):
		emit_signal("swipe", Vector2(-sign(dir.x), 0.0))
	else:
		emit_signal("swipe", Vector2(0.0, -sign(dir.y)))

func _on_timer_timeout():
	emit_signal('swipe_canceled', swipe_start_pos)