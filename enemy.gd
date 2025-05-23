extends CharacterBody2D

@export var speed: float = 200
@export var gravity: float = 800
@export var attack_range: float = 80
@export var attack_duration: float = 0.6
@export var walk_duration: float = 2.0
@export var idle_duration: float = 1.5

@onready var detection_area = $DetectionArea
@onready var direction_timer = $DirectionTimer

enum State { IDLE, PATROL, CHASE, ATTACK, STAGGER }
var state = State.IDLE

var player: Node2D = null
var direction: Vector2 = Vector2.LEFT
var walk_timer = 0.0
var idle_timer = 0.0
var health = 3

func _ready():
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	direction_timer.timeout.connect(_on_direction_timer_timeout)
	change_state(State.PATROL)

func _process(_delta):
	if state == State.STAGGER:
		return

	if player:
		var distance = global_position.distance_to(player.global_position)

		if distance <= attack_range:
			if state != State.ATTACK:
				change_state(State.ATTACK)
		else:
			if state != State.CHASE:
				change_state(State.CHASE)
	else:
		if state not in [State.PATROL, State.IDLE]:
			change_state(State.PATROL)

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
			$AnimatedSprite2D.play("Idle")
			if not direction_timer.is_stopped():
				direction_timer.start()

		State.PATROL:
			walk_timer = walk_duration
			$AnimatedSprite2D.play("Walk")
			direction_timer.start()

		State.CHASE:
			$AnimatedSprite2D.play("Walk")
			direction_timer.stop()

		State.ATTACK:
			$AnimatedSprite2D.play("Attack")
			direction_timer.stop()
			perform_attack()

		State.STAGGER:
			$AnimatedSprite2D.play("Stagger")
			direction_timer.stop()
			stagger()

func perform_attack():
	await get_tree().create_timer(attack_duration).timeout

	if player and player.is_parrying:
		change_state(State.STAGGER)
	else:
		$AttackArea.monitoring = true
		await get_tree().create_timer(0.2).timeout
		$AttackArea.monitoring = false
		change_state(State.IDLE)

func stagger():
	await get_tree().create_timer(1.0).timeout
	change_state(State.IDLE)

func flash_on_hit():
	$AnimatedSprite2D.modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	$AnimatedSprite2D.modulate = Color(1, 1, 1)

func _on_direction_timer_timeout():
	direction = -direction
	$AnimatedSprite2D.flip_h = not $AnimatedSprite2D.flip_h

func _flip_sprite(x: float):
	$AnimatedSprite2D.flip_h = x < 0

func _on_player_detected(body: Node2D):
	if body.name == "Player":
		player = body

func _on_player_lost(body: Node2D):
	if body.name == "Player":
		player = null
		change_state(State.PATROL)

func die():
	queue_free()
