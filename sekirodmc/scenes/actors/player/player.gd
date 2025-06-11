extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var anim_tree = $AnimationTree

const SPEED = 300.0
const JUMP_VELOCITY = -400.0


func _ready():
	anim_tree.active = true

func _physics_process(delta):
	handle_gravity(delta)
	handle_jump()
	handle_movement()

	move_and_slide()


func handle_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	pass

func handle_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	pass

func handle_movement():
	var direction = Input.get_axis("move_left", "move_right")
	handle_movement_anim_state(direction)
	
	if direction:
		velocity.x = direction * SPEED
		handle_sprite_flip(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	pass

func handle_sprite_flip(dir):
	sprite.flip_h = dir < 0
	pass

func handle_movement_anim_state(dir):
	anim_tree.set("parameters/move/blend_position", dir)
	pass
