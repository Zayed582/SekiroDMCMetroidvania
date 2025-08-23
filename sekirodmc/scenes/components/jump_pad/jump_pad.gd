extends Area2D

@export var JUMP_FORCE = -1500.0
@onready var anim = $AnimationPlayer

func activate_jump_boost(body):
	if body.velocity.y <= 0: return
	GameManager.emit_signal("shake_camera",0.2, 4.0)
	anim.play("activate")
	body.activate_jump_boost(JUMP_FORCE)
	pass

func _on_body_entered(body):
	activate_jump_boost(body)
	pass # Replace with function body.
