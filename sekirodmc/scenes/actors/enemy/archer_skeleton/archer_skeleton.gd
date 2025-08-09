extends BaseEnemy

@onready var arrow_scene = preload("res://scenes/components/arrow/arrow.tscn")
@onready var marker = $Animation/Marker2D
var marker_offset = Vector2(100, 4)
var is_in_frame = false

func _ready():
	super._ready()
	direction = -1

func spawn_arrow():
	if !is_in_frame: return
	var arrow = arrow_scene.instantiate()
	arrow.global_position = marker.global_position + Vector2(marker_offset.x * direction, marker_offset.y)
	arrow.direction = direction
	arrow.sender = self
	get_tree().current_scene.add_child(arrow)
	pass


func _on_visible_on_screen_enabler_2d_screen_entered():
	is_in_frame = true
	pass # Replace with function body.


func _on_visible_on_screen_enabler_2d_screen_exited():
	is_in_frame = false
	pass # Replace with function body.
