extends Area2D

var parent = null

func init(data):
	parent = data.parent
	pass

func _on_body_entered(body):
	if parent.stop_process: return
	parent.set_state(parent.ATTACK)
	parent.travel("attack")
	parent.velocity.x = 0
	
	var direction = sign(body.global_position.x - parent.global_position.x)
	parent.set_direction(direction)

	pass # Replace with function body.


func _on_body_exited(body):
	if parent.stop_process: return
	parent.set_state(parent.CHASE)
	parent.travel("idle")
	pass # Replace with function body.
