extends Area2D

@export var activate_wait_time = 1.0
@export var deactivate_wait_time = 2.0

@onready var anim = $AnimationPlayer
@onready var activate_timer = $ActivateTimer
@onready var deactivate_timer = $DeactivateTimer

var damage = 2

func _ready():
	activate_timer.start()
	activate_timer.wait_time = activate_wait_time
	deactivate_timer.wait_time = deactivate_wait_time

func _on_timer_timeout():
	anim.play("new_animation")
	await anim.animation_finished
	deactivate_timer.start()
	pass # Replace with function body.


func _on_deactivate_timer_timeout():
	anim.play_backwards("new_animation")
	await anim.animation_finished
	activate_timer.start()
	pass # Replace with function body.
