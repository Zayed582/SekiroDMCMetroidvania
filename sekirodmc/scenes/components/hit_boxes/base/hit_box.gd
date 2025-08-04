extends Area2D

var damage = 1

func init(data):
	var _damage = damage
	pass

func _on_body_entered(body):
	#if stop_process: return
	print("entered hitbox")
	var player = body
	player.hitbox.emit_signal("take_damage", damage)
	pass # Replace with function body.
