extends Node2D

@onready var parent: CharacterBody2D = get_parent()

func _on_area_2d_body_exited(body):
	change_direction()

func change_direction():
	if !parent: return
	parent.direction = -parent.direction
	pass # Replace with function body.
