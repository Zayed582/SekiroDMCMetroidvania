extends Area2D

var parent = null

func init(data):
	var _parent = data.parent
	parent = _parent
	pass

func _on_body_entered(body):
	parent.player = body
	parent.set_state(parent.CHASE)
	pass # Replace with function body.


func _on_body_exited(body):
	parent.player = null
	parent.set_state(parent.IDLE)
	pass # Replace with function body.
