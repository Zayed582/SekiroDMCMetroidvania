extends CharacterBody2D

@export var speed := 120
@export var gravity := 800
@export var max_health := 4
@export var attack_range := 200
@export var max_posture := 1500
@export var deathblow_window := 1.0
var knockback_velocity := Vector2.ZERO
var pogo_counter := 0
const MAX_POGO_BEFORE_COUNTER := 3
var is_pogo_dashing := false

@onready var anim = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var parry_area = $ParryTagArea as Node
@onready var detection_area = $DetectionArea
@onready var posture_bar = $PostureBar
var is_dead = false
@export var debug_id: String = "UNKNOWN"

var current_health = 999
var current_posture := 0
var posture_decay_timer := 0.0
const POSTURE_DECAY_DELAY := 1.5
const POSTURE_DECAY_SPEED := 20
var deathblow_pending = false
@export var takes_damage_on_parry := false

var player: Node2D = null
var is_attacking = false
var is_locked = false
var was_parried = false
var is_parried_interrupted = false
var allow_post_parry_damage = false
var in_deathblow_state = false

var current_attack_name := ""
var attack_queue := ["Attack1", "Attack2", "Attack3"]
var current_attack_index := 0

func _ready():
	posture_bar.max_value = max_posture
	posture_bar.value = current_posture
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_left)

	attack_area.body_entered.connect(_on_attack_landed)
	(attack_area as Area2D).monitoring = false
	(parry_area as Area2D).monitoring = false
	add_to_group("enemies")

func _physics_process(delta):
	if is_dead:
		return
		
	# prevent normal movement while dashing
	if is_pogo_dashing:
		move_and_slide()
		return
	var allow_ai = not is_locked and not is_attacking and not in_deathblow_state

	if allow_ai:
		if posture_decay_timer > 0:
			posture_decay_timer -= delta
		else:
			current_posture = max(current_posture - POSTURE_DECAY_SPEED * delta, 0)
			posture_bar.value = current_posture

		var mirage = null
		for node in get_tree().get_nodes_in_group("mirage"):
			if node and node.is_inside_tree():
				mirage = node
				break

		var target = mirage if mirage else player

		if target:
			var to_target = target.global_position - global_position

			if to_target.length() < attack_range:
				start_attack()
			else:
				velocity.x = to_target.normalized().x * speed
				anim.play("Walk")
				anim.flip_h = to_target.x < 0

				var offset = abs(attack_area.position.x)
				var flip_sign = -1 if anim.flip_h else 1
				attack_area.position.x = offset * flip_sign
				parry_area.position.x = offset * flip_sign
		else:
			velocity.x = 0
			anim.play("Idle")

	velocity.y += gravity * delta
	velocity += knockback_velocity
	knockback_velocity = Vector2.ZERO

	if is_attacking or is_locked or in_deathblow_state:
		velocity.x = 0

	move_and_slide()


func on_pogo_hit_by_player():
	if is_dead or in_deathblow_state:
		return

	pogo_counter += 1
	if pogo_counter >= MAX_POGO_BEFORE_COUNTER:
		print("🛡️ Dual Wielder is countering pogo!")
		pogo_counter = 0
		if player and player.has_method("launch_for_pogo_punish"):
			player.launch_for_pogo_punish()
			await get_tree().create_timer(0.4).timeout
			start_pogo_counter_dash()


func start_pogo_counter_dash():
	if is_dead or in_deathblow_state:
		return

	print("⚔️ Dual Wielder: Counter Pogo Dash!")
	is_attacking = true
	is_pogo_dashing = true

	await get_tree().create_timer(0.4).timeout  # small wait before dash

	if is_instance_valid(player) and player.is_inside_tree():
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * 3000
		anim.play("AttackDash")

		await get_tree().create_timer(0.5).timeout  # dash duration

		if global_position.distance_to(player.global_position) < 80:
			if player.has_method("take_damage"):
				player.take_damage(true)

	velocity = Vector2.ZERO
	is_attacking = false
	is_pogo_dashing = false












func start_pogo_counter_attack():
	if is_dead or in_deathblow_state:
		return

	print("🛡️ Dual Wielder is parrying the pogo!")
	is_locked = true
	anim.play("ParryCounter")

	await get_tree().create_timer(0.3).timeout

	# 💥 Launch the player in the air as punishment
	if player and player.has_method("launch_for_pogo_punish"):
		player.launch_for_pogo_punish(self)

	# ⏳ Optional: delay before resuming AI
	await get_tree().create_timer(0.6).timeout
	is_locked = false



func _on_player_detected(body):
	if body.name == "Player":
		player = body

func start_attack():
	is_attacking = true
	is_parried_interrupted = false
	was_parried = false
	allow_post_parry_damage = false

	var attack_name = attack_queue[current_attack_index % attack_queue.size()]
	var attack_finished_cleanly = await monitor_dual_wield_attacks(attack_name)

	match attack_name:
		"Attack1":
			current_attack_index = 1
		"Attack2":
			current_attack_index = 2
		"Attack3":
			if was_parried:
				play_stagger_with_duration(0.8)

				current_attack_index = 0
			else:
				current_attack_index = 0

	is_attacking = false

func monitor_dual_wield_attacks(animation_name: String) -> bool:
	anim.play(animation_name)
	anim.frame = 0
	await get_tree().process_frame

	var total_frames = {
		"Attack1": 6,
		"Attack2": 9,
		"Attack3": 10
	}.get(animation_name, 0)

	var parry_frames = {
		"Attack1": [2, 3, 4, 5, 6],
		"Attack2": [0, 1, 2, 3, 5, 6, 7, 8],
		"Attack3": [7, 8]
	}.get(animation_name, [])

	var damage_frames = {
		"Attack1": [5],
		"Attack2": [5, 6],
		"Attack3": [9, 10]
	}.get(animation_name, [])

	var speed = anim.sprite_frames.get_animation_speed(animation_name)
	if speed <= 0:
		speed = 10.0
	var frame_duration = 1.0 / speed

	var parry_tag := parry_area as Node
	var attack_area_2d := attack_area as Area2D
	var parry_area_2d := parry_area as Area2D

	for i in range(total_frames):
		if is_parried_interrupted:
			attack_area_2d.monitoring = false
			parry_area_2d.monitoring = false
			if "is_parryable" in parry_tag:
				parry_tag.is_parryable = false
			anim.stop()
			anim.frame = 0
			return false

		if i in parry_frames:
			parry_area_2d.monitoring = true
			if "is_parryable" in parry_tag:
				parry_tag.is_parryable = true
		else:
			parry_area_2d.monitoring = false
			if "is_parryable" in parry_tag:
				parry_tag.is_parryable = false

		if i in damage_frames:
			if not was_parried or allow_post_parry_damage:
				attack_area_2d.monitoring = true
			else:
				attack_area_2d.monitoring = false
		else:
			attack_area_2d.monitoring = false

		# 🧠 Check for mirage in range and notify it
		for area in parry_area_2d.get_overlapping_areas():
			if area.is_in_group("mirage") and area.has_method("on_enemy_attack_triggered"):
				print("⚠️ Mirage detected, triggering response")
				area.on_enemy_attack_triggered()

		await get_tree().create_timer(frame_duration).timeout

	# Reset
	attack_area_2d.monitoring = false
	parry_area_2d.monitoring = false
	if "is_parryable" in parry_tag:
		parry_tag.is_parryable = false

	was_parried = false
	allow_post_parry_damage = false
	return true


func _on_attack_landed(body):
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(true)

func on_parried():
	is_parried_interrupted = true
	was_parried = true
	allow_post_parry_damage = false

	if attack_area and attack_area is Area2D:
		attack_area.monitoring = false

	if parry_area and parry_area is Area2D:
		parry_area.monitoring = false
		if "is_parryable" in parry_area:
			parry_area.is_parryable = false

	# 💥 Check if player is in SMOKIN STYLE rank
	if player and player.has_method("get_current_parry_rank"):
		var rank = player.get_current_parry_rank()
		if rank == "SMOKIN STYLE":
			if has_method("apply_air_knockback"):
				apply_air_knockback()

			if takes_damage_on_parry and has_method("take_damage"):
				take_damage()


	# Always apply posture
				apply_posture_damage(40)



func apply_posture_damage(amount: int):
	current_posture += amount
	posture_decay_timer = POSTURE_DECAY_DELAY
	posture_bar.value = current_posture

	if current_posture >= max_posture:
		current_posture = 0
		posture_bar.value = 0
		await trigger_deathblow()

func trigger_deathblow():
	in_deathblow_state = true
	is_locked = true
	deathblow_pending = true  # ✅ STAYS TRUE — NEVER RESET

	anim.play("Staggered")
	

	await get_tree().create_timer(0.4).timeout
	anim.play("DeathblowReady")
	

	if player and player.has_method("set_deathblow_target"):
		
		player.set_deathblow_target(self)

	# 🕒 Recovery fallback (always triggers, even if no player)
	await get_tree().create_timer(2.0).timeout

	if not is_dead and deathblow_pending:
		
		in_deathblow_state = false
		is_locked = false
		deathblow_pending = false
		anim.play("Idle")



	# ⛔ No timer, no loop, no reset
	# Let the player kill whenever they want




func take_damage(amount := 1):
	print("❤️", debug_id, "Current HP:", current_health, "/", max_health)

	current_health -= amount
	anim.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	anim.modulate = Color(1, 1, 1)

	if current_health <= 0:
		die()


func die():
	if is_dead:
		return
	is_dead = true

	# 💥 Notify player if Ghostfang Drive is active (1 HP kill effect)
	var player = get_node_or_null("/root/World/Player")
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed()

	anim.play("Death")

	# ✅ Double protection against animation bug
	var timer := get_tree().create_timer(0.6)
	await timer.timeout

	set_physics_process(false)
	call_deferred("queue_free")



func _on_player_left(body):
	if body.name == "Player":
		player = null

func extend_stagger_duration(extra_time: float):
	play_stagger_with_duration(0.8 + extra_time)



func apply_air_knockback():
	if is_dead:
		return

	# 💡 If posture is broken, still apply knockback but skip locking
	
		
	else:
		is_locked = true

	
	knockback_velocity.y = -350
	anim.play("Hurt")

	await get_tree().create_timer(0.4).timeout

	if not is_dead:
		anim.play("Idle")
	if not in_deathblow_state:
		is_locked = false

	# Reset velocity after delay
	knockback_velocity = Vector2.ZERO





func deathblow():
	if is_dead:
		
		return

	
	is_dead = true

	# Kill logic
	set_physics_process(false)
	set_process(false)
	set_collision_layer(0)
	set_collision_mask(0)

	if has_node("Hurtbox"):
		$Hurtbox.monitoring = false
	if has_node("AttackArea"):
		$AttackArea.monitoring = false

	if parry_area and parry_area is Area2D:
		
		parry_area.monitoring = false
		if "is_parryable" in parry_area:
			parry_area.is_parryable = false

	if attack_area and attack_area is Area2D:
		
		attack_area.monitoring = false

	
	anim.play("Death")

	await get_tree().create_timer(0.6).timeout

	
	call_deferred("queue_free")

	



func play_stagger_with_duration(duration: float = 0.8):
	if is_dead or in_deathblow_state:
		return
	if is_locked:
		return  # already staggered or locked doing something else

	is_locked = true
	anim.play("Staggered")

	await get_tree().create_timer(duration).timeout

	if not is_dead:
		anim.play("Idle")
	is_locked = false
