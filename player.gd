extends CharacterBody3D

@export var move_speed: float = 5.5
@export var jump_strength: float = 8.5
@export var gravity: float = 24.0
@export var mouse_sensitivity: float = 0.0025

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var block_ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var world: Node = get_node("../World")
@onready var hud = get_node("../HUD")

var _jump_queued: bool = false
var selected_block_id: int = 1


func _ready() -> void:
	block_ray.enabled = true
	block_ray.add_exception(self)

	var camera_environment := Environment.new()
	camera_environment.background_mode = Environment.BG_COLOR
	camera_environment.background_color = Color(0.52, 0.73, 0.92)
	camera_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	camera_environment.ambient_light_color = Color(0.82, 0.86, 0.91)
	camera_environment.ambient_light_energy = 0.8
	camera.environment = camera_environment

	if not OS.has_feature("mobile") and not bool(hud.get("show_mobile_controls")):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var move_input := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_input.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_input.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_input.y += 1.0

	var touch_input: Vector2 = hud.call("get_move_vector")
	if touch_input.length() > move_input.length():
		move_input = touch_input
	if move_input.length() > 1.0:
		move_input = move_input.normalized()

	var move_direction: Vector3 = transform.basis * Vector3(move_input.x, 0.0, move_input.y)
	move_direction.y = 0.0
	if move_direction.length_squared() > 1.0:
		move_direction = move_direction.normalized()

	velocity.x = move_direction.x * move_speed
	velocity.z = move_direction.z * move_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	if _jump_queued and is_on_floor():
		velocity.y = jump_strength
	_jump_queued = false

	move_and_slide()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_apply_look(event.relative)
	elif event is InputEventScreenDrag:
		var viewport_width: float = get_viewport().get_visible_rect().size.x
		if event.position.x > viewport_width * 0.38:
			_apply_look(event.relative)
	elif event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not bool(hud.call("are_touch_controls_enabled")):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			attempt_break()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			attempt_place()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_SPACE:
			request_jump()
		elif event.keycode == KEY_1:
			select_block(1)
		elif event.keycode == KEY_2:
			select_block(2)
		elif event.keycode == KEY_3:
			select_block(3)


func _apply_look(relative_motion: Vector2) -> void:
	rotate_y(-relative_motion.x * mouse_sensitivity)
	head.rotate_x(-relative_motion.y * mouse_sensitivity)
	head.rotation.x = clampf(head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))


func request_jump() -> void:
	_jump_queued = true


func attempt_break() -> void:
	block_ray.force_raycast_update()
	if not block_ray.is_colliding():
		return
	world.call("break_block", block_ray.get_collision_point(), block_ray.get_collision_normal())


func attempt_place() -> void:
	block_ray.force_raycast_update()
	if not block_ray.is_colliding():
		return
	world.call(
		"place_block",
		block_ray.get_collision_point(),
		block_ray.get_collision_normal(),
		global_position,
		selected_block_id
	)


func select_block(block_id: int) -> void:
	selected_block_id = clampi(block_id, 1, 3)
