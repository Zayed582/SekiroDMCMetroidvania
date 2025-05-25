extends Area2D
@export var parry_projectile_scene: PackedScene
var is_parryable = true


@export var speed: float = 300.0
@export var direction: Vector2 = Vector2.RIGHT

func _ready():
	add_to_group("parryable")



func _physics_process(delta):
	position.x += speed * delta  # or -speed if going left

func on_parried():
	print("🧊 Projectile was parried!")
	queue_free()  # Or whatever you want


func spawn_parry_projectile():
	var proj = parry_projectile_scene.instantiate()
	proj.position = global_position + Vector2(100, -20)
	get_tree().current_scene.add_child(proj)
	print("🚀 Projectile spawned at:", proj.position)
