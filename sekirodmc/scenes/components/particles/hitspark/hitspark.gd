extends Node2D

var deathblow_active = false
@onready var anim = $AnimationPlayer

func _ready():
	play_hitspark()
	pass

func play_hitspark():
	if deathblow_active:
		anim.play("deathblow_attack")
	else:
		anim.play("attack")
	pass
