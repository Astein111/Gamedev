extends CharacterBody2D
@export var gravity: float = 360.0
@export var max_fall_speed: float = 340.0
@export var spin_speed: float = 8.0
@export var wait_for_first_hit: bool = true
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var timer: Timer = get_node_or_null("StallTimer") if has_node("StallTimer") else get_node_or_null("Timer") as Timer

var gravity_dir: float = 1.0
var active: bool = false
func _ready() -> void:
	add_to_group("ball")
	active = not wait_for_first_hit
	_ignore_player_collision.call_deferred()
func _ignore_player_collision() -> void:
	var scene: Node = get_tree().current_scene
	if scene:
		var mc: Node = scene.find_child("MC", true, false)
		if mc is CollisionObject2D:
			add_collision_exception_with(mc)
func _physics_process(delta: float) -> void:
	if not active:
		return
	if sprite:
		sprite.rotation += spin_speed * delta
	if timer and not timer.is_stopped():
		velocity = Vector2.ZERO
		if sprite:
			sprite.modulate = Color.CYAN
		return
	if sprite:
		sprite.modulate = Color.WHITE
	velocity.y += gravity * gravity_dir * delta
	move_and_slide()
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider and (collider.name == "MC" or (collider is Node and collider.is_in_group("player"))):
			continue
		print("Ball hit the room! You lose!")
		get_tree().reload_current_scene()
		return
func launch(launch_velocity: Vector2) -> void:
	active = true
	if timer:
		timer.stop()
	velocity = launch_velocity
func stall(duration: float) -> void:
	active = true
	if timer:
		timer.start(duration)
func set_gravity_dir(new_dir: float) -> void:
	gravity_dir = new_dir
	up_direction = Vector2.UP * gravity_dir
