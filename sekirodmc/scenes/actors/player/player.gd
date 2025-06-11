extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var anim_tree = $AnimationTree
@onready var state: int = IDLE

enum {
	IDLE,
	RUN,
	SPRINT,
	JUMP
}

var state_label = {
	IDLE: "IDLE",
	RUN: "RUN",
	SPRINT: "SPRINT",
	JUMP: "JUMP"
}

const RUN_SPEED = 300.0
const SPRINT_SPEED = 600.0
const JUMP_VELOCITY = -400.0

var direction = 0
var move_speed = 300

func _ready():
	anim_tree.active = true

func _physics_process(delta):
	handle_movement(delta)
	handle_attack()
	handle_state_animations()
	move_and_slide()

func handle_movement(delta):
	handle_gravity(delta)
	handle_jump()
	handle_run()
	pass

func handle_state_animations():
	match state:
		IDLE:
			anim_tree.set("parameters/Movement/Transition/transition_request", "idle")
			#anim_tree.set("parameters/Movement/Idle Blend/blend_amount", 0)
			#anim_tree.set("parameters/Movement/Run Blend/blend_amount", 0)
			pass
		RUN:
			anim_tree.set("parameters/Movement/Transition/transition_request", "run")
			#anim_tree.set("parameters/Movement/Idle Blend/blend_amount", 1)
			#anim_tree.set("parameters/Movement/Run Blend/blend_amount", 0)
			pass
		SPRINT:
			anim_tree.set("parameters/Movement/Transition/transition_request", "sprint")
			#anim_tree.set("parameters/Movement/Idle Blend/blend_amount", 1)
			#anim_tree.set("parameters/Movement/Run Blend/blend_amount", 1)
		JUMP:
			pass
	
	pass

func handle_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	pass

func handle_jump():
	if !is_on_floor(): return

	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		await get_tree().process_frame
		set_state(JUMP)
	pass

func handle_run():
	direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * move_speed
		handle_sprite_flip(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
	
	if !is_on_floor(): return
	
	if direction: 
		handle_sprint()
	else:
		set_state(IDLE)
	pass

func handle_sprint():
	if is_on_floor():
		if Input.is_action_pressed("sprint"):
			set_state(SPRINT)
			move_speed  = SPRINT_SPEED
		else:
			set_state(RUN)
			move_speed = RUN_SPEED
	pass

func handle_attack():
	if Input.is_action_just_pressed("attack"):
		print("yes")
		anim_tree.set("parameters/Movement/OneShot 2/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		pass

func handle_sprite_flip(dir: int):
	sprite.flip_h = dir < 0
	pass

func update_state_label(_state: int):
	$DebugLabel.text = str(state_label[_state])
	pass

func set_state(_state: int):
	state = _state
	update_state_label(state)
	pass
