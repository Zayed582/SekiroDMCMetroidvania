extends Control

@onready var anim = $AnimationPlayer
var scene = null

func navigate_to_scene(_scene):
	scene = _scene
	anim.play("fade_in")
	pass

func navigate():
	get_tree().change_scene_to_file(scene)
	pass
