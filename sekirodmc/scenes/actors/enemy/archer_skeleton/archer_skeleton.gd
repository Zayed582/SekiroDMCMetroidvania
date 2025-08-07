extends BaseEnemy

@onready var arrow_scene = preload("res://scenes/components/arrow/arrow.tscn")
@onready var marker = $Marker2D

func _ready():
	super._ready()
	direction = -1

func spawn_arrow():
	var arrow = arrow_scene.instantiate()
	arrow.global_position = marker.global_position
	arrow.direction = direction
	get_tree().current_scene.add_child(arrow)
	pass
