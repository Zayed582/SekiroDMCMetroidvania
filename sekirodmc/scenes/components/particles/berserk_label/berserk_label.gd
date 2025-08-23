extends Node2D

@onready var body = $Body
@onready var label = $Body/Label

func animate(text):
	label.text = get_berserk_text(text)
	
	var tween = create_tween()
	var tween2 = create_tween()
	
	tween2.set_ease(Tween.EASE_OUT)
	tween2.set_trans(Tween.TRANS_BOUNCE)
	tween2.tween_property(body, "modulate", Color("red"), 0.5)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(body, "global_position", global_position + Vector2(0,-100), 1)
	
	await tween.finished
	await get_tree().create_timer(0.5).timeout
	queue_free()
	pass

func get_berserk_text(level):
	match level:
		1: return "Dull"
		2: return "Cool"
		3: return "Savage"
		4: return "Sick skills"
		5: return "Smoking Style"
	pass
