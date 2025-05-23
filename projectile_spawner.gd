extends Node2D

@export var parry_projectile_scene: PackedScene
@export var spawn_offset: Vector2 = Vector2(100, -20)

func _process(_delta):
	if Input.is_action_just_pressed("spawn_projectile"):
		spawn()

func spawn():
	var proj = parry_projectile_scene.instantiate()
	proj.position = global_position + spawn_offset
	get_tree().current_scene.add_child(proj)
	print("🚀 Projectile spawned at:", proj.position)
