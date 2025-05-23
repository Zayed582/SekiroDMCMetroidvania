extends CanvasLayer
class_name TransitionScreen

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect

func _ready():
	#Overwrites the current transition screen in SceneManager once the level loads
	SceneManager.transition_screen = self

## True -> plays fade_in, FALSE -> plays fade_out
func fade(fade_in: bool):
	var anim: String = 'fade_in' if fade_in else 'fade_out'
	animation_player.play(anim)
	
	color_rect.show()
	
	await animation_player.animation_finished #Stop function until animation ends
	
	return
