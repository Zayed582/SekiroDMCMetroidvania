extends Node2D

@export_enum("Left", "Right") var look_at = "Left"
@export var parry_meter = Node2D
@export var health = 20

@onready var body = $Body
@onready var anim = $Animations/AnimationPlayer
@onready var sprite = $Body/Sprite2D
@onready var raycast2d = $Body/RayCast2D
@onready var bullet_scene = preload("res://scenes/components/bullet/bullet.tscn")
@onready var timer = $Timers/ShootTimer
@onready var anim2 = $Animations/AnimationPlayer2
@onready var muzzle = $Body/Marker2D

var player: Node2D = null
var entered = false
var bullet_offset = Vector2(60,-80)

#KNOCKBACK
var velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 1000.0 

var stop_process = false

func play_anim():
	anim.play("new_animation")

func _process(delta):
	if stop_process: return
	
	look_at_direction()
	look_at_player()
	handle_knockback(delta)
	
	if player and !entered: 
		anim.play("new_animation")
		timer.start()
		entered = true
		
	elif !player and entered:
		anim.play_backwards("new_animation")
		entered = false
		timer.stop()
	pass

func look_at_direction():
	match look_at:
		"Left": 
			body.scale.x = -1
			pass
		"Right": 
			body.scale.x = 1
			pass
	
	pass

func handle_knockback(delta):
	if velocity.length() > 0:
		global_position.x += velocity.x * delta
		velocity = velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	pass

func look_at_player():
	if raycast2d.is_colliding():
		player = raycast2d.get_collider()
	else:
		player = null
	pass

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	var direction = sign(body.scale.x)
	bullet.global_position = global_position + Vector2(muzzle.position.x * direction, muzzle.position.y)
	bullet.direction = direction
	bullet.sender = self
	get_parent().add_child(bullet)
	pass

func apply_knockback(from_position: Vector2, strength: float):
	var direction = global_position.direction_to(from_position).normalized()
	velocity = -direction * strength

func take_damage(pos, damage):
	health -= damage
	anim2.play("hurt")
	apply_knockback(pos, 250)
	GameManager.emit_signal("shake_camera",0.2, 4.0)
	await get_tree().create_timer(0.2).timeout
	stop_process = true
	if health <= 0:
		queue_free()
		pass
	await get_tree().create_timer(0.2).timeout
	stop_process = false
	pass

func handle_parry():
	var amount = 1
	if parry_meter: parry_meter.set_parry_details(amount, self)
	pass

func _on_shoot_timer_timeout():
	if stop_process: return
	shoot_bullet()
	pass # Replace with function body.


func _on_hurt_box_area_entered(area):
	if area.is_in_group("projectile"):
		take_damage(area.global_position, area.damage)
		area.queue_free()
	pass # Replace with function body.
