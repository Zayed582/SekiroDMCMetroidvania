extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var health: int = 3
var can_take_damage: bool = true

func take_damage(pos: Vector2, value: float) -> void:
	if can_take_damage:
		if health > 0:
			health -= 1
			animation_player.play("hurt")
			if health <= 0:
				can_take_damage = false
				animation_player.play("die")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "hurt":
		animation_player.play("idle")
	elif anim_name == "die":
		queue_free()


func _on_damage_detector_area_2d_area_entered(area: Area2D) -> void:
	if area.get("damage"):
		take_damage(Vector2.ZERO, area.damage)
	elif area.has_method("change_direction"):
		area.change_direction()
