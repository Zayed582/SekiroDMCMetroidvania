extends Control

@onready var berserker_level_label_ui: Label = $BerserkerLevelLabelUI


func _ready() -> void:
	berserker_level_label_ui.hide()
	GameManager.set_bearserk_level.connect(_on_set_berserker_level)

func _on_set_berserker_level(level: int) -> void:
	var the_tween: Tween = create_tween()
	the_tween.set_ease(Tween.EASE_OUT)
	the_tween.set_trans(Tween.TRANS_SINE)
	berserker_level_label_ui.scale = Vector2(1,1)
	the_tween.tween_property(berserker_level_label_ui, "scale", Vector2(1.5,1.5), 0.2)
	the_tween.tween_property(berserker_level_label_ui, "scale", Vector2(1,1), 0.2)
	if level > 1:
		berserker_level_label_ui.show()
	else:
		berserker_level_label_ui.hide()
	match level:
		1: berserker_level_label_ui.text = "Dull"
		2: berserker_level_label_ui.text = "Cool"
		3: berserker_level_label_ui.text = "Stylish"#"Savage"
		4: berserker_level_label_ui.text = "SSick"#"Sick skills"
		5: berserker_level_label_ui.text = "Smoking Style"
	pass
