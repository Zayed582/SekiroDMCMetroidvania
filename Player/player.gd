extends CharacterBody2D

var rank_display_buffer_timer = 0.0
var buffered_rank = ""
var last_shown_rank = ""
var was_on_floor = false
var max_health = 10000
var current_health = 100000
var is_alive = true
var freeze_frames = 0
var pending_parry_areas: Array = []
var parried_lockout = false
var attack_cooldown = 0.0
const ATTACK_COOLDOWN_TIME = 0.4
@export var max_speed := 180.0
@export var acceleration := 3000.0
@export var decceleration := 2000.0

@export var max_air_jumps := 1
var air_jumps_left := 1

var combo_step := 0
var combo_timer := 0.0
const COMBO_MAX_TIME := 0.5
var combo_queued := false

var combo_catalyst_heal_ready := true
const COMBO_CATALYST_HEAL_COOLDOWN := 2.0

var deathblow_ready_target = null
const DEATHBLOW_RANGE = 80
const DEATHBLOW_KEY = "attack"  # Can use a separate action if you want
var parry_burst_scene = preload("res://NotResolvedYet/parryburst.tscn")

@onready var wall_check_left = $WallCheckLeft
@onready var wall_check_right = $WallCheckRight
var shock_blast_scene = preload("res://Effects/CharmEffects/VengefulSpirit/shock_blast.tscn")


@onready var afterimage_scene = preload("res://Effects/AfterImage/afterimage.tscn")
var afterimage_timer := 0.0
const AFTERIMAGE_INTERVAL := 0.05

@export var wall_climb_speed := 100.0
var is_on_wall = false
var is_climbing = false
var original_max_speed = 0.0
var original_parry_cooldown = 0.6

var overdrive_type_parry_distortion := false

var parry_cooldown := 0.0
const PARRY_COOLDOWN_TIME := 0.6  # You can tweak this
var is_charging = false
var charge_timer = 0.0
const CHARGE_THRESHOLD = 0.8  # How long to charge
var active_charm_vengeful_spirit := false  # ✅ Toggle this as needed
var vengeful_spirit_tier := "SMOKIN STYLE"  # or "COOL", "STYLISH"
var has_reduced_damage := false
var reduced_damage_timer := 0.0
var razor_bloom_petals_scene = preload("res://Effects/CharmEffects/RazorBloom/razor_bloom_petals.tscn")
var razor_bloom_explosion_scene = preload("res://Effects/CharmEffects/RazorBloom/razor_bloom_explosion.tscn")
@onready var echo_slash_scene = preload("res://Effects/CharmEffects/Echo Slash/echo_slash.tscn")

var active_charm_double_edged_soul := false
var double_edge_tier := "SMOKIN STYLE"  # or "COOL", "STYLISH"
var overdrive_moonveil := false

var parry_boost_timer := 0.0
var double_edge_s_active := false
var overdrive_clone_echo := false
var is_frozen_in_air = false

@onready var healthbar = get_node("/root/World/UI/ProgressBar")
var active_charm_shock_repeater := false
@export var jump_velocity: float = -800.0
@export var SPEED: float = 200.0
@export var gravity: float = 1200.0
@export var parry_boost: float = -300.0
@onready var attack_area = $AttackArea
var attack_offset = Vector2(65, 0)
var is_locked_from_parry = false
const OVERDRIVE_SPEED_MULTIPLIER := 1.25
const OVERDRIVE_PARRY_COOLDOWN_MULTIPLIER := 0.5
var active_charm_momentum_drive := false
var active_charm_combo_catalyst := false
var combo_catalyst_tier := "SMOKIN STYLE"  # or "COOL", "STYLISH"
var combo_catalyst_heal_cooldown := 0.0
var shock_repeater_tier = "COOL"  # or "STYLISH", "SMOKIN STYLE"
var parry_risk_active := false
var charge_threshold := CHARGE_THRESHOLD
var active_charm_ghostfang_drive := false
var ghostfang_tier := "COOL"  # or "STYLISH", "SMOKIN STYLE"
@onready var enemy_pull_area = $EnemyPullArea
var overdrive_phantom := false  # add at top
var overdrive_infernal := false
var ghostfang_invincible_timer := 0.0
var ghostfang_damage_boost := false
var selected_overdrive_type: String = "moonveil"
var has_air_attacked = false
var is_performing_deathblow := false
var is_deathblow_dashing := false

var deathblow_target = null
@export var max_flow := 100
var current_flow := 0
var overdrive_active := false
var overdrive_timer := 0.0
const OVERDRIVE_DURATION := 5.0
@onready var hurt_area = $HurtArea
@onready var animated_sprite = $AnimatedSprite2D
var hurt_offset = Vector2.ZERO
var sprite_offset = Vector2.ZERO
var dodge_lockout_timer := 0.0  # ← new at top
@export var walk_speed := 600.0
@export var run_speed := 1000.0
const DEFAULT_DODGE_LOCKOUT := 0.3  # ← adjust how strict you want the lock
var is_running = false
var active_charm_razor_bloom := false
var razor_bloom_combo_count := 0
const RAZOR_BLOOM_HIT_LIMIT := 5
const RAZOR_BLOOM_STYLISH_THRESHOLD := 3

@onready var petal_projectile_scene = preload("res://Effects/CharmEffects/RazorBloom/razor_bloom_petals.tscn")
@onready var slash_explosion_scene = preload("res://Effects/CharmEffects/RazorBloom/razor_bloom_explosion.tscn")

@export var wall_jump_force := Vector2(250, -800)
var can_wall_jump = false
var wall_jump_cooldown = 0.0
const WALL_JUMP_COOLDOWN_TIME = 0.2

var active_charm_blood_voltage = false

@export var wall_slide_speed := 250.0
var speed_boost = 1.0
var attack_speed_boost = 1.0
var active_charm_adrenal_edge = false  # toggle if equipped
var infernal_regen_timer := 0.0
const INFERNAL_REGEN_INTERVAL := 1.0  # Heal every 0.4 sec

var parry_combo = 0
var parry_timer = 0.0
var max_parry_cooldown = 3.0
var combo_active = false
var startup_lock := true

var facing_right = true
var dodge_direction = Vector2.ZERO
var is_invincible = false
var is_dodging = false
var dodge_speed = 900
var dodge_duration = 0.2
var dodge_timer = 0.0
var attacking = false

@export var parry_duration: float = 0.2
var is_parrying = false

var is_hurt = false

var can_attack := true




var is_knockedback = false
var recovering_from_knockback = false
var is_knockedback_sliding = false
var knockback_timer = 0.0
var has_landed_from_knockback = false

var rank_meter = 0.0
var rank_thresholds = [0, 2, 4, 6, 8, 10]

func _ready():
	add_to_group("player")
	$ParryDetector.area_entered.connect(_on_ParryDetector_area_entered)
	animated_sprite.play("Idle")
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	startup_lock = false  # ✅ Unlock movement after physics init

	attack_offset = attack_area.position.abs()
	hurt_offset = hurt_area.position.abs()
	sprite_offset = animated_sprite.position

	update_facing()
	global_position.y -= 2
	move_and_slide()
	velocity = Vector2.ZERO



func gain_flow(amount: int):
	if overdrive_active:
		return

	# 💥 Combo Catalyst COOL+ — +10% Flow gain
	if active_charm_combo_catalyst and combo_catalyst_tier in ["COOL", "STYLISH", "SMOKIN STYLE"]:
		amount = int(amount * 1.1)

	current_flow += amount
	if current_flow > max_flow:
		current_flow = max_flow

	print("🌀 Flow:", current_flow)
	update_flow_ui()

	if current_flow == max_flow:
		print("🔥 Overdrive Ready!")




func activate_overdrive():
	print("🔍 SELECTED:", selected_overdrive_type)

	if overdrive_active:
		return

	# 🔥 Infernal Ascension has stricter condition
	if selected_overdrive_type == "infernal":
		if current_flow < max_flow or get_current_parry_rank() != "SMOKIN STYLE":
			print("❌ Infernal Ascension requires SMOKIN STYLE + full Flow!")
			return
	else:
		if current_flow < max_flow:
			return


	overdrive_active = true
	overdrive_timer = OVERDRIVE_DURATION
	current_flow = 0

	print("🔥 OVERDRIVE ACTIVATED!")
	$AnimatedSprite2D.modulate = Color(1, 0.6, 0.2)
	$Camera2D.shake(6.0)

	# Reset all overdrives
	overdrive_moonveil = false
	overdrive_clone_echo = false
	overdrive_type_parry_distortion = false
	overdrive_infernal = false

	# ✅ Enable your selected one (can be changed via debug menu)
	if selected_overdrive_type == "moonveil":
		overdrive_moonveil = true
	elif selected_overdrive_type == "clone_echo":
		overdrive_clone_echo = true
	elif selected_overdrive_type == "parry_distortion":
		overdrive_type_parry_distortion = true
	elif selected_overdrive_type == "phantom":
		overdrive_phantom = true
	elif selected_overdrive_type == "infernal":
		overdrive_infernal = true



func _physics_process(delta):
	if is_performing_deathblow:
		if not is_deathblow_dashing:
			# Allow gravity only after dash ends
			if not is_on_floor():
				velocity.y += gravity * delta
			else:
				velocity.y = 0
			move_and_slide()
		return







	# Clamp cooldowns
	parry_cooldown = max(parry_cooldown - delta, 0)
	attack_cooldown = max(attack_cooldown - delta, 0)
	wall_jump_cooldown = max(0, wall_jump_cooldown - delta)

	# Prevent early input issues by applying gravity before any inputs if not grounded
	if !is_on_floor() and wall_jump_cooldown == 0:
		if is_on_wall and not is_climbing:
			# Apply reduced gravity for wall slide
			var wall_slide_gravity := gravity * 0.5  # Tweak friction strength here
			velocity.y += wall_slide_gravity * delta
			velocity.y = clamp(velocity.y, -100, wall_slide_speed)  # Prevent fast fall
		else:
			velocity.y += gravity * delta

			# ✂️ Cut jump short if jump released while going up
			if velocity.y < 0 and not Input.is_action_pressed("jump"):
				velocity.y += gravity * delta * 2



	# Handle deathblow input
	if deathblow_target and Input.is_action_just_pressed("attack"):
		perform_deathblow()
		return

	# Movement input
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector = input_vector.normalized()
	is_running = Input.is_action_pressed("run")
	max_speed = run_speed if is_running else walk_speed

	# Wall check
	var touching_wall_left = wall_check_left.is_colliding()
	var touching_wall_right = wall_check_right.is_colliding()
	is_on_wall = (touching_wall_left or touching_wall_right) and not is_on_floor()
	is_climbing = is_on_wall and Input.is_action_pressed("ui_up")

	# Wall climb
	if is_climbing:
		velocity.y = -wall_climb_speed

	# Wall jump
	if is_on_wall and Input.is_action_just_pressed("jump") and wall_jump_cooldown == 0:
		var dir = 1 if touching_wall_left else -1
		velocity = Vector2(wall_jump_force.x * dir, wall_jump_force.y)
		facing_right = velocity.x > 0
		update_facing()
		wall_jump_cooldown = WALL_JUMP_COOLDOWN_TIME
		$AnimatedSprite2D.play("WallJump")


	# Regular jump
	if not is_climbing and Input.is_action_just_pressed("jump") and not is_hurt and not is_knockedback_sliding and not recovering_from_knockback:
		if is_on_floor():
			velocity.y = jump_velocity
		elif air_jumps_left > 0:
			velocity.y = jump_velocity
			air_jumps_left -= 1
			#$AnimatedSprite2D.play("DoubleJump")  # Only if you have one


	# Apply friction for knockback slide
	if is_knockedback_sliding and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, 600 * delta)

	# Handle movement logic
	if is_knockedback:
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_knockedback = false
	elif recovering_from_knockback or is_knockedback_sliding:
		pass
	elif is_dodging:
		velocity.x = dodge_direction.x * dodge_speed
	else:
		var target_speed = input_vector.x * max_speed
		var final_speed = target_speed * speed_boost
		velocity.x = move_toward(velocity.x, final_speed, acceleration * delta if input_vector.x != 0 else decceleration * delta)

	# Sprite flip and hurt box offset
	if input_vector.x != 0 and not is_dodging and not is_hurt and not is_knockedback_sliding and not recovering_from_knockback:
		var new_facing = input_vector.x > 0
		if new_facing != facing_right:
			facing_right = new_facing
			update_facing()

	# Lock movement if parried
	if parried_lockout:
		velocity = Vector2.ZERO

	# Recover from landing
	if has_landed_from_knockback and abs(velocity.x) < 5:
		has_landed_from_knockback = false
		start_downed_recovery()

	# Apply velocity
	move_and_slide()

	# === MOMENTUM DRIVE EFFECTS ===
	if active_charm_momentum_drive and parry_combo >= 3:
		# Cancel attack into dodge at COOL+
		if Input.is_action_just_pressed("dodge") and attacking:
			attacking = false
			$AttackArea.monitoring = false
			start_dodge(input_vector)

	# Animation transitions
	if is_dodging:
		if $AnimatedSprite2D.animation != "Dodge":
			if is_on_floor():
				$AnimatedSprite2D.play("Dodge")
			else:
				$AnimatedSprite2D.play("AirDash")

		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false
			is_invincible = false
	else:
		if Input.is_action_just_pressed("dodge") and input_vector.length() > 0 and not is_hurt and not is_knockedback_sliding and not recovering_from_knockback and dodge_lockout_timer <= 0:
			start_dodge(input_vector)

			# Invincibility flash at STYLISH+
			if active_charm_momentum_drive and parry_combo >= 4:
				is_invincible = true
				$AnimatedSprite2D.modulate = Color(1, 1, 0.5)
				await get_tree().create_timer(0.2).timeout
				$AnimatedSprite2D.modulate = Color(1, 1, 1)

			# Reset attack cooldown at SMOKIN STYLE
			if active_charm_momentum_drive and parry_combo > 6:
				attack_cooldown = 0.0

		# ❌ Don't override animation if charging
		if not attacking and not is_parrying and not is_dodging and not is_hurt and not recovering_from_knockback and not is_knockedback_sliding and not is_charging and not is_performing_deathblow:


			# 🔁 WALL ANIMATIONS
			if wall_jump_cooldown > 0 and not is_on_floor():
				$AnimatedSprite2D.play("WallJump")
			elif is_climbing:
				$AnimatedSprite2D.play("Climb")
			elif is_on_wall and velocity.y > 0:
				$AnimatedSprite2D.play("WallSlide")
			# 🔁 AIR + GROUND
			elif not is_on_floor():
				$AnimatedSprite2D.play("jump" if velocity.y < 0 else "Fall")
			else:
				if input_vector.length() > 0:
					$AnimatedSprite2D.play("Sprint" if is_running else "Run")
				else:
					$AnimatedSprite2D.play("Idle")
	# Freeze-frame logic
	if freeze_frames > 0:
		Engine.time_scale = 0.0001
		freeze_frames -= 1
	elif Engine.time_scale < 1.0:
		pass  # Don't override if already in slow-mo
	else:
		Engine.time_scale = 1.0

	# Ground check
	if not was_on_floor and is_on_floor():
		_on_landed()
		air_jumps_left = max_air_jumps
		has_air_attacked = false  # ✅ allow air attack again

	was_on_floor = is_on_floor()




func on_enemy_killed():
	if not active_charm_ghostfang_drive:
		return

	if current_health == 1 and ghostfang_tier == "SMOKIN STYLE":
		current_flow = max_flow
		update_flow_ui()
		print("💥 Ghostfang SMOKIN STYLE: Flow fully restored!")

		# 🔊 Optional: screen shake or global effect
		if has_node("Camera2D"):
			$Camera2D.shake(4.5)

		# 🌩️ Optional: spawn a shockwave or screen flash
		var shock = shock_blast_scene.instantiate()
		shock.global_position = global_position
		get_tree().current_scene.add_child(shock)





func perform_charge_attack():
	attacking = true
	can_attack = false
	$AnimatedSprite2D.play("ChargeAttack")
	$AttackTimer.start()
	$AttackArea.monitoring = true
	$AnimatedSprite2D.flip_h = not facing_right

	# 💥 Deal initial hit to enemies
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			var final_damage = 2.0  # Base charged attack damage

			# ⚔️ Double-Edged Soul bonus
			if active_charm_double_edged_soul and double_edge_tier in ["COOL", "STYLISH", "SMOKIN STYLE"]:
				final_damage *= 1.25
				if double_edge_tier in ["STYLISH", "SMOKIN STYLE"] and parry_boost_timer > 0:
					final_damage *= 1.5
				if double_edge_tier == "SMOKIN STYLE" and get_current_parry_rank() == "SMOKIN STYLE":
					final_damage *= 2.0
					if body.has_method("apply_posture_damage"):
						body.apply_posture_damage(2)

			# 👻 Ghostfang STYLISH+: double damage at 1 HP
			if current_health == 1 and active_charm_ghostfang_drive and ghostfang_tier in ["STYLISH", "SMOKIN STYLE"]:
				final_damage *= 2.0
				print("👻 Ghostfang: Charged double damage at 1 HP!")

			body.take_damage(int(final_damage))

	# 🔁 Shock Repeater STYLISH+: second hit after short delay
	if active_charm_shock_repeater and shock_repeater_tier in ["STYLISH", "SMOKIN STYLE"]:
		await get_tree().create_timer(0.15).timeout

		if $AttackArea.monitoring:
			for body in attack_area.get_overlapping_bodies():
				if body.is_in_group("enemies") and body.has_method("take_damage"):
					body.take_damage(1)
					if body.has_method("apply_posture_damage"):
						body.apply_posture_damage(1)
			print("💢 Shock Repeater STYLISH+: second hit landed!")

	# 🌪️ Shock Repeater SMOKIN STYLE: send echo slashes
	if active_charm_shock_repeater and shock_repeater_tier == "SMOKIN STYLE":
		for i in range(3):
			var slash = echo_slash_scene.instantiate()
			slash.global_position = global_position
			slash.rotation = deg_to_rad(-15 + i * 15)
			slash.set("velocity", Vector2(300, 0).rotated(slash.rotation))
			get_tree().current_scene.add_child(slash)
		print("🌪️ Shock Repeater: Echo slashes launched!")

	# 🔥 Infernal Ascension shockwave on charge
	if overdrive_active and selected_overdrive_type == "infernal":
		var shock = shock_blast_scene.instantiate()
		shock.global_position = global_position
		get_tree().current_scene.add_child(shock)



func spawn_afterimage():
	var ghost = afterimage_scene.instantiate()
	var offset = Vector2(-10 if facing_right else 10, 0)
	ghost.global_position = global_position + offset

	var rank_name = ""  # fallback
	match parry_combo:
		3:
			rank_name = "COOL"
		4:
			rank_name = "STYLISH"
		5:
			rank_name = "SAVAGE"
		6:
			rank_name = "SSSICK!!"
		_:
			if parry_combo > 6:
				# 🔥 Alternate between red and gold clones
				if randf() < 0.5:
					rank_name = "SSSICK!!"
				else:
					rank_name = "SMOKIN STYLE"


	ghost.setup($AnimatedSprite2D, $AnimatedSprite2D.flip_h, rank_name)
	get_parent().add_child(ghost)







func _process(delta):
	
	# 💠 Vengeful Spirit cooldown logic
	if has_reduced_damage:
		reduced_damage_timer -= delta
		if reduced_damage_timer <= 0:
			has_reduced_damage = false

	# 💢 Double-Edged Soul STYLISH+ boost timer
	if parry_boost_timer > 0:
		parry_boost_timer -= delta
		if parry_boost_timer <= 0:
			parry_risk_active = false
			print("💤 Parry boost ended")

	# 🔥 Double-Edged Soul SMOKIN STYLE rank monitor
	if active_charm_double_edged_soul and double_edge_tier == "SMOKIN STYLE":
		var current_rank = get_current_parry_rank()
		if current_rank == "SMOKIN STYLE":
			if not double_edge_s_active:
				print("🔥 Double-Edged Soul: S rank mode active!")
				double_edge_s_active = true
		elif double_edge_s_active and current_rank != "SMOKIN STYLE":
			print("💔 Double-Edged Soul: Dropped from S rank. Losing half HP!")
			current_health = max(1, int(current_health / 2))
			healthbar.value = current_health
			double_edge_s_active = false

	# ⚡ Shock Repeater COOL+ — charge faster
	if active_charm_shock_repeater and shock_repeater_tier in ["COOL", "STYLISH", "SMOKIN STYLE"]:
		charge_threshold = CHARGE_THRESHOLD * 0.7
	else:
		charge_threshold = CHARGE_THRESHOLD

	# Cooldowns
	parry_cooldown = max(parry_cooldown - delta, 0)
	attack_cooldown = max(attack_cooldown - delta, 0)
	dodge_lockout_timer = max(dodge_lockout_timer - delta, 0)
	if combo_catalyst_heal_cooldown > 0:
		combo_catalyst_heal_cooldown -= delta

	# OVERDRIVE timer logic
	# 🔥 Infernal Ascension Trigger (SSS rank + full Flow)
		print("🧪 Checking infernal condition:", selected_overdrive_type, current_flow, get_current_parry_rank())

		if not overdrive_active and selected_overdrive_type == "infernal":
			if current_flow == max_flow and get_current_parry_rank() == "SMOKIN STYLE":
				print("🔥 Infernal Ascension triggered!")
				activate_infernal_ascension()

	if overdrive_active:
			# 🧬 Infernal Ascension regen
		if selected_overdrive_type == "infernal":
			infernal_regen_timer -= delta
			if infernal_regen_timer <= 0.0:
				infernal_regen_timer = INFERNAL_REGEN_INTERVAL
				if current_health < max_health:
					current_health += 1
					healthbar.value = current_health
					print("🔥 Infernal Regen: +1 HP")

		overdrive_timer -= delta
		if overdrive_timer <= 0:
			overdrive_active = false
			print("💤 Overdrive ended")
			$AnimatedSprite2D.modulate = Color(1, 1, 1)
			max_speed = original_max_speed
			parry_cooldown = original_parry_cooldown

	# Manual Overdrive activation
	if Input.is_action_just_pressed("overdrive"):
		activate_overdrive()

	# Parried lockout — only allow dodge or parry
	if parried_lockout:
		if Input.is_action_just_pressed("parry") and not is_parrying and not is_dodging:
			start_parry()
		elif Input.is_action_just_pressed("dodge") and not is_dodging:
			start_dodge(Vector2(facing_right if facing_right else -1, 0))
		return

		# 🔋 Charging logic
	if Input.is_action_pressed("attack") \
		and not attacking \
		and not is_parrying \
		and not is_dodging \
		and not is_hurt \
		and not recovering_from_knockback \
		and is_on_floor():

		if not is_charging:
			is_charging = true
			charge_timer = 0.0
		else:
			charge_timer += delta

			# ✅ Start "Charge" animation after 0.1s to prevent flicker
			if charge_timer >= 0.1 and $AnimatedSprite2D.animation != "Charge":
				$AnimatedSprite2D.speed_scale = 1  # 🔥 Force ensure it's animating
				$AnimatedSprite2D.play("Charge")

	elif is_charging:
		if charge_timer >= charge_threshold:
			perform_charge_attack()
		elif attack_cooldown <= 0 and not attacking:
			perform_normal_attack()

		# ✅ Reset charging state
		is_charging = false
		charge_timer = 0.0





	# 🛡️ Parry input
	if Input.is_action_just_pressed("parry") and parry_cooldown <= 0 and not is_parrying and not attacking and not is_dodging and not is_hurt and not is_knockedback_sliding and not recovering_from_knockback:
		parry_cooldown = 0.6
		start_parry()

	# 🔁 Combo decay logic
	if combo_active:
		parry_timer -= delta
		if parry_timer <= 0:
			combo_active = false
			parry_combo = 0
			rank_meter = 0.0
			update_rank_meter_ui()
			update_parry_rank_ui(true)

	# 🅁 Rank display delay buffer
	if rank_display_buffer_timer > 0:
		rank_display_buffer_timer -= delta
		if rank_display_buffer_timer <= 0 and buffered_rank != "":
			show_rank(buffered_rank)

	# 🛡️ Active parry window detection
	if is_parrying:
		for area in $ParryDetector.get_overlapping_areas():
			if not area.is_in_group("parryable") or area in pending_parry_areas:
				continue
			var target = area
			if "is_parryable" not in area:
				if area.get_owner() and "is_parryable" in area.get_owner():
					target = area.get_owner()
				elif area.get_parent() and "is_parryable" in area.get_parent():
					target = area.get_parent()
			if "is_parryable" in target and target.is_parryable:
				pending_parry_areas.append(area)
				print("✅ Re-added during parry:", area.name)

	# 🕷️ Afterimage trail for SMOKIN STYLE
	if parry_combo >= 5:
		afterimage_timer -= delta
		if afterimage_timer <= 0:
			spawn_afterimage()
			afterimage_timer = AFTERIMAGE_INTERVAL
			
			
			
			# 🥋 Combo input buffer
	if Input.is_action_just_pressed("attack") and attacking:
		combo_queued = true

	# 🥋 Allow simple tap attacks (when not charging or locked)
	if Input.is_action_just_pressed("attack") \
		and not is_charging \
		and not attacking \
		and not is_parrying \
		and not is_dodging \
		and not is_hurt \
		and not recovering_from_knockback \
		and attack_cooldown <= 0:

		combo_step = 0  # 🔧 Reset combo chain if idle
		perform_normal_attack()





func activate_infernal_ascension():
	get_node("/root/World/CanvasLayer/UI/AnimationPlayer").play("infernal_flash")

	var tint = get_node("/root/World/UI/InfernalTint")
	var fx_player = get_node("/root/World/UI/InfernalFXPlayer")  # ← AnimationPlayer

	print("🧨 ENTERED ACTIVATE INFERNAL ASCENSION")

	tint.visible = true
	fx_player.play("infernal_flash")  # Fade in tint

	infernal_regen_timer = 0.0
	overdrive_active = true
	overdrive_timer = 8.0
	current_flow = 0

	print("🔥 INFERNAL ASCENSION MODE!")
	Engine.time_scale = 0.4
	$AnimatedSprite2D.modulate = Color(1.2, 0.4, 0.2)

	if has_node("Camera2D"):
		$Camera2D.shake(6.5)

	# Regen setup
	var regen_timer = Timer.new()
	regen_timer.name = "InfernalRegenTimer"
	regen_timer.one_shot = false
	regen_timer.wait_time = 0.5
	regen_timer.timeout.connect(func():
		if current_health < max_health:
			current_health += 1
			healthbar.value = current_health
	)
	add_child(regen_timer)
	regen_timer.start()

	# Wait for duration
	await get_tree().create_timer(8.0).timeout

	# Reset state
	Engine.time_scale = 1.0
	$AnimatedSprite2D.modulate = Color(1, 1, 1)
	overdrive_active = false

	if has_node("InfernalRegenTimer"):
		$InfernalRegenTimer.queue_free()

	# Fade out tint
	fx_player.play_backwards("infernal_flash")
	await fx_player.animation_finished
	tint.visible = false

	print("💤 Infernal Ascension ended")









func update_flow_ui():
	var bar = get_node_or_null("/root/World/UI/FlowMeter")
	if bar:
		bar.value = current_flow



func start_parry():
	parry_cooldown = 0.6  # ⏱️ adjust as needed
	is_parrying = true

	# 🔁 Choose animation based on grounded or midair
	if not is_on_floor():
		$AnimatedSprite2D.play("MidAirParry")
	else:
		$AnimatedSprite2D.play("Parry")

	print("🛡️ Parry activated!")
	await get_tree().process_frame

	var did_parry = false

	for area in pending_parry_areas:
		if area and area.is_inside_tree():
			print("🛠️ Checking parry target for:", area.name)

			var target = area
			if not area.has_method("on_parried"):
				if area.get_owner() and area.get_owner().has_method("on_parried"):
					target = area.get_owner()
				elif area.get_parent() and area.get_parent().has_method("on_parried"):
					target = area.get_parent()

			if target and target.has_method("on_parried"):
				target.on_parried()
				print("✅ on_parried() called on:", target.name)
				did_parry = true
			else:
				print("❌ No valid on_parried() found for:", area.name)

			if not area.is_in_group("projectile"):
				area.set_deferred("monitoring", false)

	if did_parry:
			# 🔥 Infernal Ascension — AOE burst on parry
		if overdrive_active and selected_overdrive_type == "infernal":
			var burst = parry_burst_scene.instantiate()
			burst.global_position = global_position
			get_tree().current_scene.add_child(burst)

		OS.delay_msec(200)
		$Camera2D.shake(4.0)
		print("🚧 is_on_floor():", is_on_floor(), "| velocity.y:", velocity.y)
		if not is_on_floor():
			print("🟣 BOOSTING JUMP")
			velocity.y = parry_boost
		else:
			print("🟤 No boost, grounded")
		parry()

	await get_tree().create_timer(parry_duration).timeout
	pending_parry_areas.clear()
	is_parrying = false
	print("🛡️ Parry ended")
	is_locked_from_parry = false



func parry():
	freeze_frame(1)
	$ParrySFX.play()
	rank_meter += 1.0
	gain_flow(20)

	# 💚 Combo Catalyst STYLISH+ — heal 1 HP on parry (with cooldown)
	if active_charm_combo_catalyst and combo_catalyst_heal_ready:
		var current_rank = get_current_parry_rank()
		if current_rank in ["STYLISH", "SMOKIN STYLE"]:
			if current_health < max_health:
				current_health += 1
				healthbar.value = current_health
				print("💚 Combo Catalyst: +1 HP")

			combo_catalyst_heal_ready = false
			await get_tree().create_timer(COMBO_CATALYST_HEAL_COOLDOWN).timeout
			combo_catalyst_heal_ready = true

	# 🛡️ Short invincibility after parry
	is_invincible = true
	await get_tree().create_timer(0.5).timeout
	is_invincible = false

	# 💠 Vengeful Spirit COOL+ effect
	if active_charm_vengeful_spirit and vengeful_spirit_tier in ["COOL", "STYLISH", "SMOKIN STYLE"]:
		has_reduced_damage = true
		reduced_damage_timer = 2.0

	# ⚔️ Double-Edged Soul STYLISH+ effect
	if active_charm_double_edged_soul and double_edge_tier in ["STYLISH", "SMOKIN STYLE"]:
		parry_boost_timer = 3.0
		parry_risk_active = true
		print("🩸 Double-Edged Soul: Parry boost activated!")

	# 🔼 Rank logic
	var max_threshold = rank_thresholds[rank_thresholds.size() - 1]
	if rank_meter > max_threshold:
		rank_meter = max_threshold
	for i in range(rank_thresholds.size() - 1, -1, -1):
		if rank_meter >= rank_thresholds[i]:
			parry_combo = rank_thresholds[i]
			break

	# ⏳ Extend SMOKIN STYLE duration
	if parry_combo > 6:
		parry_timer = 20.0  # Longer combo window for highest rank
	else:
		parry_timer = max_parry_cooldown

	combo_active = true

	# 🔥 Overdrive-only: Parry Time Distortion
	if overdrive_active and overdrive_type_parry_distortion:
		print("⚡ Parry Distortion Triggered!")
		await slow_motion(0.3, 0.3)


		

		# 🧲 Pull nearby enemies slightly toward player
		for body in enemy_pull_area.get_overlapping_bodies():
			if body.is_in_group("enemies") and body.has_method("apply_central_impulse"):
				var direction = (global_position - body.global_position).normalized()
				body.apply_central_impulse(direction * -150)  # Negative = toward player
			elif body.is_in_group("enemies"):
				var dir = body.global_position.direction_to(global_position)
				body.global_position += dir * 30  # Basic fallback pull if no physics

	update_rank_meter_ui()
	update_parry_rank_ui()

	# 🩸 Blood Voltage effects
	if active_charm_blood_voltage:
		for area in pending_parry_areas:
			var target = area
			if not area.has_method("on_parried"):
				if area.get_owner() and area.get_owner().has_method("on_parried"):
					target = area.get_owner()
				elif area.get_parent() and area.get_parent().has_method("on_parried"):
					target = area.get_parent()

			if is_instance_valid(target):
				if parry_combo >= 3 and target.has_method("apply_posture_damage"):
					target.apply_posture_damage(1)
				if parry_combo >= 4 and target.has_method("extend_stagger_duration"):
					target.extend_stagger_duration(0.3)
				if parry_combo > 6:
					if target.has_method("take_damage"):
						target.take_damage()
					if target.has_method("apply_air_knockback"):
						target.apply_air_knockback()

	# ⚡ Combo Catalyst SMOKIN STYLE effect — hit enemies reset posture & give bonus Flow
	if active_charm_combo_catalyst and get_current_parry_rank() == "SMOKIN STYLE":
		for area in pending_parry_areas:
			var target = area
			if not area.has_method("on_parried"):
				if area.get_owner() and area.get_owner().has_method("on_parried"):
					target = area.get_owner()
				elif area.get_parent() and area.get_parent().has_method("on_parried"):
					target = area.get_parent()

			if is_instance_valid(target):
				# 💥 Reset enemy posture if they support it
				if target.has_method("apply_posture_damage"):
					target.apply_posture_damage(-target.max_posture)  # Reset to 0
					print("🌀 Combo Catalyst: Reset enemy posture")

				# 💧 Build extra Flow
				gain_flow(30)





func get_current_parry_rank() -> String:
	match parry_combo:
		3:
			return "COOL"
		4:
			return "STYLISH"
		5:
			return "SAVAGE"
		6:
			return "SSSICK!!"
		_:
			if parry_combo > 6:
				return "SMOKIN STYLE"
	return "DULL"


func _on_attack_timer_timeout():
	$AttackArea.rotation = 0
	$AttackArea.position = attack_offset  # your saved original position
	$AttackArea.monitoring = false

	if combo_queued and combo_step < 2:
		combo_step += 1
		combo_queued = false
		perform_normal_attack()  # Chain next attack
	else:
		combo_step = 0
		combo_queued = false
		attacking = false
		can_attack = true
		$AnimatedSprite2D.play("Idle")


func start_dodge(direction):
	if is_hurt or is_knockedback_sliding or recovering_from_knockback:
		return

	print("🚨 start_dodge called")

	is_dodging = true
	dodge_timer = dodge_duration
	dodge_direction = direction.normalized()

	is_invincible = true

	# 👻 Phantom Drive blink dash
	if overdrive_active and overdrive_phantom:
		# 🌌 Phantom afterimage trail
		for i in range(3):
			var ghost = afterimage_scene.instantiate()
			ghost.global_position = global_position - (dodge_direction * i * 10)
			ghost.setup($AnimatedSprite2D, $AnimatedSprite2D.flip_h, "PHANTOM")
			get_parent().add_child(ghost)
			await get_tree().create_timer(0.03).timeout

		print("👻 Phantom Drive: Blink dash!")

		var blink_distance := 120
		var blink_vector: Vector2 = direction.normalized() * blink_distance

		global_position += blink_vector
		# 🔥 Phantom Blink afterimage trail
		for i in range(3):
			await get_tree().create_timer(0.05).timeout
			spawn_afterimage()


		spawn_afterimage()  # Use your existing afterimage system
		$Camera2D.shake(2.0)
		if has_node("BlinkSFX"):
			$BlinkSFX.play()
		return

	# 🌀 Momentum Drive flashing
	if active_charm_momentum_drive and parry_combo >= 4:
		$AnimatedSprite2D.modulate = Color(1, 1, 0.5)
		await get_tree().create_timer(0.2).timeout
		$AnimatedSprite2D.modulate = Color(1, 1, 1)

	# 🌙 Moonveil Mirage spawn
	if overdrive_active:
		print("✅ Overdrive is active")
	if overdrive_moonveil:
		print("✅ Moonveil is active")
	if get_tree().has_group("mirage"):
		print("❌ Mirage already exists")

	if overdrive_active and overdrive_moonveil and not get_tree().has_group("mirage"):
		print("🌙 Spawning Mirage")
		var mirage_scene = preload("res://Effects/OverDriveEffects/MoonVeilMirage/moonveil_mirage.tscn")
		var mirage = mirage_scene.instantiate()
		mirage.global_position = global_position
		mirage.facing_right = facing_right
		mirage.scale = scale
		mirage.position = position
		mirage.get_node("AnimatedSprite2D").position = $AnimatedSprite2D.position
		mirage.get_node("AnimatedSprite2D").scale = $AnimatedSprite2D.scale
		get_tree().current_scene.add_child(mirage)


func on_pogo_hit_by_enemy(enemy):
	if not enemy.has_meta("pogo_counter"):
		enemy.set_meta("pogo_counter", 1)
	else:
		var counter = int(enemy.get_meta("pogo_counter")) + 1
		enemy.set_meta("pogo_counter", counter)

		if counter >= 3:
			print("🔁 Enemy parry trigger on pogo #4!")
			enemy.set_meta("pogo_counter", 0)

			# ✅ Let the enemy launch the player
			if enemy.has_method("start_pogo_counter_attack"):
				enemy.start_pogo_counter_attack()

			# ✅ DO NOT zero the velocity here — player is already flying

			is_locked_from_parry = true
			attacking = false
			$AnimatedSprite2D.play("Hurt")

			await get_tree().create_timer(0.4).timeout  # Delay before enemy dashes

			if enemy.has_method("start_pogo_counter_dash"):
				enemy.start_pogo_counter_dash()

			# ⚡ Unlock the player JUST before dash hits
			await get_tree().create_timer(0.3).timeout
			parried_lockout = true
			is_locked_from_parry = false
			print("⚡ Locked! Must parry now!!")
			$Camera2D.shake(2.5)



func launch_for_pogo_punish(enemy):
	if is_invincible:
		return

	print("🚀 Pogo punish launched!")
	is_invincible = true
	is_hurt = true

	# 💥 Force diagonal launch: upward + away from enemy
	var direction = (global_position - enemy.global_position).normalized()
	direction.y = -0.2  # Strong upward force
	direction = direction.normalized()
	velocity = direction * 3600  # Adjust total strength here

	$AnimatedSprite2D.play("Hurt")
	$Camera2D.shake(3.5)

	# ⏳ Wait in air before locking
	await get_tree().create_timer(1.0).timeout

	# ✅ Now lock movement AFTER flying starts
	parried_lockout = true
	is_locked_from_parry = true
	is_hurt = false

	# Give player time to react with a parry
	await get_tree().create_timer(0.8).timeout

	if parried_lockout:
		print("💢 Didn't parry in time!")
		take_damage(true)

	parried_lockout = false
	is_locked_from_parry = false
	is_invincible = false

	if is_on_floor():
		$AnimatedSprite2D.play("Idle")
	else:
		$AnimatedSprite2D.play("Fall")






func update_rank_meter_ui():
	var meter = get_node_or_null("/root/World/UI/ParryRankMeter")
	if meter:
		meter.value = clamp(rank_meter, 0, meter.max_value)

func freeze_frame(frames := 1):
	Engine.time_scale = 0.0001
	await get_tree().process_frame
	for i in range(frames - 1):
		await get_tree().process_frame
	Engine.time_scale = 1.0




func _on_attack_area_body_entered(body):
	if body.is_in_group("enemies") and attacking:
		if body.has_method("take_damage"):
			body.take_damage()

func perform_normal_attack():
	if is_on_wall and not is_on_floor():
		print("🚫 Can't attack while sliding or climbing wall")
		return

	var is_air_attack = not is_on_floor() and not is_on_wall
	can_attack = false
	attacking = true
	attack_cooldown = ATTACK_COOLDOWN_TIME
	$AttackArea.monitoring = true
	$AttackTimer.start()
	$AnimatedSprite2D.flip_h = not facing_right

	if is_air_attack and not has_air_attacked:
		var aim_direction = (get_global_mouse_position() - global_position).normalized()

		# Rotate and position AttackArea based on aim
		$AttackArea.rotation = aim_direction.angle()
		$AttackArea.position = aim_direction * 40

		$AnimatedSprite2D.play("AirAttack1")

		var angle = abs(aim_direction.angle_to(Vector2.UP))
		var diagonal_factor = clamp(abs(cos(angle)), 0.4, 1.0)
		var boost_strength = lerp(500, 1000, diagonal_factor)
		velocity = aim_direction * boost_strength

		combo_step = 0
		combo_queued = false
		has_air_attacked = true

		$AttackArea.get_node("CollisionShape2D").scale = Vector2(1.5, 1.5)
		$AttackArea.get_node("CollisionShape2D").scale = Vector2(1, 1)

		await get_tree().physics_frame
		await get_tree().physics_frame

		var hit_something := false
		for body in $AttackArea.get_overlapping_bodies():
			print("🔍 Checking:", body.name)
			if body.is_in_group("enemies"):
				print("✅ Enemy hit:", body.name)
				if body.has_method("take_damage"):
					body.take_damage()
					hit_something = true

					var down_dot = aim_direction.dot(Vector2.DOWN)
					var is_pogo = down_dot > 0.7
					print("🔽 Aim dot: ", down_dot)

					if is_pogo:
						velocity.y = -1000
						has_air_attacked = false
						print("⬇️ POGO JUMP triggered!")
						if has_method("on_pogo_hit_by_enemy"):
							on_pogo_hit_by_enemy(body)
					else:
						velocity += -aim_direction * 2000
						print("↩️ DIAGONAL RECOIL triggered!")

		if not hit_something:
			print("❌ Hit nothing")

		return

	# 🥋 GROUND COMBO ATTACK
	$AttackArea.rotation = 0
	$AttackArea.position = Vector2(40, 0) if facing_right else Vector2(-40, 0)

	match combo_step:
		0:
			$AnimatedSprite2D.play("Attack")
		1:
			$AnimatedSprite2D.play("Attack2")
		2:
			$AnimatedSprite2D.play("Attack3")

	combo_timer = COMBO_MAX_TIME




	# ✅ All the rest below only applies to **ground attacks**
	# 🌸 Razor Bloom Effects
	if active_charm_razor_bloom:
		var current_rank = get_current_parry_rank()
		if current_rank in ["STYLISH", "SMOKIN STYLE"]:
			razor_bloom_combo_count += 1
			if razor_bloom_combo_count == RAZOR_BLOOM_STYLISH_THRESHOLD:
				spawn_razor_petals()
				razor_bloom_combo_count = 0
			if current_rank == "SMOKIN STYLE" and razor_bloom_combo_count % 5 == 0:
				spawn_razor_explosion()
		else:
			razor_bloom_combo_count = 0

	# 🦶 Momentum Drive - dodge lockout tweak
	if active_charm_momentum_drive and parry_combo > 6:
		dodge_lockout_timer = 0.0
	elif active_charm_momentum_drive and parry_combo >= 3:
		dodge_lockout_timer = 0.1
	else:
		dodge_lockout_timer = 0.3

	# 💥 Charm-based bonus damage
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			var final_damage = 1.0

			if active_charm_double_edged_soul and double_edge_tier in ["COOL", "STYLISH", "SMOKIN STYLE"]:
				final_damage *= 1.25
				if double_edge_tier in ["STYLISH", "SMOKIN STYLE"] and parry_boost_timer > 0:
					final_damage *= 1.5
				if double_edge_tier == "SMOKIN STYLE" and get_current_parry_rank() == "SMOKIN STYLE":
					final_damage *= 2.0
					if body.has_method("apply_posture_damage"):
						body.apply_posture_damage(2)

			if current_health == 1 and active_charm_ghostfang_drive and ghostfang_tier in ["STYLISH", "SMOKIN STYLE"]:
				final_damage *= 2.0
				print("👻 Ghostfang: Double damage at 1 HP!")

			body.take_damage(int(final_damage))

	# 🔥 Infernal Ascension shockwave — apply during Infernal mode
	if overdrive_active and selected_overdrive_type == "infernal":
		await get_tree().create_timer(0.1).timeout
		var shock = shock_blast_scene.instantiate()
		shock.global_position = global_position
		get_tree().current_scene.add_child(shock)

	# 🌀 Overdrive: Clone Echo
	if overdrive_active and overdrive_clone_echo:
		var clone_sprite = AnimatedSprite2D.new()
		clone_sprite.sprite_frames = $AnimatedSprite2D.sprite_frames
		clone_sprite.animation = "Attack"
		clone_sprite.flip_h = $AnimatedSprite2D.flip_h
		clone_sprite.scale = $AnimatedSprite2D.scale
		clone_sprite.z_as_relative = true
		clone_sprite.z_index = $AnimatedSprite2D.z_index - 1
		clone_sprite.modulate = Color(0.7, 0.7, 1, 0.6)
		clone_sprite.global_position = global_position + Vector2(10 if facing_right else -10, -100)
		get_tree().current_scene.add_child(clone_sprite)

		await get_tree().create_timer(0.3).timeout
		clone_sprite.play("Attack")

		var echo_hitbox = $AttackArea.duplicate()
		echo_hitbox.name = "EchoHitbox"
		echo_hitbox.global_position = clone_sprite.global_position + Vector2(65 if facing_right else -65, 0)
		echo_hitbox.collision_layer = $AttackArea.collision_layer
		echo_hitbox.collision_mask = $AttackArea.collision_mask
		get_tree().current_scene.add_child(echo_hitbox)
		await get_tree().process_frame
		echo_hitbox.monitoring = true
		echo_hitbox.set_deferred("monitoring", true)

		var col_shape = echo_hitbox.get_node_or_null("CollisionShape2D")
		if col_shape:
			col_shape.disabled = false
			col_shape.visible = true

		for body in echo_hitbox.get_overlapping_bodies():
			if body.is_in_group("enemies") and body.has_method("take_damage"):
				body.take_damage(10)

		await get_tree().create_timer(1.15).timeout
		echo_hitbox.queue_free()
		clone_sprite.queue_free()











		
	



func _on_hurt_area_body_entered(body):
	# Disable contact damage from enemy bodies (Mario-style damage)
	pass


func take_damage(force := false):
	if is_invincible and not force:
		print("Ignored damage because invincible!")
		return

	if is_invincible and force:
		print("🛑 Forced damage while invincible!")
		is_invincible = false

	if is_hurt and not force:
		print("Skipped damage because already hurt")
		return

	if is_hurt and force:
		print("💢 Forced through hurt state")
		is_hurt = false

	# 💥 Apply damage
	var final_damage = 1

	# ☠️ Double-Edged Soul STYLISH+ punish
	if active_charm_double_edged_soul and double_edge_tier in ["STYLISH", "SMOKIN STYLE"] and parry_risk_active:
		current_health = 1
		parry_boost_timer = 0.0
		parry_risk_active = false
		print("☠️ Double-Edged Soul: Punished! Dropped to 1 HP")

	if has_reduced_damage and not force:
		final_damage = max(1, int(ceil(1 * 0.5)))  # always at least 1

	# ⚔️ Double-Edged Soul: take more damage
	if active_charm_double_edged_soul and double_edge_tier in ["COOL", "STYLISH", "SMOKIN STYLE"]:
		final_damage = int(final_damage * 1.25)

	current_health -= final_damage
	healthbar.value = current_health
	print("Player Health:", current_health)

	# 👻 Ghostfang Drive: 1 HP trigger
	if active_charm_ghostfang_drive and current_health == 1:
		if ghostfang_tier in ["COOL", "STYLISH", "SMOKIN STYLE"]:
			is_invincible = true
			ghostfang_invincible_timer = 2.0  # 2 seconds of invincibility
			print("👻 Ghostfang: Invincible at 1 HP!")

	# 💔 Lose style on hit (cut in half)
	parry_combo = max(0, parry_combo / 2)
	rank_meter = clamp(rank_meter / 2.0, 0.0, rank_thresholds[-1])
	update_rank_meter_ui()
	update_parry_rank_ui(true)

	# 🌩️ Vengeful Spirit STYLISH+ shockwave
	var rank = get_current_parry_rank()
	if active_charm_vengeful_spirit and rank in ["STYLISH", "SMOKIN STYLE"]:
		var shock = shock_blast_scene.instantiate()
		shock.global_position = global_position
		get_tree().current_scene.add_child(shock)

	# 🔥 Vengeful Spirit SMOKIN STYLE AOE burst
	if active_charm_vengeful_spirit and rank == "SMOKIN STYLE":
		var burst = parry_burst_scene.instantiate()
		burst.global_position = global_position
		get_tree().current_scene.add_child(burst)

	# ❌ Cancel parry and lockout it
	is_parrying = false
	parry_cooldown = PARRY_COOLDOWN_TIME
	pending_parry_areas.clear()
	
	# 💢 Play hurt animation and red flash
	is_hurt = true
	$AnimatedSprite2D.play("Hurt")
	flash_red_fast()

	await get_tree().create_timer(0.6).timeout  # Match duration of Hurt animation
	is_hurt = false

	if is_on_floor():
		$AnimatedSprite2D.play("Idle")
	else:
		$AnimatedSprite2D.play("Fall")



	# 💨 Knockback only (no lockouts)
	var knockback_force = 450
	velocity.x = (-1 if facing_right else 1) * knockback_force
	velocity.y = -200
	freeze_frame(1)

	# 🛡️ Temporary invincibility after hit
	if not force:
		is_invincible = true
		await get_tree().create_timer(0.5, false, true).timeout

		is_invincible = false

	# ☠️ Death check
	if current_health <= 0:
		die()
		return

	# 🔓 Cleanup any lock states
	if parried_lockout:
		print("🔓 Unlocking parried lock due to hit")
		parried_lockout = false

	is_locked_from_parry = false
	is_hurt = false










func die():
	is_alive = false
	print("YOU DIED!")
	$"/root/World/UI/DeathMenu".visible = true
	set_physics_process(false)
	set_process(false)
	$AnimatedSprite2D.stop()

func _on_landed():
	if is_knockedback or is_hurt:
		print("💥 Slammed into ground! Waiting to stop sliding")
		has_landed_from_knockback = true
	else:
		$Camera2D.shake(1.5)
		$LandingDust.emitting = false
		$LandingDust.emitting = true

func start_downed_recovery():
	recovering_from_knockback = true
	is_knockedback = false
	is_knockedback_sliding = false
	
	$AnimatedSprite2D.play("Downed")
	flash_red_slow(1.2)

	await get_tree().create_timer(1.2).timeout

	# ✅ finally now it's safe to say he's not hurt anymore
	is_hurt = false
	recovering_from_knockback = false
	$AnimatedSprite2D.play("Idle")

func spawn_razor_petals():
	var petals = petal_projectile_scene.instantiate()
	petals.global_position = global_position
	petals.direction = Vector2(1 if facing_right else -1, 0)
	get_tree().current_scene.add_child(petals)
	print("🌸 Razor Bloom: Petals fired!")

func spawn_razor_explosion():
	var explosion = slash_explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	print("💥 Razor Bloom: Explosion triggered!")


func _on_ParryDetector_area_entered(area):
	print("ENTERED:", area.name, "| in parryable group?", area.is_in_group("parryable"))

	if not area.is_in_group("parryable"):
		return

	var target = area

	# 🔍 Climb to owner or parent if needed
	if !"is_parryable" in area:
		if area.get_owner() and "is_parryable" in area.get_owner():
			target = area.get_owner()
		elif area.get_parent() and "is_parryable" in area.get_parent():
			target = area.get_parent()

	var value = target.get("is_parryable") if "is_parryable" in target else false
	print("🔍 Parry check:", target.name, "| is_parryable:", value)

	if value:
		if area not in pending_parry_areas:
			pending_parry_areas.append(area)
			print("✅ Added to pending:", area.name)
	else:
		print("❌ Not parryable:", area.name)


func freeze_frame_for_one_frame():
	get_tree().paused = true
	await get_tree().process_frame
	get_tree().paused = false

func update_parry_rank_ui(force_show := false):
	var rank = ""
	match parry_combo:
		1, 2:
			rank = "DULL"
		3:
			rank = "COOL"
		4:
			rank = "STYLISH"
		5:
			rank = "SAVAGE"
		6:
			rank = "SSSICK!!"
		_:
			if parry_combo > 6:
				rank = "SMOKIN STYLE"

	if active_charm_adrenal_edge:
		match parry_combo:
			3:
				speed_boost = 1.1
				attack_speed_boost = 1.0
				$AnimatedSprite2D.modulate = Color(1.1, 1.1, 1.1)
				
			4:
				speed_boost = 1.2
				attack_speed_boost = 1.1
				$AnimatedSprite2D.modulate = Color(1.15, 1.15, 1.15)
				
			5, 6:
				speed_boost = 1.3
				attack_speed_boost = 1.2
				$AnimatedSprite2D.modulate = Color(1.25, 1.25, 1.25)
				
			_:
				speed_boost = 1.0
				attack_speed_boost = 1.0
				$AnimatedSprite2D.modulate = Color(1, 1, 1)
				
	else:
		speed_boost = 1.0
		attack_speed_boost = 1.0
		$AnimatedSprite2D.modulate = Color(1, 1, 1)

	if not force_show and rank == "DULL" and last_shown_rank != "":
		return
	buffered_rank = rank
	rank_display_buffer_timer = 0.25
	show_rank(rank)
	
# 💥 Micro camera shake on high rank gain
	if rank in ["STYLISH", "SAVAGE", "SSSICK!!", "SMOKIN STYLE"]:
		$Camera2D.shake(1.2)  # Adjust intensity to your taste



func show_rank(rank: String):
	if rank == last_shown_rank:
		return
	var label = get_node("/root/World/UI/ParryRankLabel")
	label.text = rank
	label.modulate.a = 1.0
	label.scale = Vector2(1.5, 1.5)
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	last_shown_rank = rank

func slow_motion(duration := 0.5, slow_factor := 0.3) -> void:
	print("🎞️ Simulated slow-mo")

	Engine.time_scale = slow_factor
	await get_tree().create_timer(duration, false, true).timeout
	Engine.time_scale = 1.0

	print("⏱️ Slow-mo ended")









func flash_red_slow(duration := 0.6, interval := 0.1):
	var flash_timer = 0.0

	while flash_timer < duration:
		var tween1 = create_tween()
		tween1.tween_property($AnimatedSprite2D, "modulate", Color(1, 0.3, 0.3), interval / 2)
		await tween1.finished

		var tween2 = create_tween()
		tween2.tween_property($AnimatedSprite2D, "modulate", Color(1, 1, 1), interval / 2)
		await tween2.finished

		flash_timer += interval


func flash_red_fast(duration := 1.0, interval := 0.05):
	var flash_timer = 0.0

	while flash_timer < duration:
		var tween1 = create_tween()
		tween1.tween_property($AnimatedSprite2D, "modulate", Color(1, 0.2, 0.2), interval / 2)
		await tween1.finished

		var tween2 = create_tween()
		tween2.tween_property($AnimatedSprite2D, "modulate", Color(1, 1, 1), interval / 2)
		await tween2.finished

		flash_timer += interval


func is_attacking() -> bool:
	return attacking

func on_parried(source = null):
	is_locked_from_parry = true
	parried_lockout = true
	is_hurt = false
	is_invincible = false
	is_parrying = false
	attacking = false
	is_dodging = false
	is_knockedback = false
	is_knockedback_sliding = false
	$AnimatedSprite2D.play("Hurt")
	velocity = Vector2(-1 if facing_right else 1, 0) * 200

	# Reflect beam if source is valid and supports it
	if source and source.has_method("reflect_beam"):
		source.reflect_beam()

	await get_tree().create_timer(0.8).timeout

	is_hurt = false
	parried_lockout = false

	if is_on_floor():
		$AnimatedSprite2D.play("Idle")
	else:
		$AnimatedSprite2D.play("Fall")



func update_facing():
	var flip = 1 if facing_right else -1

	animated_sprite.flip_h = not facing_right
	animated_sprite.position = sprite_offset * Vector2(flip, 1)
	attack_area.position = attack_offset * Vector2(flip, 1)
	hurt_area.position = hurt_offset * Vector2(flip, 1)




func unlock_parry_lock():
	if parried_lockout:
		print("🧯 Failsafe: Manual unlock")
		parried_lockout = false
		is_hurt = false
		if is_on_floor():
			$AnimatedSprite2D.play("Idle")
		else:
			$AnimatedSprite2D.play("Fall")


func set_deathblow_target(enemy):
	deathblow_target = enemy  # ✅ not deathblow_ready_target
	print("🎯 Ready for Deathblow!")

	



func perform_deathblow():
	is_performing_deathblow = true

	if not is_instance_valid(deathblow_target) or not deathblow_target.is_inside_tree():
		print("❌ Invalid or missing deathblow target")
		is_performing_deathblow = false
		return

	print("🧨 Starting deathblow on:", deathblow_target.name)

	# Face the enemy
	facing_right = deathblow_target.global_position.x > global_position.x
	$AnimatedSprite2D.flip_h = not facing_right

	# Preserve Y position depending on air/ground
	var enemy_y = deathblow_target.global_position.y
	var target_y = global_position.y

	if not is_on_floor() and global_position.y < enemy_y - 40:
		target_y = enemy_y - 40  # Clamp just above
	elif is_on_floor():
		target_y = enemy_y

	var front_offset = Vector2(-40, 0) if facing_right else Vector2(40, 0)
	var behind_offset = Vector2(500, 0) if facing_right else Vector2(-500, 0)

	# Snap to front of enemy
	global_position = Vector2(deathblow_target.global_position.x + front_offset.x, target_y)
	velocity = Vector2.ZERO

	# Play appropriate animation
	if not is_on_floor():
		$AnimatedSprite2D.play("AirDeathBlow")
	else:
		$AnimatedSprite2D.play("DeathBlow")
	print("✅ Now playing: ", $AnimatedSprite2D.animation)

	# Camera shake and quick slow motion
	$Camera2D.shake(6.0)
	await slow_motion(0.02, 0.02)

	# Slice dash-through
	is_deathblow_dashing = true
	var duration := 0.15
	var elapsed := 0.0
	var start_pos = global_position
	var end_pos = Vector2(deathblow_target.global_position.x + behind_offset.x, target_y)

	while elapsed < duration:
		var t = elapsed / duration
		global_position = start_pos.lerp(end_pos, t)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	global_position = end_pos
	is_deathblow_dashing = false

	# Wait for animation to finish
	var finished := false
	$AnimatedSprite2D.animation_finished.connect(func(): finished = true, CONNECT_ONE_SHOT)

	var t2 := 0.0
	while not finished and t2 < 1.0:
		await get_tree().process_frame
		t2 += get_process_delta_time()

	# Trigger enemy death
	if "deathblow_pending" in deathblow_target:
		deathblow_target.deathblow_pending = false

	var target = deathblow_target
	while target:
		if target.has_method("deathblow"):
			target.deathblow()
			break
		elif target.has_method("die"):
			target.die()
			break
		target = target.get_parent()

	deathblow_target = null
	print("💥 Executed deathblow!")
	is_performing_deathblow = false







func _on_parry_detector_area_exited(area):
	print("EXITED:", area.name, "| in parryable group?", area.is_in_group("parryable"))

	if not area.is_in_group("parryable"):
		return

	var target = area

	# 🔍 Climb to owner or parent if needed
	if !"is_parryable" in area:
		if area.get_owner() and "is_parryable" in area.get_owner():
			target = area.get_owner()
		elif area.get_parent() and "is_parryable" in area.get_parent():
			target = area.get_parent()

	var value = target.get("is_parryable") if "is_parryable" in target else false
	print("🔍 Parry check:", target.name, "| is_parryable:", value)

	if value:
		if area in pending_parry_areas:
			pending_parry_areas.erase(area)
			print("✅ Removing from pending areas:", area.name)
	else:
		print("❌ Not parryable:", area.name)
	pass # Replace with function body.
