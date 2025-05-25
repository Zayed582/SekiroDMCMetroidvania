extends CharacterBody2D

@export var speed := 100
@export var gravity := 800

enum State { IDLE, WALK, WINDUP, ATTACKING, DEFENDING, STAGGERED, DEAD, PARRYING }

var current_state = State.IDLE

@export var max_health := 5
var current_health := max_health
var allow_post_parry_damage = false
var reaction_cooldown := 0.0
var windup_interrupted = false


@export var attack_range := 100
@export var stop_distance := 100

var parry_lock_timer := 0.0

@onready var anim = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var parry_area = $ParryTagArea
@onready var detection_area = $DetectionArea

var was_parried = false
var is_parryable = false
var is_locked_in_parry_response = false


@export var windup_time := 0.5
@export var attack_duration := 0.7
@export var attack_cooldown := 1.5
@export var defend_chance := 0.25
var attack_timer := 0.0

var player: Node2D = null
var recently_hit = false
var chase_after_hit_timer = 0.0
const CHASE_AFTER_HIT_DURATION = 1.2

func _ready():
	add_to_group("enemies")
	detection_area.body_entered.connect(_on_player_detected)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	parry_area.monitoring = false
	attack_area.monitoring = false
	parry_area.is_parryable = false

func _physics_process(delta):
	
	if is_locked_in_parry_response:
		return  # ✅ Don't do ANYTHING until post-parry finishes

	parry_lock_timer = max(parry_lock_timer - delta, 0)

	if reaction_cooldown > 0:
		reaction_cooldown -= delta

	if current_state in [State.ATTACKING, State.WINDUP, State.DEFENDING, State.STAGGERED, State.PARRYING]:
		return

	velocity.y += gravity * delta

	if recently_hit:
		chase_after_hit_timer -= delta
		if chase_after_hit_timer <= 0:
			recently_hit = false

	if current_state == State.WALK and player:
		var to_player = player.global_position - global_position
		var dist = to_player.length()

		if dist > stop_distance:
			var dir = to_player.normalized()
			velocity.x = dir.x * speed
		else:
			velocity.x = 0

		anim.flip_h = to_player.x < 0
		attack_area.position.x = abs(attack_area.position.x) * (-1 if anim.flip_h else 1)
		parry_area.position.x = abs(parry_area.position.x) * (-1 if anim.flip_h else 1)
		detection_area.position.x = abs(detection_area.position.x) * (-1 if anim.flip_h else 1)
	else:
		velocity.x = 0

	move_and_slide()

	if current_state == State.WALK and player and reaction_cooldown <= 0:
		if global_position.distance_to(player.global_position) < attack_range or recently_hit:
			reaction_cooldown = 1.0
			if randf() < defend_chance:
				start_defending()
			else:
				start_windup()

	if current_state == State.IDLE and attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0 and player:
			if randf() < defend_chance:
				start_defending()
			else:
				start_windup()

	if current_state == State.WINDUP and player:
		if player.has_method("is_attacking") and player.is_attacking():
			if global_position.distance_to(player.global_position) < 90:
				print("😈 Player spammed into windup — punished!")
				start_parrying()

func _on_player_detected(body):
	if body.name == "Player":
		player = body
		current_state = State.WALK
		anim.play("Walk")

func start_windup():
	reaction_cooldown = 1.0
	current_state = State.WINDUP
	anim.play("Windup")
	parry_area.monitoring = true
	print("⚠️ Blade Grunt is parryable!")
	windup_interrupted = false  # ✅ Reset flag

	await get_tree().create_timer(windup_time).timeout

	if current_state != State.WINDUP or windup_interrupted:
		print("❌ Skipped attack: interrupted during windup")
		return

	start_attack()


func start_attack():
	print("💥 ATTACKING!")
	current_state = State.ATTACKING
	parry_area.monitoring = false
	attack_area.monitoring = false
	parry_area.is_parryable = false
	anim.frame = 0
	anim.play("Attack")
	await monitor_attack_frames()
	enter_cooldown()

func enter_cooldown():
	current_state = State.IDLE
	anim.play("Idle")
	attack_timer = attack_cooldown
	is_parryable = false
	detection_area.monitoring = false
	await get_tree().process_frame
	detection_area.monitoring = true

func _on_attack_area_body_entered(body):
	if body.name == "Player":
		if current_state == State.DEFENDING:
			start_parrying()
		elif current_state == State.ATTACKING:
			if body.has_method("is_attacking") and body.is_attacking():
				start_parrying()
			elif body.has_method("take_damage"):
				print("🔎 was_parried:", was_parried, "| allow_post_parry_damage:", allow_post_parry_damage)
				if not was_parried or allow_post_parry_damage:
					body.take_damage(true)

func on_parried():
	if current_state == State.DEAD:
		return
	print("🛑 Blade Grunt was parried!")

	# Stop current attack detection
	parry_area.monitoring = false
	parry_area.is_parryable = false
	attack_area.monitoring = false

	# Stop attack state
	was_parried = true
	allow_post_parry_damage = false  # RESET HERE IMMEDIATELY
	is_locked_in_parry_response = false  # just in case

	# Play stagger
	if current_state != State.DEFENDING:
		anim.play("Staggered")
	current_state = State.STAGGERED

	await get_tree().create_timer(1.0).timeout

	# Recover logic
	print("✅ Recovering from parry")
	detection_area.monitoring = false
	await get_tree().process_frame
	detection_area.monitoring = true

	# RESET EVERYTHING HERE — THIS IS THE CRUCIAL PART
	was_parried = false
	allow_post_parry_damage = false

	if player and detection_area.get_overlapping_bodies().has(player):
		current_state = State.WALK
		anim.play("Walk")
	else:
		current_state = State.IDLE
		anim.play("Idle")

	attack_timer = attack_cooldown





func start_defending():
	reaction_cooldown = 1.0
	print("🛡️ Blade Grunt is defending!")
	current_state = State.DEFENDING
	anim.play("Defend")
	parry_area.monitoring = true
	parry_area.is_parryable = false
	await get_tree().create_timer(1.2).timeout
	parry_area.monitoring = false
	if current_state == State.DEFENDING:
		enter_cooldown()

func monitor_attack_frames():
	print("🎬 Monitoring animation:", anim.animation)
	var frame_duration = 1.0 / anim.sprite_frames.get_animation_speed(anim.animation)
	var total_frames = anim.sprite_frames.get_frame_count(anim.animation)
	for i in range(total_frames):
		var frame = anim.frame
		if frame >= 3 and frame <= 6:
			if not parry_area.monitoring:
				parry_area.monitoring = true
				parry_area.is_parryable = true
				print("🛡️ Parry window START")
		elif frame == 7:
			parry_area.monitoring = false
			parry_area.is_parryable = false
			print("🛡️ Parry window END")
		if anim.animation == "Attack" and frame == 7:
			if not was_parried or allow_post_parry_damage:
				print("⚔️ Damage START (allowed)")
				attack_area.monitoring = true
			else:
				print("❌ Damage SKIPPED: parry lockout active")
		if frame == 9:
			if attack_area.monitoring:
				print("🛑 Damage END")
			attack_area.monitoring = false
		await get_tree().create_timer(frame_duration).timeout

func start_parrying():
	windup_interrupted = true

	if current_state == State.DEAD:
		return
	print("🛡️ Blade Grunt PARRIED you!")
	anim.modulate = Color(0.4, 0.6, 1.0)
	await get_tree().create_timer(0.3).timeout
	anim.modulate = Color(1, 1, 1)
	if player and player.has_method("on_parried"):
		player.on_parried()
	await get_tree().create_timer(0.4).timeout
	if player and global_position.distance_to(player.global_position) > attack_range:
		current_state = State.WALK
		anim.play("Walk")
		return
	start_post_parry_attack()

func start_post_parry_attack():
	print("💥 POST PARRY ATTACKING!")
	is_locked_in_parry_response = true
	current_state = State.ATTACKING
	was_parried = true
	allow_post_parry_damage = true

	parry_area.monitoring = false
	attack_area.monitoring = false
	parry_area.is_parryable = false

	await get_tree().process_frame

	anim.frame = 0
	anim.play("PostParryWindup")
	await get_tree().create_timer(0.2).timeout

	anim.frame = 0
	anim.play("Attack")
	await get_tree().process_frame

	await monitor_attack_frames()

	was_parried = false
	allow_post_parry_damage = false
	is_locked_in_parry_response = false  # ✅ RELEASE THE LOCK

	enter_cooldown()





func force_hit_if_close():
	if player and player.has_method("take_damage"):
		if global_position.distance_to(player.global_position) < 90 and not player.is_invincible:
			print("💥 Forced counter hit!")
			player.take_damage(true)
		else:
			print("❌ Counterattack missed — unlocking manually")
			if player.has_method("unlock_parry_lock"):
				player.unlock_parry_lock()

func take_damage():
	if current_state == State.DEAD:
		return
	if current_state == State.DEFENDING:
		print("🛡️ Blocked the attack!")
		start_parrying()
		return
	if current_state == State.WINDUP:
		print("🎭 Baited the player — counter parry!")
		start_parrying()
		return
	current_health -= 1
	print("🔥 You HIT Blade Grunt! Health:", current_health)
	anim.modulate = Color(1, 0.2, 0.2)
	await get_tree().create_timer(0.1).timeout
	anim.modulate = Color(1, 1, 1)
	recently_hit = true
	chase_after_hit_timer = CHASE_AFTER_HIT_DURATION
	if current_health <= 0:
		die()
		return
	current_state = State.STAGGERED
	anim.play("Staggered")
	await get_tree().create_timer(0.5).timeout
	attack_timer = attack_cooldown
	detection_area.monitoring = false
	await get_tree().process_frame
	detection_area.monitoring = true
	if player and detection_area.get_overlapping_bodies().has(player):
		current_state = State.WALK
		anim.play("Walk")
	else:
		current_state = State.IDLE
		anim.play("Idle")

func die():
	print("☠️ Blade Grunt is dead!")
	current_state = State.DEAD
	anim.play("Dead")
	parry_area.monitoring = false
	attack_area.monitoring = false
	set_physics_process(false)
	queue_free()
