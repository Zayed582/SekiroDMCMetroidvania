extends CharacterBody2D


const SPEED = 50.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 10000

@onready var direction = -1 if randf() < 0.5 else 1
@onready var state_machine = $Animation/AnimationTree.get("parameters/playback")

var health = 3
var stop_process = false
var knockback_decay: float = 800.0
var knockback_strength = 300
var damage = 1

func _physics_process(delta):
	handle_gravity(delta)
	handle_knockback(delta)
	handle_movement()
	move_and_slide()

func handle_movement():
	if stop_process: return
	velocity.x = direction * SPEED
	pass

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	pass

func handle_knockback(delta):
	if velocity.length() > 0:
		global_position.x += velocity.x * delta
		velocity = velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	pass

func apply_knockback(from_position: Vector2, strength: float):
	var direction = global_position.direction_to(from_position).normalized()
	velocity = -direction * strength

func take_damage(pos, damage):
	health -= damage
	state_machine.travel("hurt")
	apply_knockback(pos, knockback_strength)
	GameManager.emit_signal("shake_camera",0.2, 4.0)
	GameManager.emit_signal("add_hit_particle", damage, global_position)
	stop_process = true
	if health <= 0:
		state_machine.start("die")
		pass
	
	await get_tree().create_timer(1).timeout
	stop_process = false
	pass
