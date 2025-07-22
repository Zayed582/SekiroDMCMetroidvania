extends Node2D

@onready var hit_particle_scene = preload("res://scenes/components/particles/hit_particle/hit_particle.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.connect("add_hit_particle", _on_add_hit_particle)
	pass

func _on_add_hit_particle(text, pos):
	var hit_particle: Node2D = hit_particle_scene.instantiate()
	add_child(hit_particle)
	hit_particle.global_position = pos + Vector2(0, -20)
	hit_particle.animate_hit(text)
	pass
