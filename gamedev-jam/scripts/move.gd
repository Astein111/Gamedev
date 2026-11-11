extends CollisionShape2D

@export var start_speed: float = 160.0
@export var max_speed: float = 400.0
@export var time_to_max_speed: float = 0.75

@export var jump_velocity: float = -500.0
@export var gravity: float = 1000.0
@export_range(0.1, 1.0) var jump_cut: float = 0.4

@onready var body: CharacterBody2D = get_parent() as CharacterBody2D


func _ready() -> void:
	if body == null:
		push_warning("CollisionShape2D must be a child of a CharacterBody2D for movement to work.")


func _physics_process(delta: float) -> void:
	if body == null:
		return

	# Apply gravity
	if not body.is_on_floor():
		body.velocity.y += gravity * delta

	# Start jump
	if Input.is_action_just_pressed("Jump") and body.is_on_floor():
		body.velocity.y = jump_velocity

	# Cut jump short if Jump is released while still moving up
	if Input.is_action_just_released("Jump") and body.velocity.y < 0.0:
		body.velocity.y *= jump_cut

	# Start at start_speed and reach max_speed in time_to_max_speed seconds
	var direction: float = Input.get_axis("Left", "Right")
	if direction != 0.0:
		var effective_start: float = clampf(start_speed, 0.0, max_speed)
		var target_start: float = direction * effective_start
		if signf(body.velocity.x) != signf(direction) or absf(body.velocity.x) < absf(target_start):
			body.velocity.x = target_start

		var accel: float = (max_speed - effective_start) / maxf(time_to_max_speed, 0.001)
		body.velocity.x = move_toward(body.velocity.x, direction * max_speed, accel * delta)
	else:
		body.velocity.x = 0.0

	body.move_and_slide()
