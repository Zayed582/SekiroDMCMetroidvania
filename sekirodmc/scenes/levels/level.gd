extends Node2D

@onready var player_scene = preload("res://scenes/actors/player/player.tscn")
@onready var player_marker = $Marker2D
@onready var player_container = $Character

func _ready():
	spawn_player()
	GameManager.reset_game()
	pass

func spawn_player():
	var player = player_scene.instantiate()
	player.global_position = player_marker.global_position
	player_container.add_child(player)
	pass
