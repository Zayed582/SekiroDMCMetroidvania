extends CharacterBody2D

@export var speed := 90
@export var gravity := 800
@export var max_health := 30
@export var attack_range := 200
@export var max_posture := 300
var current_attack_index := 0
var attack_queue := ["Attack", "Attack2", "Attack3", "JumpAttack"]
var was_parried := false

var current_health := max_health
var current_posture := 0
var posture_decay_timer := 0.0
const POSTURE_DECAY_DELAY := 1.5
const POSTURE_DECAY_SPEED := 1
enum State { IDLE, CHASING, ATTACKING, STAGGERED, DEATHBLOW, DEAD, EVADING }
var state = State.IDLE
var attack_cooldown = 0.0
const ATTACK_COOLDOWN_TIME = 1.2
@export var desired_attack_distance := 80
var is_jumping_attack = false
var shuffled_attack_queue: Array = []
var evade_cooldown = 0.0
const EVADE_COOLDOWN_TIME = 1.2

@onready var anim = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var parry_area = $ParryTagArea
@onready var detection_area = $DetectionArea
@onready var posture_bar = $PostureBar
@onready var raycast = $RayCast2D

var player = null
var is_attacking = false
var is_locked = false
var is_dead = false

func _ready():
	randomize()

	posture_bar.max_value = max_posture
	posture_bar.value = current_posture

	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_left)
	attack_area.body_entered.connect(_on_attack_landed)
	
func _on_player_detected(body):
	if body.name == "Player":
		player = body

func _on_player_left(body):
	if body.name == "Player":
		player = null

func _physics_process(delta):
	if is_dead or state == State.DEAD:
		return

	velocity.y += gravity * delta

	match state:
		State.IDLE:
			if player:
				state = State.CHASING

		State.CHASING:
			if not player:
				state = State.IDLE
				velocity.x = 0
				anim.play("Idle")
				return

			var to_player = player.global_position - global_position
			var distance = to_player.length()

			# 🧠 Extra reaction if player is too close and attacking
			#if distance < 100 and player.has_method("is_attacking") and player.is_attacking() and evade_cooldown <= 0.0:
				#state = State.EVADING
				#evade_cooldown = EVADE_COOLDOWN_TIME
				#await perform_evade()
				#return

			# 🧠 If player is attacking, react (general case)
			if player and player.has_method("is_attacking") and player.is_attacking() and distance < 100:
				if randf() < 0.6 and attack_cooldown <= 0.0 and evade_cooldown <= 0.0:
					state = State.EVADING
					evade_cooldown = EVADE_COOLDOWN_TIME
					await perform_evade()
					return
				elif randf() < 0.1 and attack_cooldown <= 0.0:
					state = State.ATTACKING
					start_attack()
					return

	# Existing distance logic...



			var min_range = 10
			var max_range = attack_range

			if distance < min_range:
				# 🛑 Too close! Step back or idle
				velocity.x = 0
				anim.play("Idle")

				# Try to retreat if right in the player's face
				# INFO Removed this 
				#if randf() < 0.15 and attack_cooldown <= 0.0:
					#state = State.EVADING
					#await perform_evade()
					#print("Reacting, player too close ")
					#return
			elif distance < max_range and attack_cooldown <= 0.0:
				velocity.x = 0
				state = State.ATTACKING
				start_attack()
				return
			else:
				
				if not is_locked and state == State.CHASING and player and is_on_floor():
					velocity.x = to_player.normalized().x * speed
					anim.play("Walk")
			# Flip sprite + sync hitboxes
			anim.flip_h = to_player.x < 0
			var offset = abs(attack_area.position.x)
			var sign = -1 if anim.flip_h else 1
			attack_area.position.x = offset * sign
			parry_area.position.x = offset * sign

		State.ATTACKING:
			velocity.x = 0

		State.STAGGERED:
			velocity.x = 0

		State.DEATHBLOW:
			velocity.x = 0

	# 💫 Decay posture if not busy
	if state not in [State.ATTACKING, State.DEATHBLOW, State.STAGGERED]:
		if posture_decay_timer > 0:
			posture_decay_timer -= delta
		else:
			current_posture = max(current_posture - POSTURE_DECAY_SPEED * delta, 0)
			posture_bar.value = current_posture


		
		move_and_slide()
		


	if attack_cooldown > 0:
		attack_cooldown -= delta

	evade_cooldown = max(evade_cooldown - delta, 0)

	
	

func perform_evade():
	print("🌀 Starting perform_evade()")
	is_locked = true
	print("🔒 is_locked = true")
	anim.play("Backstep")
	print("🎞️ Playing Backstep animation")

	var direction = 1 if anim.flip_h else -1
	print("↔️ Evade direction:", direction)

	var evade_distance = 180
	var duration = 0.2
	var start_pos = global_position
	var end_pos = Vector2.ZERO
	
	raycast.target_position = Vector2(direction * evade_distance, 0)
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var collision_point = raycast.get_collision_point()
		end_pos = collision_point + Vector2(-50 * direction,0)
	else:
		end_pos = start_pos + Vector2(direction * evade_distance, 0)
	
	print("📍 Start position:", start_pos)
	print("🎯 Target end position:", end_pos)
	
	
	
	var timer := 0.0
	while timer < duration:
		var t = timer / duration
		global_position = start_pos.lerp(end_pos, t)
		timer += get_process_delta_time()
		await get_tree().process_frame

	print("✅ Evade finished")
	is_locked = false
	state = State.CHASING
	print("🔓 is_locked = false, State -> CHASING")




func start_attack():
	if is_attacking or is_locked:
		return

	is_attacking = true
	was_parried = false

	# 🔀 Shuffle attack queue if empty
	if shuffled_attack_queue.is_empty():
		shuffled_attack_queue = attack_queue.duplicate()
		shuffled_attack_queue.shuffle()

	var attack_name = shuffled_attack_queue.pop_front()

	if attack_name == "JumpAttack":
		if randf() < 0.5:
			# 50% chance to fakeout with just a backstep
			#await perform_evade()
			pass
		else:
			await perform_jump_attack()

	else:
		var attack_finished_cleanly = await monitor_ashen_attacks(attack_name)
		if not attack_finished_cleanly:
			anim.play("Staggered")
			await get_tree().create_timer(0.5).timeout

	if not is_dead:
		anim.play("Idle")

	# 🔁 Random chance to backstep after attack
	#INFO
	if randi() % 100 < 10:
		state = State.EVADING
		await perform_evade()
	else:
		state = State.CHASING

	is_attacking = false
	is_locked = false
	attack_cooldown = ATTACK_COOLDOWN_TIME




func monitor_ashen_attacks(animation_name: String) -> bool:
	anim.play(animation_name)
	anim.frame = 0
	await get_tree().process_frame

	var total_frames = {
		"Attack": 6,
		"Attack2": 7,
		"Attack3": 10
	}.get(animation_name, 8)

	var parry_frames = {
		"Attack": [2, 3, 4, 5],
		"Attack2": [4, 5, 6],
		"Attack3": [1, 2, 3, 4, 6, 7, 8, 9]
	}.get(animation_name, [])

	var damage_frames = {
		"Attack": [5],
		"Attack2": [5],
		"Attack3": [4, 9]
	}.get(animation_name, [])

	var speed = anim.sprite_frames.get_animation_speed(animation_name)
	if speed <= 0:
		speed = 10.0
	var frame_duration = 1.0 / speed

	for i in range(total_frames):
		if was_parried:
			attack_area.monitoring = false
			parry_area.monitoring = false
			if "is_parryable" in parry_area:
				parry_area.is_parryable = false
			return false

		if i in parry_frames:
			parry_area.monitoring = true
			if "is_parryable" in parry_area:
				parry_area.is_parryable = true
		else:
			parry_area.monitoring = false
			if "is_parryable" in parry_area:
				parry_area.is_parryable = false

		if i in damage_frames:
			attack_area.monitoring = true
		else:
			attack_area.monitoring = false

		await get_tree().create_timer(frame_duration).timeout

	# Cleanup
	attack_area.monitoring = false
	parry_area.monitoring = false
	if "is_parryable" in parry_area:
		parry_area.is_parryable = false

	return true



func _on_attack_landed(body):
	if not is_attacking:
		return
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(true)


func on_parried():
	if is_dead:
		return

	is_attacking = false
	is_locked = true
	state = State.STAGGERED
	was_parried = true

	anim.stop()
	anim.frame = 0
	

	# Just disable hitboxes — no position resets
	attack_area.monitoring = false
	parry_area.monitoring = false
	if "is_parryable" in parry_area:
		parry_area.is_parryable = false
	
	apply_arc_motion()
	apply_posture_damage(100)

	await recover_from_parry()



func apply_arc_motion():
#	APPLY ARC MOTION
	if !is_jumping_attack: return
	
	# Face direction
	var direction = 1 if (player.global_position.x - global_position.x) > 0 else -1
	
	#anim.flip_h = direction < 0

	# 🎬 Play backstep animation
	anim.play("Backstep")
	

	# 📦 Arc motion: jump back with diagonal force
	var velocity_back = Vector2(-direction * 1020, -100)
	var timer = 0.0
	var duration = 0.5

	while timer < duration:
		velocity = velocity_back
		velocity.y += gravity * get_process_delta_time()
		move_and_slide()
		timer += get_process_delta_time()
		await get_tree().process_frame
	pass


func recover_from_parry():
	# Step back 40% of the time
	#INFO
	if randf() < 0.1:
		await get_tree().create_timer(0.3).timeout
		await perform_evade()
	else:
		await get_tree().create_timer(0.6).timeout

	# Add a temporary idle buffer before resuming chase
	state = State.IDLE
	await get_tree().create_timer(0.4).timeout

	if not is_dead:
		anim.play("Idle")
	state = State.CHASING
	is_locked = false



func trigger_deathblow():
	is_locked = true
	anim.play("DeathblowReady")

	if player and player.has_method("set_deathblow_target"):
		player.set_deathblow_target(self)

	await get_tree().create_timer(2.0).timeout
	if not is_dead:
		anim.play("Idle")
		is_locked = false

func take_damage(amount := 1):
	if is_dead:
		return

	current_health -= amount
	anim.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	anim.modulate = Color(1, 1, 1)

	if current_health <= 0:
		die()


func apply_posture_damage(amount: int):
	current_posture += amount
	posture_bar.value = current_posture

	if current_posture >= max_posture:
		current_posture = 0
		posture_bar.value = 0
		await trigger_deathblow()

func die():
	if is_dead:
		return

	is_dead = true
	anim.play("Death")

	# Optional: notify player for charms like Ghostfang
	var player = get_node_or_null("/root/World/Player")
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed()

	await get_tree().create_timer(0.6).timeout
	queue_free()
	
	
	
func deathblow():
	if is_dead:
		return

	is_dead = true
	anim.play("Death")
	set_physics_process(false)
	set_collision_layer(0)
	set_collision_mask(0)

	if has_node("Hurtbox"):
		$Hurtbox.monitoring = false
	if has_node("AttackArea"):
		$AttackArea.monitoring = false
	if has_node("ParryTagArea"):
		$ParryTagArea.monitoring = false

	await get_tree().create_timer(0.6).timeout
	queue_free()


func perform_jump_attack():
	

	is_jumping_attack = true
	was_parried = false
	state = State.ATTACKING
	is_attacking = true
	is_locked = true
	

	# Disable all hitboxes (just in case)
	attack_area.monitoring = false
	parry_area.monitoring = false
	if "is_parryable" in parry_area:
		parry_area.is_parryable = false
	

	# Face direction
	var direction = 1 if (player.global_position.x - global_position.x) > 0 else -1
	
	anim.flip_h = direction < 0

	# 🎬 Play backstep animation
	anim.play("Backstep")
	

	# 📦 Arc motion: jump back with diagonal force
	var velocity_back = Vector2(-direction * 620, -100)
	var timer = 0.0
	var duration = 0.5

	while timer < duration:
		self.velocity = velocity_back
		self.velocity.y += gravity * get_process_delta_time()
		move_and_slide()
		timer += get_process_delta_time()
		await get_tree().process_frame

	

	# 🧍 Land and stay idle briefly
	anim.play("Idle")
	state = State.IDLE
	
	await get_tree().create_timer(0.6).timeout
	

	# ⬆️ Jump vertically and stop at apex
	anim.play("JumpAttack")
	

	self.velocity = Vector2(0, -700)  # High jump

	while self.velocity.y < 0:
		self.velocity.y += gravity * get_process_delta_time()
		move_and_slide()
		await get_tree().process_frame 


	# Pause midair at apex
	self.velocity = Vector2.ZERO
	
	await get_tree().create_timer(0.4).timeout

	# 📌 Lock direction to player's position
	if player:
		

		var to_player = (player.global_position - global_position).normalized()
		

		var perpendicular = Vector2(-to_player.y, to_player.x)  # 90° rotated vector
		

		# Flip offset direction depending on side
		var offset_dir = -1 if global_position.x < player.global_position.x else 1
		var overshoot = to_player + perpendicular * 0.4 * offset_dir
		

		self.velocity = overshoot.normalized() * 500
		

		anim.flip_h = to_player.x < 0
		
	else:
		self.velocity = Vector2(0, 500)
		







	# Activate hitboxes
	parry_area.monitoring = true
	if "is_parryable" in parry_area:
		parry_area.is_parryable = true
	attack_area.monitoring = true

	# 🔁 Dive loop
	anim.frame = 6
	while not is_on_floor():
		self.velocity.y += gravity * get_process_delta_time()
		move_and_slide()
		anim.frame = 6 + int(Time.get_ticks_msec() / 80) % 3
		await get_tree().process_frame

	# Reset hitboxes
	parry_area.monitoring = false
	attack_area.monitoring = false
	if "is_parryable" in parry_area:
		parry_area.is_parryable = false

	

	# ✅ Cleanup
	anim.play("Idle")
	state = State.CHASING
	is_attacking = false
	is_locked = false
	is_jumping_attack = false
	


func _on_collide_hit_box_body_entered(body):
	#if body.name == "Player" and body.has_method("take_damage"):
		#body.take_damage(true)
	pass # Replace with function body.
