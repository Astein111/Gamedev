extends CharacterBody2D

signal gravity_switched(new_gravity_dir: float)

@export var start_speed: float = 160.0
@export var max_speed: float = 400.0
@export var time_to_max_speed: float = 0.75

@export var jump_velocity: float = -500.0
@export var gravity: float = 1000.0
@export_range(0.1, 1.0) var jump_cut: float = 0.4

@export var restart_hold_time: float = 1.0
@export var max_teleport_distance: float = 3000.0
@export var show_aim_line: bool = true

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D

var facing_dir: float = 1.0
var gravity_dir: float = 1.0 # 1.0 = normal (down), -1.0 = inverted (ceiling)
var aim_dir: Vector2 = Vector2.RIGHT
var _restart_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if _handle_restart(delta):
		return

	# Gravity switch + parallel teleport to ceiling/floor
	if InputMap.has_action("GravitySwitch") and Input.is_action_just_pressed("GravitySwitch"):
		_switch_gravity()

	# Apply gravity in current direction
	if not is_on_floor():
		velocity.y += gravity * gravity_dir * delta

	# Start jump away from current floor/ceiling
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_velocity * gravity_dir

	# Cut jump short if Jump is released early
	if Input.is_action_just_released("Jump") and (velocity.y * gravity_dir) < 0.0:
		velocity.y *= jump_cut

	# Start at start_speed and reach max_speed in time_to_max_speed seconds
	var direction: float = Input.get_axis("Left", "Right")
	if direction != 0.0:
		facing_dir = signf(direction)
		if sprite:
			sprite.flip_h = (facing_dir < 0.0)

		var effective_start: float = clampf(start_speed, 0.0, max_speed)
		var target_start: float = direction * effective_start
		if signf(velocity.x) != signf(direction) or absf(velocity.x) < absf(target_start):
			velocity.x = target_start

		var accel: float = (max_speed - effective_start) / maxf(time_to_max_speed, 0.001)
		velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)
	else:
		velocity.x = 0.0

	aim_dir = _get_aim_direction()
	queue_redraw()
	move_and_slide()


func _handle_restart(delta: float) -> bool:
	if InputMap.has_action("Restart") and Input.is_action_pressed("Restart"):
		_restart_timer += delta
		if _restart_timer >= restart_hold_time:
			get_tree().reload_current_scene()
			return true
	else:
		_restart_timer = 0.0
	return false


func _switch_gravity() -> void:
	var new_gravity_dir: float = -gravity_dir
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var ray_end: Vector2 = global_position + Vector2(0.0, new_gravity_dir * max_teleport_distance)

	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, ray_end)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]

	var hit: Dictionary = space_state.intersect_ray(query)
	if hit.is_empty():
		return

	gravity_dir = new_gravity_dir
	up_direction = Vector2.UP * gravity_dir
	velocity.y = 0.0

	if sprite:
		sprite.flip_v = (gravity_dir < 0.0)

	var extent: float = _get_collider_extent_in_dir(gravity_dir)
	global_position.y = hit.position.y - gravity_dir * (extent + 1.0)
	gravity_switched.emit(gravity_dir)


func _get_collider_extent_in_dir(dir_y: float) -> float:
	var col_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col_shape == null or col_shape.shape == null:
		return 32.0

	var rect: Rect2 = col_shape.shape.get_rect()
	var scale_y: float = absf(col_shape.global_scale.y)
	var offset_y: float = col_shape.position.y * absf(global_scale.y)
	if dir_y > 0.0:
		return offset_y + rect.end.y * scale_y
	return -(offset_y + rect.position.y * scale_y)


func _get_aim_direction() -> Vector2:
	var aim_x: float = Input.get_axis("Left", "Right")
	var aim_y: float = 0.0
	if InputMap.has_action("Up") and InputMap.has_action("Down"):
		aim_y = Input.get_axis("Up", "Down")

	var raw_aim: Vector2 = Vector2(aim_x, aim_y)
	if raw_aim != Vector2.ZERO:
		return raw_aim.normalized()

	return Vector2(facing_dir, 0.0)


func _draw() -> void:
	if not show_aim_line:
		return
	var end: Vector2 = aim_dir * 100.0
	draw_line(Vector2.ZERO, end, Color.YELLOW, 3.0)
	draw_circle(end, 6.0, Color.YELLOW)
