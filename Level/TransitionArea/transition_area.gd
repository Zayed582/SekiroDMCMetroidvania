extends Area2D
class_name TransitionArea

@export var level_name: String


func _on_body_entered(body: Node2D) -> void:
	if body is not Player: return #Filters out body2Ds that don't have the Player class_name in their script
	
	#Call to handle transition
	SceneManager.transition_to_scene(level_name)
