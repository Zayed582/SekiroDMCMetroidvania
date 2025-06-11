extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var anim_tree = $AnimationTree
@onready var state = IDLE

enum {
	IDLE,
	RUN,
	SPRINT,
	JUMP
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
			anim_tree.set("parameters/Movement/Idle Blend/blend_amount", 0)
			anim_tree.set("parameters/Movement/Run Blend/blend_amount", 0)
			pass
		RUN:
			anim_tree.set("parameters/Movement/Idle Blend/blend_amount", 1)
			anim_tree.set("parameters/Movement/Run Blend/blend_amount", 0)
			pass
		SPRINT:
			anim_tree.set("parameters/Movement/Idle Blend/blend_amount", 1)
			anim_tree.set("parameters/Movement/Run Blend/blend_amount", 1)
	
	pass

func handle_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	pass

func handle_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	pass

func handle_run():
	direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * move_speed
		handle_sprite_flip(direction)
		handle_sprint()
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		state = IDLE
	pass

func handle_sprint():
	if is_on_floor():
		if Input.is_action_pressed("sprint"):
			state = SPRINT
			move_speed  = SPRINT_SPEED
		else:
			state = RUN
			move_speed = RUN_SPEED
	pass

func handle_sprite_flip(dir):
	sprite.flip_h = dir < 0
	pass
