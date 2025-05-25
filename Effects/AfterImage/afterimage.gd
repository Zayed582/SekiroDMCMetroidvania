extends Node2D

func setup(original_sprite: AnimatedSprite2D, flip_h: bool, rank: String = ""):
	var sprite = $AfterSprite  # Get it when you need it

	sprite.sprite_frames = original_sprite.sprite_frames
	sprite.animation = original_sprite.animation
	sprite.frame = original_sprite.frame
	sprite.scale = original_sprite.scale
	sprite.flip_h = flip_h
	sprite.position = original_sprite.position


	# 🌈 Rank-Based Color
	match rank:
		"COOL":
			sprite.modulate = Color(0.3, 0.6, 1.0, 0.4)  # Light Blue
		"STYLISH":
			sprite.modulate = Color(0.6, 0.2, 1.0, 0.4)  # Purple
		"SAVAGE", "SSSICK!!":
			sprite.modulate = Color(1.0, 0.2, 0.2, 0.9)  # Red
		"SMOKIN STYLE":
			sprite.modulate = Color(1.0, 1.0, 0.4, 0.8)  # Gold
		_:
			sprite.modulate = Color(1, 1, 1, 0.4)  # Default

	# ⏳ Fade out and destroy
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0, 0.3).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(Callable(self, "queue_free"))
