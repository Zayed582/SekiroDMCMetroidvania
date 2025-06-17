extends Node2D

@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var raycast2d = $RayCast2D
@onready var bullet_scene = preload("res://scenes/components/bullet/bullet.tscn")
@onready var timer = $Timers/ShootTimer
@onready var anim2 = $AnimationPlayer2

var health = 3
var player: Node2D = null
var entered = false
var bullet_offset = Vector2(60,-80)


func play_anim():
	anim.play("new_animation")

func _process(delta):
	look_at_player()
	if player and !entered: 
		anim.play("new_animation")
		timer.start()
		entered = true
		
	elif !player and entered:
		anim.play_backwards("new_animation")
		entered = false
		timer.stop()
	pass

func look_at_player():
	if raycast2d.is_colliding():
		player = raycast2d.get_collider()
	else:
		player = null
	pass

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	var direction = sign(scale.x)
	var offset = bullet_offset
	offset.x = offset.x * direction
	bullet.global_position = global_position + offset
	bullet.direction = direction
	get_parent().add_child(bullet)
	pass

func take_damage(damage):
	health -= damage
	anim2.play("hurt")
	if health <= 0:
		queue_free()
		pass
	pass

func _on_shoot_timer_timeout():
	shoot_bullet()
	pass # Replace with function body.


func _on_hurt_box_area_entered(area):
	if area.is_in_group("projectile"):
		take_damage(area.damage)
		area.queue_free()
	pass # Replace with function body.
