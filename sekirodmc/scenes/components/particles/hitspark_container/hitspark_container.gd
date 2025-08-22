extends Node2D

@onready var hit_particle_scene = preload("res://scenes/components/particles/hitspark/hitspark.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.connect("add_hitspark_particle", _on_add_hitspark_particle)
	pass

func _on_add_hitspark_particle(text, pos, deathblow_active):
	var hit_particle: Node2D = hit_particle_scene.instantiate()
	hit_particle.deathblow_active = deathblow_active
	add_child(hit_particle)
	hit_particle.global_position = pos + Vector2(0, -20)
	pass
