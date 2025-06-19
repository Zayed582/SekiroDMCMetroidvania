extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var anim_tree = $AnimationTree
@onready var state: int = IDLE
@onready var state_machine = $AnimationTree["parameters/playback"]  
@onready var combo_timer = $Timers/ComboTimer
@onready var parry_timer = $Timers/ParryTimer
@onready var areas = $Areas
@onready var player_collision_shape = $CollisionShape2D

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
	DEAD
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
	DEAD: "DEAD"
}

const RUN_SPEED = 350.0
const SPRINT_SPEED = 500.0
const DECELERATION_SPEED = 1600
const JUMP_VELOCITY = -800.0
const MIN_COMBO_TIME = 0
const MAX_COMBO_TIME = 3
const GRAVITY = 1300

const ATTACK_MOVEMENT_MAX_SPEED = 1
var direction = 0
var move_speed = 300
var sprint_time = 0
var sprint_activation_time = 2
var combo_time = 0
var health = 3


var is_blocking = false
var stop_process = false
var can_parry = false
var jumped = false

#KNOCKBACK
@export var knockback_force := 300.0
@export var knockback_duration := 0.2

var knockback_timer := 0.0
var is_knockback := false
var knockback_velocity := Vector2.ZERO

func _ready():
	anim_tree.active = true
	#TODO: REMOVE THIS
	GameManager.connect("update_player_debug_state", _update_player_debug_state)

func _physics_process(delta):
	handle_knockback(delta)
	handle_movement(delta)
	handle_attack()
	handle_state_animations()
	handle_block()
	move_and_slide()

func handle_movement(delta):
	handle_gravity(delta)
	handle_jump()
	handle_run(delta)
	pass

func handle_state_animations():
	match state:
		IDLE:
			anim_tree.set("parameters/Movement/Transition/transition_request", "idle")
		RUN:
			anim_tree.set("parameters/Movement/Transition/transition_request", "run")
		SPRINT:
			anim_tree.set("parameters/Movement/Transition/transition_request", "sprint")
	pass

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		anim_tree.set("parameters/Jump/blend_position", sign(velocity.y))

	#Reset animation to idle
	if is_on_floor() and state == JUMP:
		set_state(IDLE)
		state_machine.travel("Movement")
		pass
	
	anim_tree.set("parameters/conditions/on_floor",is_on_floor())
	pass

func handle_jump():
	if stop_process: return
	
	
	if Input.is_action_just_released("jump") or is_on_ceiling():
		if velocity.y < 0: velocity.y *= 0.6
		pass
	
	if !is_on_floor(): return

	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		state_machine.travel("Jump")
		anim_tree.set("parameters/Jump/blend_position", sign(velocity.y))
		await get_tree().process_frame
		set_state(JUMP)
	pass

func handle_run(delta):
	if stop_process: return
	direction = Input.get_axis("move_left", "move_right")
	
	if [ATTACK_1, ATTACK_2, ATTACK_3].has(state): return

	if direction:
		sprint_time += delta
		velocity.x = direction * move_speed
		handle_sprite_flip(direction)
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
	if Input.is_action_just_pressed("attack_1"):
		set_movement_speed_on_attack()
		attack()
		
		combo_timer.start()
		combo_time = clamp(combo_time + 1, MIN_COMBO_TIME, MAX_COMBO_TIME)
		
		if combo_time == MAX_COMBO_TIME:
			combo_time = MIN_COMBO_TIME
	
	if Input.is_action_just_pressed("attack_2"):
		combo_time = MAX_COMBO_TIME - 1
		set_movement_speed_on_attack()
		attack()
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
	if Input.is_action_just_pressed("block"):
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
	GameManager.emit_signal("update_player_debug_state", text)
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
		pass
	pass

func handle_take_damage(area):
	var damage = area.damage
	take_damage(damage)
	apply_knockback(area.global_position)
	GameManager.emit_signal("shake_camera",0.2,8.0)
	area.queue_free()
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
	return
	pass

func take_damage(damage):
	health -= damage
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
