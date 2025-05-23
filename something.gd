extends Node2D

func _ready():
	$UI/HitFlash.color = Color(1, 0, 0, 0.0) # invisible but red

func _input(event):
	if event.is_action_pressed("ui_accept"): # Enter key or Spacebar
		flash_screen()

func flash_screen():
	print("FLASH!") # Debug line
	var hit_flash = $UI/HitFlash
	hit_flash.modulate = Color(1, 0, 0, 0.6)

	var tween = create_tween()
	tween.tween_property(hit_flash, "modulate:a", 0.0, 0.4)
