extends Area2D

@onready var sprite = $Sprite2D

var damage = 1
var direction = -1
@export var speed = 400
var sender = null

func _physics_process(delta):
	position.x += direction * speed * delta

func reflect():
	direction = -direction
	sprite.flip_h = direction == 1
	

func _on_area_entered(area):
	if area.is_in_group("hurt_area"):
		queue_free()
	pass # Replace with function body.
