extends BaseEnemy

@onready var player_detector_area_2d: Area2D = $PlayerDetectorArea2D
@onready var shoot_delay_timer: Timer = $ShootDelayTimer

var current_target: CharacterBody2D = null
const SHOOT_DELAY_AFTER_SHOTS: float = 0.25

func look_direction():
	pass

func _process(delta: float) -> void:
	if health > 0:
		if current_target:
			look_at(current_target.global_position)


func _on_player_detector_area_2d_body_entered(body: Node2D) -> void:
	if health > 0:
		var body_list: Array = player_detector_area_2d.get_overlapping_bodies()
		if body_list.size() > 0:
			if not body_list.has(current_target):
				current_target = body_list[0]
				shoot_delay_timer.start()
	else:
		current_target = null
		if shoot_delay_timer.time_left > 0:
			shoot_delay_timer.stop()

func _on_player_detector_area_2d_body_exited(body: Node2D) -> void:
	if health > 0:
		var body_list: Array = player_detector_area_2d.get_overlapping_bodies()
		if body_list.size() > 0:
			if not body_list.has(current_target):
				current_target = body_list[0]
				shoot_delay_timer.start()
		else:
			current_target = null
			if shoot_delay_timer.time_left > 0:
				shoot_delay_timer.stop()
	else:
		current_target = null
		if shoot_delay_timer.time_left > 0:
			shoot_delay_timer.stop()
