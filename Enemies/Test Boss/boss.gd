extends CharacterBody2D

enum State { IDLE, WINDUP, ATTACKING, STAGGERED, DEAD }
var current_state = State.IDLE

@export var max_health = 10
var current_health = max_health
var parry_count = 0

var current_attack_name = "Attack1"
var is_faking_out = false

@onready var posture_bar = $PostureBar

var is_attack_dangerous = false

var attack_damage_applied = false


@onready var parry_area = $Area2D
@onready var anim = $AnimatedSprite2D
@onready var attack_area = $AttackArea
var player = null

@export var gravity = 800
@export var move_speed = 100
@export var windup_time = 0.5
@export var attack_duration = 1.0
@export var attack_cooldown = 2.0
@export var damage_interval = 1.0

var attack_timer = 0.0
var damage_cooldown = 0.0
var player_inside = false
var last_attack_frame = -1
var attack_elapsed := 0.0

func _ready():
	add_to_group("enemies")

	var root = get_tree().get_root()
	if root.has_node("World/Player"):
		
		player = root.get_node("World/Player")
	else:
		
		player = null

	attack_area.body_entered.connect(_on_AttackArea_body_entered)
	attack_area.body_exited.connect(_on_AttackArea_body_exited)
	attack_area.monitoring = false
	attack_timer = attack_cooldown
	add_to_group("parryable")

func _physics_process(delta):
	velocity.y += gravity * delta
	move_and_slide()

	if player:
		var flip = player.global_position.x < global_position.x
		anim.flip_h = flip

	match current_state:
		State.IDLE:
			attack_timer -= delta
			if attack_timer <= 0:
				start_windup()

		State.WINDUP:
			pass

		State.ATTACKING:
			update_attack_frame()
			attack_elapsed += delta
			if attack_elapsed >= attack_duration:
				end_attack()

			if player_inside:
				damage_cooldown -= delta
				if damage_cooldown <= 0:
					damage_cooldown = damage_interval
					if player and player.has_method("take_damage"):
						player.take_damage()

func start_windup():
	if current_state != State.IDLE:
		return

	current_state = State.WINDUP
	anim.play("Windup")

	is_faking_out = randi() % 4 == 0

	if is_faking_out:
		
		await get_tree().create_timer(windup_time * 0.6).timeout
		anim.play("Idle")
		current_state = State.IDLE
		attack_timer = attack_cooldown * 0.5
		is_faking_out = false
	else:
		await get_tree().create_timer(windup_time).timeout
		start_attack()

func start_attack():
	if current_state == State.DEAD or current_state == State.STAGGERED:
		return

	if player:
		var flip = player.global_position.x < global_position.x
		anim.flip_h = flip
		attack_area.scale.x = -1 if flip else 1
		parry_area.scale.x = -1 if flip else 1

		

	current_state = State.ATTACKING
	var attacks = ["Attack1", "Attack2"]
	current_attack_name = attacks[randi() % attacks.size()]
	anim.play(current_attack_name)
	
	anim.frame = 0
	attack_damage_applied = false


	last_attack_frame = -1
	parry_area.is_parryable = false
	attack_area.monitoring = false
	damage_cooldown = 0.0
	attack_elapsed = 0.0
	

func update_attack_frame():
	var current_frame = anim.frame

	match current_attack_name:
		"Attack1":
			match current_frame:
				2, 3, 4:
					parry_area.is_parryable = true
					attack_area.monitoring = false
				5:
					if not attack_damage_applied:
						parry_area.is_parryable = false
						attack_area.monitoring = true
						damage_cooldown = 0.0
						attack_damage_applied = true

						await get_tree().create_timer(0.1).timeout
						attack_area.monitoring = false
				_:
					parry_area.is_parryable = false
					attack_area.monitoring = false

		"Attack2":
			match current_frame:
				3, 4:
					parry_area.is_parryable = true
					attack_area.monitoring = false
				5:
					if not attack_damage_applied:
						parry_area.is_parryable = false
						attack_area.monitoring = true
						damage_cooldown = 0.0
						attack_damage_applied = true

						await get_tree().create_timer(0.1).timeout
						attack_area.monitoring = false
				_:
					parry_area.is_parryable = false
					attack_area.monitoring = false

	if current_frame != last_attack_frame:
		
		last_attack_frame = current_frame


func start_attack_window(duration := 0.1):
	attack_area.monitoring = true
	damage_cooldown = 0.0
	await get_tree().create_timer(duration).timeout
	attack_area.monitoring = false

func end_attack():
	parry_area.is_parryable = false
	attack_area.monitoring = false
	current_state = State.IDLE
	attack_timer = attack_cooldown

func _on_AttackArea_body_entered(body):
	if body.name == "Player":
		player_inside = true

func _on_AttackArea_body_exited(body):
	if body.name == "Player":
		player_inside = false

func on_parried():
	if current_state == State.DEAD:
		return

	parry_count += 1
	if posture_bar:
		posture_bar.value = parry_count
		

	if posture_bar:
		posture_bar.value = parry_count

	if parry_count >= 3:
		enter_stagger()
		return

	if current_state == State.ATTACKING:
		parry_area.is_parryable = false
		attack_area.monitoring = false
		
		return_to_windup()

func return_to_windup():
	current_state = State.WINDUP
	anim.play("Windup")
	await get_tree().create_timer(windup_time).timeout
	start_attack()

func enter_stagger():
	current_state = State.STAGGERED
	parry_count = 0
	parry_area.is_parryable = false
	attack_area.monitoring = false
	anim.play("Staggered")
	await get_tree().create_timer(2.0).timeout
	if current_state != State.DEAD:
		recover_from_stagger()
	if posture_bar:
		posture_bar.value = 0

func recover_from_stagger():
	current_state = State.IDLE
	attack_timer = attack_cooldown
	

func take_damage():
	if current_state == State.DEAD:
		return

	current_health -= 1
	

	flash_red()

	var bar = get_node_or_null("/root/World/UI/BossHealthBar")
	if bar:
		bar.value = current_health

	if current_health <= 0:
		die()

func die():
	current_state = State.DEAD
	anim.play("Dead")
	attack_area.monitoring = false
	queue_free()

func flash_red(duration := 0.4, interval := 0.1) -> void:
	var flash_time := 0.0
	while flash_time < duration:
		var tween1 = create_tween()
		tween1.tween_property(anim, "modulate", Color(1, 0.2, 0.2), interval / 2)
		await tween1.finished

		var tween2 = create_tween()
		tween2.tween_property(anim, "modulate", Color(1, 1, 1), interval / 2)
		await tween2.finished

		flash_time += interval

	anim.modulate = Color(1, 1, 1)
