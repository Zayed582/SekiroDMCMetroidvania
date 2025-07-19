extends CanvasLayer

@onready var anim = $AnimationPlayer
var scene = null

func navigate_to_scene(_scene):
	scene = _scene
	anim.play("fade_in")
	pass

func navigate():
	get_tree().call_deferred("change_scene_to_file", scene)
	pass


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "fade_in" and scene != "":
		navigate()
		anim.play("fade_out")
	pass # Replace with function body.
