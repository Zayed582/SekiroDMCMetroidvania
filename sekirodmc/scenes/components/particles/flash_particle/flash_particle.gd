extends Control

@onready var anim = $AnimationPlayer

func _ready():
	GameManager.connect("add_flash_particle", _on_add_flash_particle)
	pass

func _on_add_flash_particle():
	anim.play("new_animation")
	pass
