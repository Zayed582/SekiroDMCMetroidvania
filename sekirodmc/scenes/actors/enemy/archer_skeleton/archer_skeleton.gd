extends BaseEnemy

@onready var arrow_scene = preload("res://scenes/components/arrow/arrow.tscn")
@onready var marker = $Animation/Marker2D
var marker_offset = Vector2(20, 4)

func _ready():
	super._ready()
	direction = -1

func spawn_arrow():
	var arrow = arrow_scene.instantiate()
	arrow.global_position = marker.global_position + Vector2(marker_offset.x * direction, marker_offset.y)
	arrow.direction = direction
	arrow.sender = self
	get_tree().current_scene.add_child(arrow)
	pass
