extends Node

#TODO: REMOVE THIS
signal update_player_debug_state(text)
signal shake_camera(duration, intensity)
signal gameover
signal clear_parrys
signal hitstop(duration)

#PLAYER HUD
signal set_health(health)
signal set_mana_progress(mana_progress)
signal set_mana(mana)
signal set_stamina(stamina)
signal set_max_health(MAX_HEALTH)
signal set_max_mana(MAX_MANA)
signal set_max_stamina(MAX_STAMINA)

#PARTICE AND SFX
signal add_hit_particle(text, pos)

var parriable_enemies = []

var current_level = 1
var max_levels = 2

func _ready():
	connect("hitstop", _on_hitstop)
	pass

func _on_hitstop(duration := 0.1):
	#Engine.time_scale = 0.0
	#await get_tree().create_timer(duration, true, false, true).timeout
	#Engine.time_scale = 1.0
	pass
func move_to_next_level():
	if current_level > max_levels:
		TransitionScene.navigate_to_scene("res://scenes/main_menu/main_menu.tscn")
		current_level = max_levels
	else:
		var next_level = "res://scenes/levels/level_%s.tscn" % current_level
		TransitionScene.navigate_to_scene(next_level)
	pass
