extends Control

var output: Vector2 = Vector2.ZERO
var _active_touch_index: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func get_output() -> Vector2:
	return output


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and get_global_rect().has_point(event.position):
			_active_touch_index = event.index
			_update_output(event.position)
			accept_event()
		elif not event.pressed and event.index == _active_touch_index:
			_active_touch_index = -1
			output = Vector2.ZERO
			queue_redraw()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _active_touch_index:
		_update_output(event.position)
		accept_event()


func _update_output(screen_position: Vector2) -> void:
	var center: Vector2 = get_global_rect().position + size * 0.5
	var radius: float = minf(size.x, size.y) * 0.36
	var delta: Vector2 = (screen_position - center) / maxf(radius, 1.0)
	if delta.length() > 1.0:
		delta = delta.normalized()
	output = delta
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.45
	draw_circle(center, radius, Color(0.05, 0.07, 0.09, 0.34))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.9, 0.95, 1.0, 0.6), 2.0)
	draw_circle(center + output * radius * 0.62, radius * 0.34, Color(0.85, 0.9, 0.96, 0.58))
