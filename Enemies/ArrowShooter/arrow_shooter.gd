extends CharacterBody2D

@export var speed: float = 200
@export var gravity: float = 800
@export var attack_range: float = 3000
@export var shoot_interval: float = 2.0
@export var arrow_scene := preload("res://Enemies/ArrowShooter/Projectile/arrow_projectile.tscn")
@export var idle_duration: float = 1.5
@export var walk_duration: float = 2.0
@onready var posture_bar = $PostureBar

@export var max_posture: int = 30
var current_posture: int = max_posture

@onready var detection_area = $DetectionArea
@onready var direction_timer = $DirectionTimer
@onready var shoot_timer = $ShootTimer
@onready var anim = $AnimatedSprite2D
@onready var arrow_spawn = $ArrowSpawnPoint

enum State { IDLE, PATROL, CHASE, ATTACK, STAGGER }
var state = State.IDLE
@export var deathblow_window := 1.0
var in_deathblow_state := false
var deathblow_pending := false

var player: Node2D = null
var direction: Vector2 = Vector2.LEFT
var walk_timer = 0.0
var idle_timer = 0.0
var is_attacking = false
var health = 10
var has_fired_arrow := false

func _ready():
	$Hurtbox.owner = self  # 👈 allows get_parent() to work correctly
	add_to_group("enemies")
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	direction_timer.timeout.connect(_on_direction_timer_timeout)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	change_state(State.PATROL)

func _process(_delta):
	if state == State.STAGGER:
		return

	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance <= attack_range:
			change_state(State.ATTACK)
		else:
			change_state(State.CHASE)
	else:
		change_state(State.PATROL)

	if anim.animation == "Attack1":
		if anim.frame == 6 and not has_fired_arrow:
			print("\uD83C\uDFAF Frame 6 reached — SHOOTING!")
			shoot_arrow()
			has_fired_arrow = true
		elif anim.frame < 6:
			has_fired_arrow = false
	else:
		has_fired_arrow = false

func _physics_process(delta):
	velocity.y += gravity * delta

	match state:
		State.IDLE:
			velocity.x = 0
			idle_timer -= delta
			if idle_timer <= 0:
				change_state(State.PATROL)

		State.PATROL:
			velocity.x = direction.x * speed * 0.5
			walk_timer -= delta
			if walk_timer <= 0:
				change_state(State.IDLE)

		State.CHASE:
			if player:
				var dx = player.global_position.x - global_position.x
				if abs(dx) > 4:
					var chase_dir = sign(dx)
					velocity.x = chase_dir * speed
					_flip_sprite(chase_dir)
				else:
					velocity.x = 0

		State.ATTACK:
			velocity.x = 0

		State.STAGGER:
			velocity.x = 0

	move_and_slide()

func change_state(new_state: State):
	if state == new_state:
		return

	state = new_state

	match state:
		State.IDLE:
			idle_timer = idle_duration
			anim.play("Idle")
			if not direction_timer.is_stopped():
				direction_timer.start()

		State.PATROL:
			walk_timer = walk_duration
			anim.play("Walk")
			direction_timer.start()

		State.CHASE:
			anim.play("Walk")
			direction_timer.stop()

		State.ATTACK:
			_flip_sprite(sign(player.global_position.x - global_position.x))
			anim.stop()
			anim.frame = 0
			anim.play("Attack1")
			direction_timer.stop()
			shoot_timer.start(shoot_interval)

		State.STAGGER:
			anim.play("Hurt")
			direction_timer.stop()
			stagger()

func _on_shoot_timer_timeout():
	if state == State.ATTACK:
		anim.stop()
		anim.frame = 0
		anim.play("Attack1")
		shoot_timer.start(shoot_interval)

func shoot_arrow():
	if not player:
		return

	var arrow = arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)

	arrow.global_position = arrow_spawn.global_position
	var dir = (player.global_position - arrow.global_position).normalized()
	arrow.initialize(dir, 1500)  # adjust speed if needed

	if "is_parryable" in arrow:
		arrow.is_parryable = true

func stagger():
	posture_bar.visible = false
	current_posture = max_posture
	posture_bar.value = current_posture
	await get_tree().create_timer(1.0).timeout
	change_state(State.IDLE)


func flash_on_hit():
	anim.modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	anim.modulate = Color(1, 1, 1)

func _on_direction_timer_timeout():
	direction = -direction
	anim.flip_h = not anim.flip_h

func _flip_sprite(x: float):
	anim.flip_h = x < 0

	var offset = abs(arrow_spawn.position.x)
	var flip_sign = -1 if anim.flip_h else 1
	arrow_spawn.position.x = offset * flip_sign

func _on_player_detected(body: Node2D):
	if body.name == "Player":
		player = body

func _on_player_lost(body: Node2D):
	if body.name == "Player":
		player = null
		change_state(State.PATROL)

func take_damage(amount := 1):
	print("💊 ArrowShooter took damage! HP left:", health)
	health -= amount
	flash_on_hit()
	if health <= 0:
		die()
		
func is_alive() -> bool:
	return health > 0
	
func trigger_deathblow():
	in_deathblow_state = true
	deathblow_pending = true
	state = State.STAGGER

	anim.play("Hurt")
	await get_tree().create_timer(0.4).timeout
	anim.play("DeathblowReady")

	if player and player.has_method("set_deathblow_target"):
		player.set_deathblow_target(self)

	await get_tree().create_timer(2.0).timeout
	if is_alive() and deathblow_pending:
		in_deathblow_state = false
		deathblow_pending = false
		change_state(State.IDLE)


func die():
	queue_free()

func apply_posture_damage(amount: int):
	if state == State.STAGGER or not is_alive():
		return

	current_posture -= amount
	posture_bar.visible = true
	posture_bar.value = current_posture

	if current_posture <= 0:
		await trigger_deathblow()

func deathblow():
	if not is_alive():
		return

	health = 0
	in_deathblow_state = false
	deathblow_pending = false

	anim.play("Death")
	await get_tree().create_timer(0.5).timeout
	queue_free()
