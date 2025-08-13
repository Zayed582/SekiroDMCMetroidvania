extends Area2D

@onready var sprite = $Sprite2D
@export var speed = 700

var damage = 1
var direction = -1
var sender = null

func _physics_process(delta):
	position.x += direction * speed * delta

func reflect():
	direction = -direction
	sprite.flip_h = direction == 1
	speed *= 2
	

func _on_area_entered(area):
	if area.is_in_group("hurt_area"):
		queue_free()
	pass # Replace with function body.
