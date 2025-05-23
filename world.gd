extends Node2D

@onready var beam_scene = preload("res://light_beam.tscn")

func _ready():
	$UI/DeathMenu/Button.pressed.connect(_on_Button_pressed)
	var test_clone = preload("res://laserbeam_clone.tscn").instantiate()
	get_tree().current_scene.add_child(test_clone)
	test_clone.global_position = Vector2(400, 400)



func _input(event):
	if event.is_action_pressed("ui_accept"):
		print("🔵 UI_ACCEPT pressed")
		_spawn_beam()

func _spawn_beam():
	var beam = beam_scene.instantiate()
	add_child(beam)
	beam.global_position = Vector2(500, 300)  # Or player.global_position + offset





func _on_Button_pressed() -> void:
	print("✅ Retry button pressed!")
	get_tree().reload_current_scene()


func _on_button_pressed() -> void:
	print("✅ Retry button pressed!")
	get_tree().reload_current_scene()
