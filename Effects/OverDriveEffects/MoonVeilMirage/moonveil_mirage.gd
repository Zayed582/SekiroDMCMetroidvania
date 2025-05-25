extends Area2D

@export var lifetime := 1.5
var facing_right := true
var has_parried := false

func _ready():
	print("✅ Mirage Ready")

	var enemy = get_closest_enemy()
	if enemy:
		facing_right = global_position.x < enemy.global_position.x
	else:
		facing_right = true

	$AnimatedSprite2D.flip_h = not facing_right
	$AnimatedSprite2D.play("ParryPose")
	add_to_group("mirage")
	$Timer.start(lifetime)

func get_closest_enemy():
	var closest_enemy = null
	var closest_dist = INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e or not e.is_inside_tree():
			continue
		var dist = global_position.distance_to(e.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_enemy = e
	return closest_enemy

func on_enemy_attack_triggered():
	if has_parried:
		return
	has_parried = true

	print("🌙 Mirage is now executing parry!")

	# 🔊 Detach SFX properly
	if has_node("ParrySFX"):
		var sfx = $ParrySFX
		sfx.reparent(get_tree().current_scene)  # Safe detach
		sfx.global_position = global_position
		sfx.play()

		# Queue_free manually after delay (let the sound finish)
		var cleanup := Timer.new()
		cleanup.one_shot = true
		cleanup.wait_time = sfx.stream.get_length()
		get_tree().current_scene.add_child(cleanup)

		cleanup.timeout.connect(func():
			if is_instance_valid(sfx):
				sfx.queue_free()
			cleanup.queue_free()
		)

		cleanup.start()

	$AnimatedSprite2D.play("Parry")
	await $AnimatedSprite2D.animation_finished

	# Fade out smoothly over 0.4 seconds
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished

	queue_free()


func _on_Timer_timeout():
	queue_free()
