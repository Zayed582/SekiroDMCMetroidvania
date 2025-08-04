extends CharacterBody2D
class_name AirBaseEnemy

enum {
	IDLE,
	CHASE,
	ATTACK,
	PATROL,
	JUMP,
	ON_EDGE,
	HURT,
	DEAD
}
var state = null



@export_category("Ability")
@export var damage: int = 2
#@export var can_jump = true


func set_state(_state):
	state = _state
	pass
