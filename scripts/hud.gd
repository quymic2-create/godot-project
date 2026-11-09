extends CanvasLayer

@export var show_mobile_controls: bool = false

const JOYSTICK_SCRIPT = preload("res://scripts/virtual_joystick.gd")

var player
var joystick: Control
var _touch_controls_enabled: bool = false


func _ready() -> void:
	player = get_node("../Player")
	_touch_controls_enabled = OS.has_feature("mobile") or show_mobile_controls
	_create_crosshair()
	_create_instructions()
	if _touch_controls_enabled:
		_create_touch_controls()


func are_touch_controls_enabled() -> bool:
	return _touch_controls_enabled


func get_move_vector() -> Vector2:
	if joystick != null:
		var result: Vector2 = joystick.call("get_output")
		return result
	return Vector2.ZERO


func _create_crosshair() -> void:
	var crosshair := Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "+"
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 25)
	crosshair.add_theme_color_override("font_color", Color.WHITE)
	crosshair.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	crosshair.add_theme_constant_override("shadow_offset_x", 1)
	crosshair.add_theme_constant_override("shadow_offset_y", 1)
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -12.0
	crosshair.offset_top = -16.0
	crosshair.offset_right = 12.0
	crosshair.offset_bottom = 16.0
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(crosshair)


func _create_instructions() -> void:
	var instructions := Label.new()
	instructions.name = "Instructions"
	if _touch_controls_enabled:
		instructions.text = "BLOCKWORLD  |  Swipe right to look  |  Buttons: jump / break / place"
	else:
		instructions.text = "BLOCKWORLD  |  WASD move  |  SPACE jump  |  Left click break  |  Right click place  |  1-3 select block  |  ESC release mouse"
	instructions.position = Vector2(16.0, 12.0)
	instructions.add_theme_font_size_override("font_size", 15)
	instructions.add_theme_color_override("font_color", Color.WHITE)
	instructions.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	instructions.add_theme_constant_override("shadow_offset_x", 1)
	instructions.add_theme_constant_override("shadow_offset_y", 1)
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(instructions)


func _create_touch_controls() -> void:
	joystick = JOYSTICK_SCRIPT.new()
	joystick.name = "VirtualJoystick"
	joystick.anchor_left = 0.0
	joystick.anchor_top = 1.0
	joystick.anchor_right = 0.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 24.0
	joystick.offset_top = -190.0
	joystick.offset_right = 184.0
	joystick.offset_bottom = -30.0
	joystick.z_index = 5
	add_child(joystick)

	var jump_button := _make_bottom_right_button("JUMP", -132.0, -202.0, -24.0, -142.0)
	jump_button.pressed.connect(func(): player.call("request_jump"))
	var break_button := _make_bottom_right_button("BREAK", -270.0, -140.0, -164.0, -80.0)
	break_button.pressed.connect(func(): player.call("attempt_break"))
	var place_button := _make_bottom_right_button("PLACE", -154.0, -140.0, -48.0, -80.0)
	place_button.pressed.connect(func(): player.call("attempt_place"))

	var grass_button := _make_hotbar_button("GRASS", -137.0, -51.0)
	grass_button.pressed.connect(func(): player.call("select_block", 1))
	var dirt_button := _make_hotbar_button("DIRT", -44.0, 42.0)
	dirt_button.pressed.connect(func(): player.call("select_block", 2))
	var stone_button := _make_hotbar_button("STONE", 49.0, 135.0)
	stone_button.pressed.connect(func(): player.call("select_block", 3))


func _make_bottom_right_button(label_text: String, left_offset: float, top_offset: float, right_offset: float, bottom_offset: float) -> Button:
	var button := Button.new()
	button.text = label_text
	button.anchor_left = 1.0
	button.anchor_top = 1.0
	button.anchor_right = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = left_offset
	button.offset_top = top_offset
	button.offset_right = right_offset
	button.offset_bottom = bottom_offset
	button.add_theme_font_size_override("font_size", 15)
	button.z_index = 6
	add_child(button)
	return button


func _make_hotbar_button(label_text: String, left_offset: float, right_offset: float) -> Button:
	var button := Button.new()
	button.text = label_text
	button.anchor_left = 0.5
	button.anchor_top = 1.0
	button.anchor_right = 0.5
	button.anchor_bottom = 1.0
	button.offset_left = left_offset
	button.offset_top = -62.0
	button.offset_right = right_offset
	button.offset_bottom = -14.0
	button.add_theme_font_size_override("font_size", 14)
	button.z_index = 6
	add_child(button)
	return button
