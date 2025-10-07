extends BaseEnemy

@onready var bullet_spawn_nuzzle: Marker2D = $BulletSpawnNuzzle

func get_bullet_spawn_point() -> Vector2:
	return bullet_spawn_nuzzle.global_position
