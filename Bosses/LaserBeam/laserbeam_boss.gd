extends CharacterBody2D

enum State { IDLE, WINDUP, ATTACKING, STAGGERED, DEAD, ORB_BARRAGE, LIGHT_DASH, LIGHT_BEAM, RADIANT_SLAM, CLONE_DASH }


@onready var shockwave_scene = preload("res://Effects/CharmEffects/VengefulSpirit/shock_blast.tscn")
var nova_triggered := false

@onready var clone_scene = preload("res://Bosses/LaserBeam/laserbeam_clone.tscn")  # This should be a translucent version of Xarion
var attack_pattern: Array[Callable] = []
var current_attack_index := 0
var can_deal_damage := false
@export var max_posture := 120
@export var deathblow_window := 1.2

@onready var posture_bar = $PostureBar
var current_posture := 0
var posture_decay_timer := 0.0
const POSTURE_DECAY_DELAY := 1.5
const POSTURE_DECAY_SPEED := 20

var deathblow_pending = false
var in_deathblow_state = false

@export var deathblow_damage := 4



@export var max_health := 10
@export var speed := 100
@export var gravity := 800
@export var attack_cooldown := 0.4  # 🔥 More aggressive
var was_parried = false
@onready var orb_scene = preload("res://Bosses/LaserBeam/Effects/SolarOrb/solar_orb.tscn") 
@onready var anim = $AnimatedSprite2D
@onready var parry_area = $ParryTagArea
@onready var attack_area = $AttackArea
@onready var laser_scene = preload("res://Bosses/LaserBeam/Effects/Beam/light_beam.tscn")

var current_health := max_health
var attack_timer := 0.0
var current_state = State.IDLE
var player: Node2D = null
var enraged := false



func _ready():
	queue_free()
	add_to_group("enemies")
	
	var root = get_tree().get_root()
	if root.has_node("World/Player"):
		player = root.get_node("World/Player")

	attack_timer = attack_cooldown

	# 🛡️ Initialize posture bar
	if has_node("PostureBar"):
		posture_bar.max_value = max_posture
		posture_bar.value = current_posture

	# 🌀 Initial attack pattern (pre-enraged)
	attack_pattern = [
		func() -> void: attack_light_dash(),
		func() -> void: attack_orb_barrage(),
		func() -> void: attack_laser_beam()
	]



func _physics_process(delta):
	if current_state in [State.DEAD, State.STAGGERED, State.WINDUP]:
		return

	# Handle LIGHT_DASH separately (active movement)
	if current_state == State.LIGHT_DASH:
		move_and_slide()
		return

	# Gravity
	velocity.y += gravity * delta
	move_and_slide()

	# Face the player
	if player:
		anim.flip_h = player.global_position.x < global_position.x

	# Posture decay over time (for hybrid posture system)
	if posture_decay_timer > 0:
		posture_decay_timer -= delta
	elif current_posture > 0:
		current_posture = max(current_posture - POSTURE_DECAY_SPEED * delta, 0)
		if has_node("PostureBar"):
			$PostureBar.value = current_posture

	# Idle attack loop
	if current_state == State.IDLE:
		attack_timer -= delta
		if attack_timer <= 0:
			choose_next_attack()




func choose_next_attack():
	if attack_pattern.is_empty():
		print("⚠️ No attacks in pattern!")
		return

	if current_attack_index >= attack_pattern.size():
		current_attack_index = 0  # Loop back to start

	var attack_to_run = attack_pattern[current_attack_index]
	current_attack_index += 1

	# Execute the attack
	attack_to_run.call()




func spawn_orb(position: Vector2):
	var orb = orb_scene.instantiate()
	get_tree().current_scene.add_child(orb)
	orb.global_position = position
	print("🟡 Spawned orb at:", orb.global_position)

func attack_orb_barrage() -> void:
	print("☀️ Starting Solar Orb Barrage!")
	current_state = State.ORB_BARRAGE
	anim.play("Idle")

	if not player:
		print("❌ No player found for orb targeting")
		current_state = State.IDLE
		return

	var base_pos = player.global_position
	var offsets = [
		Vector2(-150, -300),
		Vector2(0, -320),
		Vector2(150, -300),
	]

	if enraged:
		offsets.append(Vector2(-225, -280))
		offsets.append(Vector2(225, -280))

	for offset in offsets:
		spawn_orb(base_pos + offset)
		var delay = enraged if 0.15 else 0.3
		await get_tree().create_timer(delay).timeout

	await get_tree().create_timer(0.3).timeout
	current_state = State.IDLE
	attack_timer = attack_cooldown

func attack_light_dash():
	print("⚡ LIGHT DASH initiated")
	current_state = State.LIGHT_DASH
	anim.play("Dash")
	await get_tree().create_timer(0.2).timeout

	if player:
		var direction = (player.global_position - global_position).normalized()
		
		# Enable parry and damage
		parry_area.monitoring = true
		parry_area.set("is_parryable", true)
		attack_area.monitoring = true
		can_deal_damage = true  # ✅ Flag used in _on_attack_area_body_entered

		var dash_distance = 600 if enraged else 400
		var dash_time = 0.5
		var dash_velocity = direction * (dash_distance / dash_time)

		var t := 0.0
		while t < dash_time:
			velocity = dash_velocity
			move_and_slide()
			await get_tree().process_frame
			t += get_process_delta_time()

		# Stop dash and disable hit detection
		velocity = Vector2.ZERO
		parry_area.monitoring = false
		parry_area.set("is_parryable", false)
		attack_area.monitoring = false
		can_deal_damage = false  # ✅ Disable damage after dash ends

		if enraged:
			spawn_orb(player.global_position + Vector2(0, -250))

	await get_tree().create_timer(0.2).timeout
	current_state = State.IDLE
	attack_timer = attack_cooldown


func start_attack():
	print("💢 Standard Attack")
	current_state = State.ATTACKING
	anim.play("Idle")  # placeholder
	await get_tree().create_timer(0.5).timeout
	current_state = State.IDLE
	attack_timer = attack_cooldown

func take_damage(was_charged_attack := false):
	if current_state == State.DEAD:
		return

	current_health -= 1
	anim.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	anim.modulate = Color(1, 1, 1)

	# 🟨 Boost posture damage if charged
	var posture_damage = 5
	if was_charged_attack:
		posture_damage = 20
		print("⚡ CHARGED ATTACK detected on Xarion!")

	apply_posture_damage(posture_damage)

	# Enrage logic
	if not enraged and current_health <= max_health / 2:
		await enter_enraged_mode()

	if current_health <= 0:
		die()




func enter_enraged_mode():
	enraged = true
	print("🔥 Xarion is ENRAGED!")
	anim.modulate = Color(1, 0.5, 0.1)
	await get_tree().create_timer(0.5).timeout
	anim.modulate = Color(1, 1, 1)

	# Add new moves to pattern
	attack_pattern.append(func() -> void: attack_radiant_slam())
	attack_pattern.append(func() -> void: attack_clone_dash())


func die():
	current_state = State.DEAD
	anim.play("Dead")
	queue_free()

func on_parried():
	if current_state == State.DEAD:
		return

	print("❌ Xarion was parried!")

	current_state = State.STAGGERED
	can_deal_damage = false
	anim.play("Idle")

	apply_posture_damage(40)

	await get_tree().create_timer(1.0).timeout

	if not in_deathblow_state:
		current_state = State.IDLE


	
func attack_laser_beam():
	print("🔆 Xarion prepares a LASER BEAM")
	current_state = State.LIGHT_BEAM
	anim.play("Charge")  # make sure this exists

	await get_tree().create_timer(0.6).timeout

	if player:
		var laser = laser_scene.instantiate()
		get_tree().current_scene.add_child(laser)
		laser.global_position = global_position + Vector2(0, -20)  # adjust position
		laser.look_at(player.global_position)
		print("🔫 Fired laser beam!")

	await get_tree().create_timer(1.2).timeout  # duration of laser
	current_state = State.IDLE
	attack_timer = attack_cooldown

func attack_radiant_slam():
	print("💥 Radiant Slam incoming!")
	current_state = State.RADIANT_SLAM
	anim.play("Idle")  # No animations, sticking with Idle

	# Simulate float up
	velocity.y = -500  # Jump velocity
	await get_tree().create_timer(0.4).timeout

	# Slam downward
	velocity.y = 1200
	await get_tree().create_timer(0.2).timeout
	velocity.y = 0  # Stop movement

	# Spawn shockwave
	if player:
		var shockwave = shockwave_scene.instantiate()  # <- preload this at top
		get_tree().current_scene.add_child(shockwave)
		shockwave.global_position = global_position + Vector2(0, 50)

		if shockwave.has_method("set"):
			shockwave.set("is_parryable", true)

		print("💢 Shockwave spawned!")

	await get_tree().create_timer(1.0).timeout
	current_state = State.IDLE
	attack_timer = attack_cooldown



func _on_attack_area_body_entered(body: Node2D) -> void:
	# Don't damage if parried or damage is disabled
	if was_parried or not can_deal_damage:
		print("⛔ Ignored attack — parried or damage disabled.")
		return

	if body.name == "Player" or body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage()
			print("💢 Xarion hit the player!")
		else:
			print("❌ Player has no take_damage method!")




func attack_clone_dash():
	print("👥 Clone Dash initiated!")
	current_state = State.CLONE_DASH
	anim.play("Idle")

	if not player:
		current_state = State.IDLE
		return

	await get_tree().create_timer(0.2).timeout

	var direction = (player.global_position - global_position).normalized()
	var dash_distance = 500
	var dash_time = 0.15
	var dash_velocity = direction * (dash_distance / dash_time)
	var dash_start_pos = global_position

	# 🔁 Spawn the clone BEFORE Xarion dashes
	print("📍 Spawning clone at:", dash_start_pos - direction * 80)
	spawn_clone(dash_start_pos - direction * 80, direction)


	# 🔥 Xarion dashes immediately
	parry_area.monitoring = true
	parry_area.set("is_parryable", true)
	attack_area.monitoring = true

	var t := 0.0
	while t < dash_time:
		velocity = dash_velocity
		move_and_slide()
		await get_tree().process_frame
		t += get_process_delta_time()

	velocity = Vector2.ZERO
	parry_area.monitoring = false
	parry_area.set("is_parryable", false)
	attack_area.monitoring = false

	await get_tree().create_timer(1.0).timeout
	current_state = State.IDLE
	attack_timer = attack_cooldown


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
	current_state = State.STAGGERED
	deathblow_pending = true

	anim.play("DeathblowReady")
	print("🟨 Xarion ready for deathblow")

	if player and player.has_method("set_deathblow_target"):
		player.set_deathblow_target(self)

	# NO automatic recovery — waits for player
func deathblow():
	if current_state == State.DEAD:
		print("⚠️ Deathblow called but Xarion is already dead")
		return

	print("☠️ Xarion deathblow executed")
	current_state = State.DEAD

	# Play death animation
	if anim:
		anim.play("Dead")

	# Disable all gameplay logic
	set_physics_process(false)
	set_process(false)

	# Disable collisions
	set_collision_layer(0)
	set_collision_mask(0)

	# Disable attack & parry
	if parry_area:
		parry_area.monitoring = false
		parry_area.set("is_parryable", false)

	if attack_area:
		attack_area.monitoring = false

	# Optional: disable posture bar visibility if used
	if has_node("PostureBar"):
		$PostureBar.visible = false

	# Wait for death animation or delay
	await get_tree().create_timer(0.6).timeout

	# Clean up
	call_deferred("queue_free")



func spawn_clone(pos: Vector2, direction: Vector2):
	print("🧬 Clone instantiated at:", pos)
	var clone = clone_scene.instantiate()
	get_tree().current_scene.add_child(clone)
	clone.global_position = pos

	if clone.has_method("start_dash"):
		print("➡️ Clone received dash command")
		clone.start_dash(direction)
	else:
		print("❌ clone has no start_dash method")
