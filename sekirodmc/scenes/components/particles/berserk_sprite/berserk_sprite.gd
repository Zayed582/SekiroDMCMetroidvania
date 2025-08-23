extends Node2D

@onready var after_image = $Sprite2D
@onready var anim = $AnimationPlayer

func init(sprite):
	after_image.texture = sprite.texture
	after_image.hframes = sprite.hframes
	after_image.vframes = sprite.vframes
	after_image.frame = sprite.frame
	after_image.scale = sprite.scale
	
	# Rainbow color
	var hue = randf()
	var color = Color.from_hsv(hue, 1.0, 1.0)
	color.a = 0.8
	after_image.modulate = color
	after_image.show_behind_parent = true
	after_image.flip_h = sprite.flip_h
	after_image.global_position = sprite.global_position
	anim.play("new_animation")
