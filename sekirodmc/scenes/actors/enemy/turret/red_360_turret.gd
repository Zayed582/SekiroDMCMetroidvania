extends BaseEnemy

@onready var bullet_spawn_nuzzle: Marker2D = $BulletSpawnNuzzle

func get_bullet_spawn_point() -> Vector2:
	return bullet_spawn_nuzzle.global_position

func apply_knockback(from_position: Vector2):
	pass

func handle_parry():
	var amount = 1
	if parry_meter_node: 
		parry_meter_node.global_rotation = deg_to_rad(180)
		parry_meter_node.global_position = self.global_position + Vector2(0, -70)
		parry_meter_node.show()
		parry_meter_node.stun_sender()
	pass

func handle_deathblow():
	pass
