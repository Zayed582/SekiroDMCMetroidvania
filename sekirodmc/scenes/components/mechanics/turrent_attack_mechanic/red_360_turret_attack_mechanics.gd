extends Area2D

@onready var bullet_scene = preload("res://scenes/components/bullet/bullet.tscn")
@onready var timer = $Timer

var timer_is_running: bool = true
var damage = 1
var parent: CharacterBody2D = null
var player: CharacterBody2D = null
var can_track: bool = true
const SHOOT_DELAY_ON_FIRST_ENTRY: float = 2
const NORMAL_SHOOT_DELAY: float = 5
const ROTATION_SPEED: float = 10

func init(data):
	parent = data.parent
	pass

func _physics_process(delta):
	if parent.stop_process:
		timer_is_running = false
		if timer.is_stopped() ==  false:
			timer.stop()
	else:
		if player and timer_is_running == false:
			if timer.is_stopped():
				timer.start()
				timer_is_running = true
				parent.velocity = Vector2.ZERO
				parent.move_and_slide()
	if parent.stop_process: return
	look_at_player(delta)


func look_at_player(delta_value: float):
	if can_track:
		if player:
			#parent.look_at(player.global_position)
			var direction: Vector2 = player.global_position - parent.global_position
			var target_angle: float = direction.angle()
			parent.rotation = lerp_angle(parent.rotation, target_angle, ROTATION_SPEED * delta_value)

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	var direction = parent.global_position.direction_to(player.global_position).normalized()
	if parent.has_method("get_bullet_spawn_point"):
		bullet.position = parent.get_bullet_spawn_point()
	else:
		printerr("parent does not have bullet spawn point in red 360 turret attack mechanics script")
	bullet.direction = direction
	bullet.damage = damage
	bullet.sender = parent
	get_tree().current_scene.add_child(bullet)
	parent.set_state(parent.ATTACK)
	parent.travel("attack")
	pass

func _on_timer_timeout():
	if parent.stop_process: return
	can_track = false
	shoot_bullet()
	await get_tree().physics_frame
	if player:
		can_track = true
		timer.wait_time = NORMAL_SHOOT_DELAY
		timer.start()
	else:
		can_track = false
	pass # Replace with function body.


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		can_track = true
		timer.wait_time = SHOOT_DELAY_ON_FIRST_ENTRY
		if timer_is_running == true:
			timer.start()


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
		can_track = false
		parent.set_state(parent.IDLE)
		parent.travel("rest")
		timer.stop()
