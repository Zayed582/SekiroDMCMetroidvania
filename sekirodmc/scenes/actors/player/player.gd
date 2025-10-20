extends CharacterBody2D

@export var MAX_HEALTH = 6
@export var MAX_MANA = 100
@export var MAX_STAMINA = 50

@export_subgroup("Berserk Level")
@export var dull_berserk_level: int = 1
@export var cool_berserk_level: int = 3
@export var stylish_berserk_level: int = 5
@export var ssick_berserk_level: int = 8
@export var smokin_style_berserk_level: int = 2#11

@export_subgroup("Berserk Level Durations")
@export var cool_berserk_seconds_limit: float = 10
@export var stylish_berserk_seconds_limit: float = 10
@export var ssick_berserk_seconds_limit: float = 15
@export var smokin_berserk_seconds_limit: float = 15

@onready var health = MAX_HEALTH
@onready var mana = MAX_MANA
@onready var stamina = MAX_STAMINA
@onready var last_mana_value = mana
@onready var mana_progress = mana

#This is for the recovery mechanic, to calculate the health charge from the base
@onready var mana_base_value = mana

var stamina_run_decrement = 0.4
var stamina_block_decrement = 0.75
var stamina_parry_decrement = 5

var mana_progress_decrement = 0.65
var mana_charge_attack_value = 20
var mana_charge_attack_decrement = 20
var mana_recovery_rate = 0.005
var stamina_recovery_rate = 0.2

var mana_health_charge = 30
var health_increment_value = 0

var current_berserker_level: int = 0
var can_track_berserker_level: bool = true

@onready var sprite = $Sprite2D
@onready var anim_tree = $AnimationTree
@onready var state: int = IDLE
@onready var state_machine = $AnimationTree["parameters/playback"]  
@onready var combo_timer = $Timers/ComboTimer
@onready var parry_timer = $Timers/ParryTimer
@onready var areas = $Areas
@onready var player_collision_shape = $CollisionShape2D
@onready var charge_cooldown_timer = $Timers/ChargeCooldownTimer
@onready var dash_timer = $Timers/DashTimer
@onready var hurt_area = $Areas/HurtArea
@onready var wall_jump_cooldown_timer = $Timers/WallJumpCooldownTimer
@onready var hit_area = $Areas/HitArea
@onready var pojo_area_detector = $Areas/PogoArea
@onready var charge_attack_timer = $Timers/ChargeAttackTimer
@onready var fall_through_raycast = $Areas/FallthroughRayCast
@onready var berserk_reset_timer = $Timers/BerserkResetTimer
@onready var berserk_mode_timer = $Timers/BerserkModeTimer
@onready var berserk_animation_timer = $Timers/BerserkAnimationTimer
@onready var ledge_climb_timer: Timer = $Timers/LedgeClimbTimer
@onready var ledge_climb_verifier_area: Area2D = $Areas/LedgeClimbing/LedgeClimbVerifierArea
@onready var shine_spark_timer: Timer = $Timers/ShineSparkTimer
@onready var shine_spark_cpu_particles_2d: CPUParticles2D = $ShineSparkCPUParticles2D

@onready var berserk_label_scene = preload("res://scenes/components/particles/berserk_label/berserk_label.tscn")
@onready var berserk_sprite_scene = preload("res://scenes/components/particles/berserk_sprite/berserk_sprite.tscn")

enum {
	IDLE,
	RUN,
	SPRINT,
	JUMP,
	ATTACK_1,
	ATTACK_2,
	ATTACK_3,
	PARRY,
	BLOCK,
	BLOCK_HIT,
	CAN_PARRY,
	HURT,
	DEAD,
	CHARGE_ATTACK,
	DASH,
	WALL_CLING,
	WALL_SLIDE,
	POGO_JUMPING,
	DIRECTIONAL_ATTACK,
	RECOVER_HEALTH
}

var state_label = {
	IDLE: "IDLE",
	RUN: "RUN",
	SPRINT: "SPRINT",
	JUMP: "JUMP",
	ATTACK_1: "ATTACK",
	ATTACK_2: "ATTACK 2",
	ATTACK_3: "ATTACK 3",
	PARRY: "PARRY",
	BLOCK: "BLOCK",
	BLOCK_HIT: "BLOCK_HIT",
	CAN_PARRY: "CAN_PARRY",
	HURT: "HURT",
	DEAD: "DEAD",
	CHARGE_ATTACK: "CHARGE_ATTACK",
	DASH: "DASH",
	WALL_CLING: "WALL_CLING",
	WALL_SLIDE: "WALL_SLIDE",
	POGO_JUMPING: "POGO_JUMPING",
	DIRECTIONAL_ATTACK: "DIRECTIONAL ATTACK",
	RECOVER_HEALTH: "RECOVER_HEALTH"
}



const RUN_SPEED = 450.0
const SPRINT_SPEED = 700.0
const ACCELERATION_SPEED = 2000
const DECELERATION_SPEED = 2000
const DASH_SPEED = 2000
const JUMP_VELOCITY = -1000.0
const WALL_JUMP_VELOCITY = Vector2(1000, -800)
const POGO_JUMP_VELOCITY = -600
const MAX_SLASH_VELOCITY = 1000
const MIN_COMBO_TIME = 0
const MAX_COMBO_TIME = 3
const GRAVITY = 1800
const MAX_CHARGE_MOVEMENT_SPEED = 1100
const MIN_CHARGE_MOVEMENT_SPEED = 400
const CHARGE_MOVEMENT_INCR = 5

# UNLOCK DOUBLE JUMP, SET MAX_JUMPS = 2
const MAX_JUMPS = 1
const WALL_STICK_FORCE = 20
const MAX_DIRECTIONAL_ATTACKS = 1

const ATTACK_MOVEMENT_MAX_SPEED = 1
var direction = 1.0
var move_input = 1
var last_direction = 1
var move_speed = 300
var combo_time = 0
var charge_movement_speed = 400
var jump_count = 0
var directional_attack_count = 0
var direction_decay = 0.5

#DAMAGE
var damage = 1
const PRIMARY_ATT_DMG = 1
const SECONDARY_ATT_DMG = 2
const DEATHBLOW_DMG = 100000

var is_blocking = false
var stop_process = false
var can_move = true
var can_parry = false
var jumped = false
var can_use_charge_attack = true
var is_charge_attacking = false
var is_on_wall_bool = false
var reset_jump_count = false
var is_pogo_jumping = false
var can_charge_attack = false
var is_recovering_mana = false
var is_attacking_enemy = false
var is_death_blowing = false
var berserk_mode_activated = false
var is_climbing_ledge: bool = false
var can_cancel_ledge_climbing: bool = false
var can_auto_run: bool = false
var is_shine_spark: bool = false
var waiting_to_shine_spark: bool = false

#KNOCKBACK
@export var knockback_force := 300.0
@export var knockback_duration := 0.2

var knockback_timer := 0.0
var is_knockback := false
var knockback_velocity := Vector2.ZERO

#DIRECTIONAL ATTACK
var closest_angle = 0
var slash_velocity = 0
var slash_decrement_percentage = 0.6

#Sounds
@onready var attack_sound = $Sounds/AttackPlayer
@onready var charged_attack_player = $Sounds/ChargeAttackPlayer
@onready var walk_1 = $Sounds/Walk1
@onready var death_sound = $Sounds/DeathPlayer
@onready var parry_sound = $Sounds/ParryPlayer
@onready var block_sound = $Sounds/BlockPlayer
@onready var deathblow_sound = $Sounds/DeathBlowPlayer

#WALK SOUND
var step_timer := 0.0
var step_interval := 0.3

#ABILITIES
var unlocked_abilities = [
	IDLE,
	RUN,
	JUMP,
	ATTACK_1,
	ATTACK_2,
	ATTACK_3,
	SPRINT,
	CAN_PARRY,
	BLOCK,
]

#ONEWAY
var one_way_collision_layer = 4

# SOUNDS
var parry_sounds = [
	"res://sounds/parry_sounds/Parry1.mp3",
	"res://sounds/parry_sounds/Parry2.mp3",
	"res://sounds/parry_sounds/Parry3.mp3",
	"res://sounds/parry_sounds/Parry4.mp3",
	"res://sounds/parry_sounds/Parry5.mp3",
	"res://sounds/parry_sounds/Parry6.mp3",
	"res://sounds/parry_sounds/Parry7.mp3",
	"res://sounds/parry_sounds/Parry8.mp3",
	"res://sounds/parry_sounds/Parry9.mp3"
]

var attack_empty_sounds = [
	"res://sounds/attack_sounds/SwordSlash1.mp3",
]

var attack_full_sounds = [
	"res://sounds/attack_sounds/SwordSlash3.mp3"
]

var final_attack_sounds = [
	"res://sounds/attack_sounds/SwordSlash4.mp3"
]

var final_attack_empty_sounds = [
	"res://sounds/attack_sounds/SwordSlash2.mp3"
]

#BERSERK MODE
var berserk_mode = 0
var full_berserk_mode = 5
var berserk_value = 1

func _ready():
	init()
	randomize()

func init():
	anim_tree.active = true
	full_berserk_mode = smokin_style_berserk_level
	await get_tree().process_frame
	GameManager.emit_signal("set_max_health", MAX_HEALTH)
	GameManager.emit_signal("set_max_mana", MAX_MANA)
	GameManager.emit_signal("set_max_stamina", MAX_STAMINA)
	pass

func _process(delta):
	mana = move_toward(mana, MAX_MANA, mana_recovery_rate)
	stamina = move_toward(stamina, MAX_STAMINA, stamina_recovery_rate)
	GameManager.emit_signal("set_stamina", stamina)
	GameManager.emit_signal("set_mana", mana)
	
	pass

func _physics_process(delta):
	handle_knockback(delta)
	handle_movement(delta)
	handle_auto_run(delta)
	handle_shine_spark(delta)
	handle_attack()
	handle_state_animations()
	handle_block()
	handle_dash()
	handle_wall_mechanics()
	#handle_fall_through()
	handle_recover()
	set_closest_angle()
	move_and_slide()

func handle_movement(delta):
	handle_gravity(delta)
	handle_jump()
	handle_run(delta)
	pass

func handle_state_animations():
	if is_on_wall(): return
	
	anim_tree.set("parameters/Movement/FallTransition/blend_amount", 0 if is_on_floor() else 1)
	match state:
		IDLE:
			anim_tree.set("parameters/Movement/Transition/transition_request", "idle")
		RUN:
			anim_tree.set("parameters/Movement/Transition/transition_request", "run")
		SPRINT:
			anim_tree.set("parameters/Movement/Transition/transition_request", "sprint")
	pass

func handle_gravity(delta):
	#handle directional attack
	if is_climbing_ledge:
		velocity.y = 0
		return

	
	if is_on_floor() and slash_velocity != MAX_SLASH_VELOCITY:
		slash_velocity = MAX_SLASH_VELOCITY
		pass
	
	if not is_on_floor() and state != DASH:
		velocity.y += GRAVITY * delta
		anim_tree.set("parameters/Jump/blend_position", sign(velocity.y))

	#Reset animation to idle
	if is_on_floor() and !is_on_wall() and reset_jump_count:
		
		if !is_charge_attacking:
			set_state(IDLE)
			state_machine.travel("Movement")
		jump_count = 0
		directional_attack_count = 0
		reset_jump_count = false
		pass
	
	anim_tree.set("parameters/conditions/on_floor",is_on_floor())
	pass

func handle_jump():
	if stop_process: return
	if is_shine_spark or waiting_to_shine_spark: return
	if is_climbing_ledge == true and can_cancel_ledge_climbing == false:
		return
	# Handle variations in jump height
	if Input.is_action_just_released("jump") or is_on_ceiling():
		if velocity.y < 0: velocity.y =0
		pass
	
	if jump_count >= MAX_JUMPS: return

	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		if jump_count == 1:
			state_machine.travel("backflip")
		else: state_machine.travel("Jump")
		anim_tree.set("parameters/Jump/blend_position", sign(velocity.y))
		jump_count += 1
		reset_jump_count = true
		disable_ledge_climb()
		await get_tree().process_frame
		set_state(JUMP)
	pass

func handle_auto_run(delta):
	if stop_process: return
	if is_shine_spark: return
	if is_shine_spark or waiting_to_shine_spark: return
	if can_auto_run:
		if berserk_value == smokin_style_berserk_level:
			if stop_process: return
			if !can_move: return
			if last_direction != 0:
				velocity.x = move_toward(velocity.x, last_direction * move_speed, ACCELERATION_SPEED * 10 * delta)
				handle_sprite_flip(last_direction)
				step_timer -= delta
				set_state(SPRINT)
				move_speed = SPRINT_SPEED
		else:
			set_state(RUN)
			move_speed = RUN_SPEED
			step_timer = 0

##currently at 6hours 50 minutes
func handle_shine_spark(delta):
	if stop_process: return
	if not waiting_to_shine_spark:
		if is_on_floor():
			if Input.is_action_just_pressed("shinespark"):
				waiting_to_shine_spark = true
				shine_spark_timer.start()
				shine_spark_cpu_particles_2d.emitting = true
	else:
		if Input.is_action_just_released("shinespark") and waiting_to_shine_spark:
			if shine_spark_timer.time_left != 0:
				shine_spark_timer.stop()
			waiting_to_shine_spark = false
			if shine_spark_cpu_particles_2d.emitting:
				shine_spark_cpu_particles_2d.emitting = false
			if is_shine_spark:
				is_shine_spark = false
		if is_shine_spark:
			velocity.y -= ACCELERATION_SPEED * 2 * delta
			if shine_spark_cpu_particles_2d.emitting:
				shine_spark_cpu_particles_2d.emitting = false

func handle_run(delta):
	if stop_process: return
	if is_shine_spark: return
	if is_shine_spark or waiting_to_shine_spark: return
	if is_climbing_ledge: 
		velocity.x += last_direction * ACCELERATION_SPEED * 0.8 * delta
		velocity.y -= ACCELERATION_SPEED * 10 * delta
		return
	move_input = Input.get_axis("move_left", "move_right")
	direction = lerp(direction, move_input, direction_decay)
	if !move_input and abs(direction) < 0.1: direction = 0.0
	
	if [ATTACK_1, ATTACK_2, ATTACK_3, CHARGE_ATTACK].has(state): return
	
	if move_input:
		last_direction = move_input
		if !can_move: return
		velocity.x = move_toward(velocity.x, direction * move_speed, ACCELERATION_SPEED * delta)
		if move_input: handle_sprite_flip(move_input)
		else: handle_sprite_flip(move_input)
		reduce_stamina(stamina_run_decrement)
		step_timer -= delta
		#handle_run_sound()
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION_SPEED * delta)
		step_timer = 0.0
		if is_on_floor(): set_state(IDLE)
	
	if !is_on_floor(): return
	if velocity.x != 0: 
		handle_sprint()
	else:
		set_state(IDLE)
	pass

func handle_run_sound():
	if is_on_floor():
		if step_timer <= 0.0:
			walk_1.pitch_scale = randf_range(0.85, 1.15)
			walk_1.play()
			step_timer = step_interval
	pass

func handle_sprint():
	if stop_process: return
	if is_on_wall(): return

	if is_on_floor():
		if Input.is_action_pressed("sprint") and has_unlocked_ability(SPRINT) and stamina > MAX_STAMINA * 0.1:
			#set_state(SPRINT)
			#move_speed = SPRINT_SPEED
			pass
			#reduce_stamina(stamina_run_decrement)
		else:
			set_state(RUN)
			move_speed = RUN_SPEED
	pass

func handle_attack():
	if stop_process: return
	if is_on_wall_only(): return
	if is_shine_spark or waiting_to_shine_spark: return
	
	anim_tree.set("parameters/conditions/can_charge_attack", can_charge_attack and mana > mana_charge_attack_decrement)
	
	if Input.is_action_just_pressed("attack_1"):
		can_charge_attack = false
		charge_movement_speed = MIN_CHARGE_MOVEMENT_SPEED
		
		set_movement_speed_on_attack()
		damage = PRIMARY_ATT_DMG * berserk_value
		
		#if is_pogo_jumping and !is_on_floor():
			#return
		if has_parriable_enemies(): 
			damage = DEATHBLOW_DMG * berserk_value
			await handle_deathblow()
			return
		
		handle_attack_midair()
		
		if !is_on_floor() and directional_attack_count < MAX_DIRECTIONAL_ATTACKS and has_unlocked_ability(DIRECTIONAL_ATTACK):
			handle_directional_attack()
			return
		
		if mana > mana_charge_attack_decrement and can_use_charge_attack and has_unlocked_ability(CHARGE_ATTACK):
			charge_attack_timer.start()
		
		attack()
		
		combo_timer.start()
		combo_time = clamp(combo_time + 1, MIN_COMBO_TIME, MAX_COMBO_TIME)
		
		if combo_time == MAX_COMBO_TIME:
			combo_time = MIN_COMBO_TIME
	
	if mana > mana_charge_attack_decrement and has_unlocked_ability(CHARGE_ATTACK):
		if Input.is_action_pressed("attack_1"):
			if can_use_charge_attack and can_charge_attack:
				state_machine.travel("charge")
				charge_movement_speed = clamp(charge_movement_speed + CHARGE_MOVEMENT_INCR, MIN_CHARGE_MOVEMENT_SPEED, MAX_CHARGE_MOVEMENT_SPEED)
				velocity.x = 0
	
	if Input.is_action_just_released("attack_1") and has_unlocked_ability(CHARGE_ATTACK):
		charge_attack_timer.stop()
		if can_charge_attack and mana > mana_charge_attack_decrement:
			handle_charge_hitstop()
			state_machine.travel("charge_attack")
			handle_charge_attack()
			set_state(IDLE)
			damage = SECONDARY_ATT_DMG * berserk_value
			
			charge_cooldown_timer.start()
			can_use_charge_attack = false
			reduce_mana(mana_charge_attack_decrement)
			
		can_charge_attack = false
		pass

func handle_charge_attack():
	if !is_on_floor(): return
	velocity.x = charge_movement_speed * last_direction
	pass

func handle_charge_hitstop():
	GameManager.emit_signal("hitstop", 0.2)
	pass

func handle_dash():
	if !has_unlocked_ability(DASH): return
	if is_on_wall(): return
	if is_shine_spark or waiting_to_shine_spark: return

	if Input.is_action_just_pressed("dash"):
		velocity.x = DASH_SPEED * last_direction
		velocity.y = 0
		
		set_state(DASH)
		dash_timer.start()
		state_machine.start("dash")
		var dash_anim = "dash" if is_on_floor() else "air_dash"
		anim_tree.set("parameters/dash/Transition/transition_request", dash_anim)
		stop_process = true
		hurt_area.monitoring = false
		pass
	
	pass

func handle_wall_mechanics():
	# WALL SLIDE
	if !has_unlocked_ability(WALL_CLING): return
	
	anim_tree.set("parameters/conditions/is_on_wall", !is_on_wall_only())
	if is_on_wall_only():
		print("walloing")
		velocity.x += WALL_STICK_FORCE * last_direction
		if Input.is_action_pressed("wall_cling"):
			velocity.y = 0
			set_state(WALL_CLING)
			pass
		else:
			velocity.y *= 0.9
			set_state(WALL_SLIDE)
		pass
		
		if !is_on_wall_bool:
			state_machine.travel("wall_slide")
			is_on_wall_bool = true
			
	else:
		if is_on_wall_bool:
			is_on_wall_bool = false
	
	if jump_count > MAX_JUMPS: return
	
	# WALL JUMP
	if Input.is_action_just_pressed("jump") and is_on_wall_only():
		handle_sprite_flip(-last_direction)
		var new_velocity_x = WALL_JUMP_VELOCITY.x * -last_direction
		last_direction = -last_direction
		velocity.y = WALL_JUMP_VELOCITY.y
		velocity.x += new_velocity_x
		state_machine.travel("Jump")
		jump_count = 1
		reset_jump_count = true
		can_move = false
		wall_jump_cooldown_timer.start()
		anim_tree.set("parameters/Jump/blend_position", sign(velocity.y))
		await get_tree().process_frame
		set_state(JUMP)
	
	pass

func handle_fall_through():
	if Input.is_action_just_pressed("fall_through") and fall_through_raycast.is_colliding():
		set_collision_layer_value(one_way_collision_layer, false)
		set_collision_mask_value(one_way_collision_layer, false)
		set_state(JUMP)
		state_machine.travel("Jump")
		reset_jump_count = true  
		await get_tree().create_timer(0.2).timeout
		set_collision_layer_value(one_way_collision_layer, true)
		set_collision_mask_value(one_way_collision_layer, true)
		pass
	pass

func handle_deathblow():
	set_physics_process(false)
	hurt_area.monitoring = false
	
	for enemy in GameManager.parriable_enemies:
		if enemy == null: return
		
		is_death_blowing = true
		enemy.silence_monitoring_node(false)
		state_machine.travel("deathblow")
		var direction = sign(enemy.global_position - global_position)
		handle_sprite_flip(direction.x)
		var offset = Vector2(5 * direction.x, -10)
		global_position = enemy.global_position + offset
		velocity = Vector2.ZERO
		deathblow_sound.pitch_scale = randf_range(0.8,1.2)
		deathblow_sound.play()
		await get_tree().create_timer(0.2).timeout
		is_death_blowing = false
	
	GameManager.parriable_enemies = []
	set_physics_process(true)
	
	hurt_area.monitoring = true
	velocity = Vector2.ZERO
	pass

func handle_attack_midair():
	if !is_on_floor() and !is_on_wall(): set_player_direction()
	
	pass

func has_parriable_enemies():
	var enemies = GameManager.parriable_enemies
	return enemies.size() > 0
	pass

func set_movement_speed_on_attack():
	velocity.x = velocity.x * 0.7
	velocity.x += last_direction * 50
	pass

func stop_movement():
	velocity.x = 0
	pass

func reset_movement():
	move_speed = RUN_SPEED
	pass

func attack():
	match combo_time:
		0: 
			#await get_tree().create_timer(0.2).timeout
			set_state(ATTACK_1)
			state_machine.travel("attack_1")
		1: 
			set_state(ATTACK_2)
			state_machine.travel("attack_2")
		2: 
			set_state(ATTACK_3)
			state_machine.travel("attack_3")
	
	pass

func handle_attack_exit():
	set_state(IDLE)
	pass

func handle_sprite_flip(dir):
	sprite.flip_h = dir < 0
	areas.scale.x = dir
	pass

func handle_block():
	if !has_unlocked_ability(BLOCK): return
	if is_on_wall_only(): return
	if is_shine_spark or waiting_to_shine_spark: return
	
	if is_blocking:
		reduce_stamina(stamina_block_decrement)
		if stamina < MAX_STAMINA * 0.05:
			is_blocking = false
			stop_process = false
			anim_tree.set("parameters/conditions/blocking", !is_blocking)
			reset_movement()
			pass
	
	if Input.is_action_just_pressed("block") and stamina > MAX_STAMINA * 0.2:
		state_machine.travel("block")
		stop_process = true
		if is_on_floor(): 
			velocity.x = 0
		is_blocking = true
		can_parry = true
		anim_tree.set("parameters/conditions/blocking", !is_blocking)
		#stop_movement()
		set_state(CAN_PARRY)
		
		parry_timer.start()
	if Input.is_action_just_released("block"):
		is_blocking = false
		stop_process = false
		anim_tree.set("parameters/conditions/blocking", !is_blocking)
		reset_movement()

func update_state_label(_state: int):
	var text = str(state_label[_state])
	_update_player_debug_state(text)
	pass

func set_state(_state: int):
	state = _state
	update_state_label(state)
	pass

func _update_player_debug_state(text):
	$DebugLabel.text = str(text)
	pass

func handle_projectile_block(area):
	if area.is_in_group("projectile"):
		match state:
			BLOCK:
				block_sound.pitch_scale = randf_range(0.8,1.2)
				block_sound.play()
				state_machine.travel("block_hit")
				set_state(BLOCK_HIT)
				stop_process = false
				area.queue_free()
			CAN_PARRY:
				hande_parry()
				stop_process = false
				area.reflect()
		pass
	pass

func handle_melee_block(area):
	match state:
		BLOCK:
			block_sound.pitch_scale = randf_range(0.8,1.2)
			block_sound.play()
			state_machine.travel("block_hit")
			set_state(BLOCK_HIT)
			apply_knockback(area.global_position)
			return true
		CAN_PARRY:
			hande_parry()
			if area.get_parent().has_method("take_damage"):
				area.get_parent().handle_parry()
			return true
	return false
	pass

func hande_parry():
	handle_berserk()
	play_random_sound(parry_sounds, parry_sound)
	state_machine.travel("parry")
	set_state(PARRY)
	GameManager.emit_signal("shake_camera", 0.2, 4.0)
	GameManager.emit_signal("hitstop", 0.2)
	increase_mana(10)
	reduce_stamina(stamina_parry_decrement)
	pass


func play_random_sound(sounds_arr: Array, sound_node: AudioStreamPlayer):
	var random_index = randi() % sounds_arr.size()
	var sound_path = sounds_arr[random_index]
	var sound = load(sound_path)
	sound_node.stream = sound
	sound_node.play()

func play_attack_sound():
	var sounds = attack_full_sounds if is_attacking_enemy else attack_empty_sounds
	play_random_sound(sounds, attack_sound)
	pass

func play_attack_final_attack_sound():
	var sounds = final_attack_sounds if is_attacking_enemy else final_attack_empty_sounds
	play_random_sound(sounds, attack_sound)
	pass

func handle_take_damage(area):
	if !area.is_in_group("projectile"):
		if handle_melee_block(area): return
	
	var damage = 0
	if area.get_parent().get("damage"):
		damage = area.get_parent().damage
	else:
		damage = area.damage
	
	#Restart charge cooldown
	can_use_charge_attack = false
	charge_cooldown_timer.start()
	reset_mana_progress()
	
	take_damage(damage)
	decrease_berserk_rank()
	apply_knockback(area.global_position)
	GameManager.emit_signal("shake_camera",0.2,8.0)
	GameManager.emit_signal("hitstop", 0.2)
	if area.is_in_group("projectile"): area.queue_free()
	GameManager.emit_signal("clear_parrys")
	pass

func apply_knockback(from_position: Vector2):
	var direction = (global_position - from_position).normalized()
	knockback_velocity = direction * knockback_force
	knockback_timer = knockback_duration
	is_knockback = true

func handle_knockback(delta):
	if is_knockback:
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_knockback = false
			knockback_velocity = Vector2.ZERO
		velocity = knockback_velocity
		floor_stop_on_slope = false
		move_and_slide()
	pass

func take_damage(damage):
	health -= damage
	GameManager.emit_signal("set_health", health)
	GameManager.emit_signal("add_flash_particle")
	is_climbing_ledge = false
	if health <= 0:
		death_sound.play()
		state_machine.travel("hurt")
		await get_tree().process_frame
		state_machine.travel("End")
		handle_death()
		await get_tree().create_timer(2).timeout
		GameManager.emit_signal("gameover")
		pass
	else:
		stop_process = true
		state_machine.travel("hurt")
		set_state(HURT)
		await get_tree().create_timer(0.2).timeout
		stop_process = false
		pass
	pass

func handle_death():
	set_process(false)
	set_physics_process(false)
	player_collision_shape.disabled = true
	
	for area in areas.get_children():
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
		pass
	
	set_state(DEAD)
	pass

func reduce_stamina(value):
	stamina = clamp(stamina - value, 0, MAX_STAMINA)
	pass

func reduce_mana(value):
	mana = clamp(mana - value, 0, MAX_MANA)
	pass

func reduce_mana_progress(value):
	mana_progress = clamp(mana_progress - value, 0, MAX_MANA)
	GameManager.emit_signal("set_mana_progress", mana_progress)
	pass

func increase_mana(value):
	mana = clamp(mana + value, 0, MAX_MANA)
	last_mana_value = mana
	mana_progress = mana
	mana_base_value = mana
	pass

func increase_health(value):
	health = clamp(health + value, 0, MAX_HEALTH)

func set_mana(value):
	mana = value
	mana_progress = value
	GameManager.emit_signal("set_mana_progress", mana_progress)
	GameManager.emit_signal("set_mana", mana)
	pass

func reset_mana_progress():
	var mana = stepped_from_base(mana_progress, mana_base_value, mana_health_charge)
	set_mana(mana)
	is_recovering_mana = false
	pass

func reduce_health(value):
	health = clamp(health - value, 0, MAX_HEALTH)
	pass

func handle_recover():
	if !has_unlocked_ability(RECOVER_HEALTH): return

	if Input.is_action_just_pressed("recover"):
		mana_progress = mana
		mana_base_value = mana
		reduce_mana(mana_health_charge)
		health_increment_value = 0
		is_recovering_mana = true
		pass
	
	if Input.is_action_pressed("recover") and is_recovering_mana:
		reduce_mana_progress(mana_progress_decrement)
		var mana = stepped_from_base(mana_progress, mana_base_value, mana_health_charge)
		if last_mana_value > mana:
			health_increment_value += 1
			last_mana_value = mana
			reduce_mana(mana_health_charge)
		pass
	
	if Input.is_action_just_released("recover") and is_recovering_mana:
		increase_health(health_increment_value)
		GameManager.emit_signal("set_health", health)
		reset_mana_progress()
	pass

func handle_directional_attack():
	directional_attack_count += 1
	velocity = get_slash_velocity()
	slash_velocity *= slash_decrement_percentage
	
	set_state(DIRECTIONAL_ATTACK)
	state_machine.travel("attack_1")
	pass

func disable_ledge_climb() -> void:
	if is_climbing_ledge:
		is_climbing_ledge = false
		can_cancel_ledge_climbing = false
		ledge_climb_timer.stop()

func _on_combo_timer_timeout():
	combo_time = clamp(combo_time - 1, MIN_COMBO_TIME, MAX_COMBO_TIME)
	if combo_time <= 0:
		combo_timer.stop()
	pass # Replace with function body.

func _on_block_area_area_entered(area):
	handle_projectile_block(area)
	pass # Replace with function body.

func _on_parry_timer_timeout():
	can_parry = false
	set_state(BLOCK)
	pass # Replace with function body.

func _on_hurt_area_area_entered(area):
	handle_take_damage(area)
	pass # Replace with function body.

func handle_mini_jump():
	velocity.y = POGO_JUMP_VELOCITY
	pass

func get_aim_direction() -> Vector2:
	var offset = Vector2(0,30)
	return get_global_mouse_position() - (global_position - offset)
	pass

func set_closest_angle():
	var aim_vector = get_aim_direction()
	var angle_deg = rad_to_deg(aim_vector.angle())
	angle_deg = fposmod(angle_deg + 360.0, 360.0)
	var allowed_angles = [0, 45, 90, 135, 180, 225, 270, 315]

	var _closest_angle = allowed_angles[0]
	var min_diff = abs(angle_deg - _closest_angle)
	for a in allowed_angles:
		var diff = abs(angle_deg - a)
		if diff < min_diff:
			_closest_angle = a
			min_diff = diff
	
	closest_angle = _closest_angle

func get_slash_velocity():
	var vel = Vector2.ZERO
	match closest_angle:
		0: vel = Vector2(1,0)
		45: vel = Vector2(1,1)
		90: vel = Vector2(0,1)
		135: vel = Vector2(-1,1)
		180: vel = Vector2(-1,0)
		225: vel = Vector2(-1,-1)
		270: vel = Vector2(0,-1)
		315: vel = Vector2(1,-1)
		
	
	return vel.normalized() * slash_velocity

func set_player_direction():
	var snapped_angle_rad = deg_to_rad(closest_angle)
	var snapped_direction = Vector2.from_angle(snapped_angle_rad).normalized()
	
	sprite.flip_h = snapped_direction.x < 0
	last_direction = snapped_direction.x
	pass

func stepped_from_base(current_value: float, base_value: float, step: float) -> float:
	var steps_down = floor((base_value - current_value) / step)
	return base_value - (steps_down * step)

func has_unlocked_ability(ability):
	return unlocked_abilities.has(ability)
	pass

func _on_charge_cooldown_timer_timeout():
	can_use_charge_attack = true
	pass # Replace with function body.

func _on_dash_timer_timeout():
	if is_on_wall_only(): 
		stop_process = false
		hurt_area.monitoring = true
		return

	stop_process = false
	set_state(IDLE)
	state_machine.travel("Movement")
	hurt_area.monitoring = true
	velocity.x = 0
	pass # Replace with function body.


func _on_wall_jump_cooldown_timer_timeout():
	can_move = true
	pass # Replace with function body.


func _on_hit_area_area_entered(area):
	if area.get_parent().has_method("take_damage"):
		if is_death_blowing:
			if GameManager.parriable_enemies.has(area.get_parent()):
				area.get_parent().take_damage(global_position, damage)
		else:
			area.get_parent().take_damage(global_position, damage)
	
	#GameManager.emit_signal("hitstop")
	#if is_pogo_jumping and !is_on_floor():
		#handle_mini_jump()
		#set_state(POGO_JUMPING)
	pass # Replace with function body.


func _on_pogo_area_area_entered(area):
	#is_pogo_jumping = true
	#jump_count = 1
	pass # Replace with function body.


func _on_pogo_area_area_exited(area):
	#is_pogo_jumping = false
	pass # Replace with function body.


func _on_charge_attack_timer_timeout():
	can_charge_attack = true
	set_state(CHARGE_ATTACK)
	pass # Replace with function body.


func _on_pre_hit_area_area_entered(area):
	is_attacking_enemy = true
	pass # Replace with function body.


func _on_pre_hit_area_area_exited(area):
	is_attacking_enemy = false
	pass # Replace with function body.

func activate_jump_boost(jump_boost):
	velocity.y = jump_boost
	set_state(JUMP)
	pass

func handle_berserk():
	if berserk_mode_activated: return
	
	berserk_mode = clamp(berserk_mode + 1, 0, full_berserk_mode)
	if berserk_mode == dull_berserk_level:
		add_berserk_label(1)
		berserk_reset_timer.wait_time = cool_berserk_seconds_limit
		berserk_reset_timer.start()
	elif berserk_mode == cool_berserk_level:
		berserk_reset_timer.wait_time = stylish_berserk_seconds_limit
		add_berserk_label(2)
		berserk_reset_timer.start()
	elif berserk_mode == stylish_berserk_level:
		berserk_reset_timer.wait_time = ssick_berserk_seconds_limit
		add_berserk_label(3)
		berserk_reset_timer.start()
	elif berserk_mode == ssick_berserk_level:
		berserk_reset_timer.wait_time = smokin_berserk_seconds_limit
		add_berserk_label(4)
		berserk_reset_timer.start()
	elif berserk_mode == smokin_style_berserk_level:
		add_berserk_label(5)
		berserk_mode_activated = true
		berserk_mode_timer.start()
		berserk_reset_timer.stop()
		berserk_animation_timer.start()
		berserk_value = 2
		can_auto_run = true
	
	#if berserk_mode == full_berserk_mode:
		#berserk_mode_activated = true
		#berserk_mode_timer.start()
		#berserk_reset_timer.stop()
		#berserk_animation_timer.start()
		#berserk_value = 2
	#pass

func decrease_berserk_rank():
	if can_auto_run:
		can_auto_run = false
	if berserk_mode == smokin_style_berserk_level:
		berserk_mode = ssick_berserk_level
		add_berserk_label(4)
		berserk_mode_activated = false
		berserk_value = 1
		reset_movement()
	elif berserk_mode == ssick_berserk_level:
		berserk_mode = stylish_berserk_level
		add_berserk_label(3)
		berserk_mode_activated = false
	elif berserk_mode == stylish_berserk_level:
		berserk_mode = cool_berserk_level
		add_berserk_label(2)
		berserk_mode_activated = false
	elif berserk_mode == cool_berserk_level:
		berserk_mode = dull_berserk_level
		add_berserk_label(1)
		berserk_mode_activated = false
	elif berserk_mode == dull_berserk_level:
		add_berserk_label(1)
		berserk_mode_activated = false

func add_berserk_label(id: int):
	var berserk_label = berserk_label_scene.instantiate()
	berserk_label.global_position = global_position + Vector2(0, -100)
	get_tree().current_scene.add_child(berserk_label)
	berserk_label.animate(id)#berserk_label.animate(berserk_mode)
	pass

func _on_beserk_reset_timer_timeout():
	berserk_mode = clamp(berserk_mode - 1, 0, full_berserk_mode)
	decrease_berserk_rank()
	if berserk_mode <= 0: berserk_reset_timer.stop()
	
	pass # Replace with function body.

func _on_berserk_mode_timer_timeout():
	berserk_mode_activated = false
	berserk_animation_timer.stop()
	berserk_mode = dull_berserk_level#a0
	berserk_value = 1
	decrease_berserk_rank()
	pass # Replace with function body.

func after_image():
	var berserk_sprite = berserk_sprite_scene.instantiate()
	get_tree().current_scene.get_node("Decorations").add_child(berserk_sprite)
	berserk_sprite.init(sprite)
	pass

func _on_berserk_animation_timer_timeout():
	after_image()
	pass # Replace with function body.

func _on_ledge_climb_area_body_entered(body: Node2D) -> void:
	var bodies = ledge_climb_verifier_area.get_overlapping_bodies()
	if bodies.size() == 0 and can_auto_run == false and velocity.y >= 0:
		is_climbing_ledge = true
		can_cancel_ledge_climbing = false
		state_machine.travel("ledge_climb")
		ledge_climb_timer.start()
		print("climbing")

func _on_ledge_climb_area_body_exited(body: Node2D) -> void:
	#disable_ledge_climb()
	print("exited")
	pass

func _on_ledge_climb_timer_timeout() -> void:
	can_cancel_ledge_climbing = true
	print("can cancel climb")
	jump_count = 0
	reset_jump_count = true

##CONTINUE WITH THE LEDGE CLIMB ANIMATION AND ACTIVATE THE ANIMATION TREE WHEN YOU ARE DONE


func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "ledge_climb":
		disable_ledge_climb()


func _on_shine_spark_timer_timeout() -> void:
	is_shine_spark = true
	shine_spark_cpu_particles_2d.emitting = false
