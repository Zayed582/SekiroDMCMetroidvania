extends Area2D

@export var speed := 150
@export var direction := Vector2(1, 0)
@export var lifetime := 1.5
@export var explosion_scene := preload("res://Effects/CharmEffects/RazorBloom/razor_bloom_explosion.tscn")

func _ready():
	$CollisionShape2D.disabled = false
	$AnimatedSprite2D.play("Fly")
	rotation = direction.angle()
	$Timer.start(lifetime)
	connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta):
	position += direction.normalized() * speed * delta

func _on_Timer_timeout():
	queue_free()

func _on_body_entered(body):
	if not body.is_in_group("enemies"):
		return  # ❌ Ignore anything that's not an enemy

	if body.has_method("take_damage"):
		body.take_damage()

		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)

	queue_free()
