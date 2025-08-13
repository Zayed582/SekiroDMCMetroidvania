extends Area2D

@onready var timer = $Timer

var parent = null
var player_in_area = false
var player = null

func init(data):
	parent = data.parent
	pass

func _on_body_entered(body):
	#if parent.stop_process: return
	player_in_area = true
	player = body
	timer.start()
	attack()
	pass # Replace with function body.


func _on_body_exited(body):
	#if parent.stop_process: return
	player_in_area = false
	player = null
	parent.set_state(parent.CHASE)
	parent.travel("idle")
	timer.stop()
	pass # Replace with function body.

func attack():
	if !player: return
	if parent.stop_process: return
	
	var direction = sign(player.global_position.x - parent.global_position.x)
	parent.set_direction(direction)
	parent.set_state(parent.ATTACK)
	parent.travel("attack")
	parent.velocity.x = 0
	pass


func _on_timer_timeout():
	attack()
	pass # Replace with function body.
