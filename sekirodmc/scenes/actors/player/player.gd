extends CharacterBody2D

@export var MAX_HEALTH = 50
@export var MAX_MANA = 50
@export var MAX_STAMINA = 50

@onready var health = MAX_HEALTH
@onready var mana = MAX_MANA
@onready var stamina = MAX_STAMINA

var stamina_run_decrement = 0.5
var stamina_block_decrement = 0.75
var stamina_parry_decrement = 5

var mana_charge_attack_value = 10
var mana_charge_attack_decrement = 10
var mana_recovery_rate = 0.005
var stamina_recovery_rate = 0.2

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
@onready var player_hud = $CanvasLayer/PlayerHUD

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
	POGO_JUMPING
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
	POGO_JUMPING: "POGO_JUMPING"
}

const RUN_SPEED = 350.0
const SPRINT_SPEED = 500.0
const DECELERATION_SPEED = 1600
const DASH_SPEED = 2000
const JUMP_VELOCITY = -800.0
const WALL_JUMP_VELOCITY = Vector2(1000, -800)
const POGO_JUMP_VELOCITY = -600
const MAX_SLASH_VELOCITY = 800
const MIN_COMBO_TIME = 0
const MAX_COMBO_TIME = 3
const GRAVITY = 1300
const MAX_CHARGE_MOVEMENT_SPEED = 1100
const MIN_CHARGE_MOVEMENT_SPEED = 400
const CHARGE_MOVEMENT_INCR = 5
const MAX_JUMPS = 2
const WALL_STICK_FORCE = 20

const ATTACK_MOVEMENT_MAX_SPEED = 1
var direction = 0
var last_direction = 0
var move_speed = 300
var sprint_time = 0
var sprint_activation_time = 2
var combo_time = 0
var charge_movement_speed = 400
var jump_count = 0

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

#KNOCKBACK
@export var knockback_force := 300.0
@export var knockback_duration := 0.2
var knockback_timer := 0.0
var is_knockback := false
var knockback_velocity := Vector2.ZERO

var closest_angle = 0
var slash_velocity = 0
var slash_decrement_percentage = 0.6
func _ready():
	init()

func init():
	anim_tree.active = true
	player_hud.set_max_health(MAX_HEALTH)
	player_hud.set_max_mana(MAX_MANA)
	player_hud.set_max_stamina(MAX_STAMINA)
	
	pass

func _process(delta):
	mana = move_toward(mana, MAX_MANA, mana_recovery_rate)
	stamina = move_toward(stamina, MAX_STAMINA, stamina_recovery_rate)
	player_hud.set_stamina(stamina)
	player_hud.set_mana(mana)
	
	pass

func _physics_process(delta):
	handle_knockback(delta)
	handle_movement(delta)
	handle_attack()
	handle_state_animations()
	handle_block()
	handle_dash()
	handle_wall_mechanics()
	handle_fall_through()
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
		reset_jump_count = false
		pass
	
	anim_tree.set("parameters/conditions/on_floor",is_on_floor())
	pass

func handle_jump():
	if stop_process: return
	
	# Handle variations in jump height
	if Input.is_action_just_released("jump") or is_on_ceiling():
		if velocity.y < 0: velocity.y *= 0.6
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
		await get_tree().process_frame
		set_state(JUMP)
	pass

func handle_run(delta):
	if stop_process: return
	direction = Input.get_axis("move_left", "move_right")
	
	if [ATTACK_1, ATTACK_2, ATTACK_3].has(state): return

	if direction:
		last_direction = direction
		if !can_move: return
		sprint_time += delta
		velocity.x = direction * move_speed
		handle_sprite_flip(direction)
		reduce_stamina(stamina_run_decrement)
	else:
		sprint_time = 0
		velocity.x = move_toward(velocity.x, 0, DECELERATION_SPEED * delta)
		if is_on_floor(): set_state(IDLE)
	
	if !is_on_floor(): return
	if direction: 
		handle_sprint()
	else:
		set_state(IDLE)
	pass

func handle_sprint():
	if stop_process: return
	if is_on_wall(): return
	
	if is_on_floor():
		if sprint_time > sprint_activation_time:
			set_state(SPRINT)
			move_speed = SPRINT_SPEED
		else:
			set_state(RUN)
			move_speed = RUN_SPEED
	pass

func handle_attack():
	if stop_process: return
	if is_on_wall_only(): return
	
	if Input.is_action_just_pressed("attack_1"):
		set_movement_speed_on_attack()
		damage = PRIMARY_ATT_DMG
		
		if is_pogo_jumping and !is_on_floor():
			return
		if has_parriable_enemies(): 
			damage = DEATHBLOW_DMG
			await handle_deathblow()
			return
		
		if !is_on_floor():
			handle_directional_attack()
			pass
		
		attack()
		
		combo_timer.start()
		combo_time = clamp(combo_time + 1, MIN_COMBO_TIME, MAX_COMBO_TIME)
		
		if combo_time == MAX_COMBO_TIME:
			combo_time = MIN_COMBO_TIME
	
	if mana > mana_charge_attack_decrement:
		if Input.is_action_pressed("attack_2"):
			if can_use_charge_attack:
				charge_movement_speed = clamp(charge_movement_speed + CHARGE_MOVEMENT_INCR, MIN_CHARGE_MOVEMENT_SPEED, MAX_CHARGE_MOVEMENT_SPEED)
			velocity.x = 0
			
		if Input.is_action_just_pressed("attack_2") and can_use_charge_attack:
			state_machine.travel("charge")
			charge_movement_speed = MIN_CHARGE_MOVEMENT_SPEED
			is_charge_attacking = true

		if Input.is_action_just_released("attack_2") and can_use_charge_attack and is_charge_attacking:
			state_machine.travel("charge_attack")
			handle_charge_attack()
			set_state(IDLE)
			damage = SECONDARY_ATT_DMG
			
			charge_cooldown_timer.start()
			can_use_charge_attack = false
			is_charge_attacking = false
			reduce_mana(mana_charge_attack_decrement)
			pass

func handle_charge_attack():
	if !is_on_floor(): return
	velocity.x += charge_movement_speed * last_direction
	pass

func handle_dash():
	if is_on_wall(): return

	if Input.is_action_just_pressed("dash"):
		velocity.x = DASH_SPEED * last_direction
		velocity.y = 0
		
		set_state(DASH)
		dash_timer.start()
		state_machine.travel("dash")
		var dash_anim = "dash" if is_on_floor() else "air_dash"
		anim_tree.set("parameters/dash/Transition/transition_request", dash_anim)
		stop_process = true
		hurt_area.monitoring = false
		pass
	
	pass

func handle_wall_mechanics():
	# WALL SLIDE
	anim_tree.set("parameters/conditions/is_on_wall", !is_on_wall_only())
	if is_on_wall_only():
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
	if Input.is_action_just_pressed("fall_through"):
		player_collision_shape.disabled = true
		set_state(JUMP)
		state_machine.travel("Jump")
		reset_jump_count = true  
		await get_tree().create_timer(0.05).timeout
		player_collision_shape.disabled = false
		pass
	pass

func handle_deathblow():
	set_physics_process(false)
	for enemy in GameManager.parriable_enemies:
		if enemy == null: return
		
		state_machine.travel("deathblow")
		var direction = sign(enemy.global_position - global_position)
		handle_sprite_flip(direction.x)
		var offset = Vector2(0 * direction.x, -50)
		global_position = enemy.global_position + offset
		velocity = Vector2.ZERO
		await get_tree().create_timer(0.2).timeout
	
	GameManager.parriable_enemies = []
	set_physics_process(true)
	velocity = Vector2.ZERO
	pass

func has_parriable_enemies():
	var enemies = GameManager.parriable_enemies
	return enemies.size() > 0
	pass

func set_movement_speed_on_attack():
	velocity.x = velocity.x * 0.3
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

func handle_sprite_flip(dir: int):
	sprite.flip_h = dir < 0
	areas.scale.x = dir
	pass

func handle_block():
	if is_on_wall_only(): return
	
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
		is_blocking = true
		can_parry = true
		anim_tree.set("parameters/conditions/blocking", !is_blocking)
		stop_movement()
		set_state(CAN_PARRY)
		
		parry_timer.start()
	if Input.is_action_just_released("block"):
		is_blocking = false
		stop_process = false
		anim_tree.set("parameters/conditions/blocking", !is_blocking)
		reset_movement()

func update_state_label(_state: int):
	var text = str(state_label[_state])
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
				state_machine.travel("block_hit")
				set_state(BLOCK_HIT)
				stop_process = false
				area.queue_free()
			CAN_PARRY:
				state_machine.travel("parry")
				set_state(PARRY)
				stop_process = false
				area.reflect()
				GameManager.emit_signal("shake_camera", 0.2, 4.0)
				if area.sender and area.sender.has_method("handle_parry"):
					area.sender.handle_parry()
				reduce_stamina(stamina_parry_decrement)
		pass
	pass

func handle_take_damage(area):
	var damage = area.damage
	take_damage(damage)
	apply_knockback(area.global_position)
	GameManager.emit_signal("shake_camera",0.2,8.0)
	area.queue_free()
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
		move_and_slide()
	pass

func take_damage(damage):
	health -= damage
	player_hud.set_health(health)
	if health <= 0:
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

func reduce_health(value):
	health = clamp(health - value, 0, MAX_HEALTH)
	pass

func handle_recover():
	if Input.is_action_just_pressed("recover") and mana == MAX_MANA:
		health = MAX_HEALTH
		player_hud.set_max_health(MAX_HEALTH)
		reduce_mana(MAX_MANA)
		pass
	
	pass

func handle_directional_attack():
	velocity = get_slash_velocity()
	set_player_direction()
	slash_velocity *= slash_decrement_percentage
	pass

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
	area.get_parent().get_parent().take_damage(global_position, damage)
	if is_pogo_jumping and !is_on_floor():
		handle_mini_jump()
		set_state(POGO_JUMPING)
	pass # Replace with function body.


func _on_pogo_area_area_entered(area):
	is_pogo_jumping = true
	jump_count = 1
	pass # Replace with function body.


func _on_pogo_area_area_exited(area):
	is_pogo_jumping = false
	pass # Replace with function body.
