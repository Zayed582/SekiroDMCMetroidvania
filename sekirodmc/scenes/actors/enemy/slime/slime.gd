extends BaseEnemy

const SPEED = 50.0
const JUMP_VELOCITY = -400.0

func _ready():
	super._ready()
	direction = -1 if randf() < 0.5 else 1
	pass

func _physics_process(delta):
	super._physics_process(delta)
	handle_movement()
	move_and_slide()

func handle_movement():
	if stop_process: return
	velocity.x = direction * SPEED
	pass
