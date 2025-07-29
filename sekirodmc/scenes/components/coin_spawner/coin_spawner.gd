extends Node2D

@onready var coin_scene = preload("res://scenes/components/coin/coin.tscn")

func _ready():
	GameManager.connect("spawn_coin", _on_spawn_coin)

func add_coin_to_scene(pos, vel):
	var coin: RigidBody2D = coin_scene.instantiate()
	coin.global_position = pos
	coin.has_gravity = true
	coin.apply_impulse(vel)
	call_deferred("add_child",coin)
	pass

func _on_spawn_coin(pos, amount):
	randomize()
	for i in amount:
		var rand_pos = pos + Vector2(randi_range(-10, 10), randi_range(-10, 10))
		var rand_vel = Vector2(randf_range(-100, 100), randi_range(-100, -500))
		add_coin_to_scene(rand_pos, rand_vel)
		pass
	pass
