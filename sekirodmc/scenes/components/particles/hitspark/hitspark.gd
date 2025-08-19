extends Node2D

enum {
	ATTACK,
	DEATHBLOW
}

var state = ATTACK
@onready var anim = $AnimationPlayer

func _ready():
	play_hitspark()
	pass

func play_hitspark():
	match state:
		ATTACK:
			anim.play("attack")
	pass
