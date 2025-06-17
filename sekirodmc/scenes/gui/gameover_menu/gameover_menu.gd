extends Control


func _ready():
	GameManager.connect("gameover", _show)
	_hide()
	pass

func _show():
	get_tree().paused = true
	show()
	pass

func _hide():
	get_tree().paused = false
	pass


func _on_button_pressed():
	_hide()
	get_tree().reload_current_scene()
	pass # Replace with function body.
