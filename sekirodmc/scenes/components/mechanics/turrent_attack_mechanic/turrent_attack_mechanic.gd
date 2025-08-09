extends Area2D

@export var offset = Vector2.ZERO
@onready var raycast = $RayCast2D
@onready var bullet_scene = preload("res://scenes/components/bullet/bullet.tscn")
@onready var timer = $Timer

var damage = 1
var parent: CharacterBody2D = null
var player: CharacterBody2D = null
var entered = false

func init(data):
	parent = data.parent
	pass

func _physics_process(delta):
	if parent.stop_process: return
	
	look_at_player()
	
	if player and !entered: 
		parent.set_state(parent.ATTACK)
		parent.travel("attack")
		timer.start()
		entered = true
		
	elif !player and entered:
		parent.set_state(parent.IDLE)
		parent.travel("rest")
		entered = false
		timer.stop()
	pass

func look_at_player():
	if raycast.is_colliding():
		player = raycast.get_collider()
	else:
		player = null
	pass

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	var direction = parent.global_position.direction_to(player.global_position).normalized().x
	bullet.position = parent.global_position + Vector2(offset.x * direction, offset.y)
	bullet.direction = direction
	bullet.damage = damage
	bullet.sender = parent
	get_tree().current_scene.add_child(bullet)
	pass

func _on_timer_timeout():
	if parent.stop_process: return
	shoot_bullet()
	pass # Replace with function body.
