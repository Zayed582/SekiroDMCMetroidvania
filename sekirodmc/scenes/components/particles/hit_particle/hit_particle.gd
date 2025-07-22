extends Node2D

@onready var body = $Body
@onready var label = $Body/Label

func animate_hit(text):
	label.text = "-" + str(text)
	
	var tween = create_tween()
	var tween2 = create_tween()
	
	tween2.set_ease(Tween.EASE_OUT)
	tween2.set_trans(Tween.TRANS_BOUNCE)
	tween2.tween_property(body, "modulate", Color("red"), 0.5)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(body, "global_position", global_position + Vector2(0,-100), 0.45)
	
	await tween.finished
	queue_free()
	pass
