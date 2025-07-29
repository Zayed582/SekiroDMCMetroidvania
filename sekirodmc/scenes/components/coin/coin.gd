extends RigidBody2D

@onready var anim2 = $AnimationPlayer2

#KNOCKBACK
#var knockback_decay: float = 800.0
#var knockback_strength = 200

#PHYSICS
#const GRAVITY = 1000

@export var has_gravity = false


func _ready():
	gravity_scale = 1 if has_gravity else 0
	if !has_gravity: anim2.play("new_animation")

#func _physics_process(delta):
	#handle_gravity(delta)
	#handle_knockback(delta)
	#move_and_slide()
#
#func take_damage(pos, damage):
	#apply_knockback(pos, knockback_strength)
	##GameManager.emit_signal("shake_camera",0.2, 4.0)
	#pass

#func handle_gravity(delta):
	#if !has_gravity: return
	#
	#if not is_on_floor():
		#velocity.y += GRAVITY * delta
	#pass

#func apply_knockback(from_position: Vector2, strength: float):
	#var direction = global_position.direction_to(from_position).normalized()
	#velocity = -direction * strength
#
#
#func handle_knockback(delta):
	#if velocity.length() > 0:
		#global_position.x += velocity.x * delta
		#velocity = velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	#pass


func _on_area_2d_body_entered(body):
	GameManager.emit_signal("add_coin")
	queue_free()
	pass # Replace with function body.
