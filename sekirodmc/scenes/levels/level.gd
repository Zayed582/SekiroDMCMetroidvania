extends Node2D

@onready var player_scene = preload("res://scenes/actors/player/player.tscn")
@onready var player_marker = $Marker2D

func _ready():
	spawn_player()
	pass

func spawn_player():
	var player = player_scene.instantiate()
	player.global_position = player_marker.global_position
	add_child(player)
	pass
