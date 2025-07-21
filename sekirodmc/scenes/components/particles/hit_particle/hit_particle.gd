extends Node2D

@onready var body = $Body
@onready var label = $Body/Label

func animate_hit(text):
	print("connected")
	label.text = "- " + str(text)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(body, "global_position", global_position + Vector2(0,-100), 0.5)
	pass
