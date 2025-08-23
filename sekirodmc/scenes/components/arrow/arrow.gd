extends Area2D

@onready var sprite = $Sprite2D
@export var speed = 700

var damage = 1
var direction = -1
var sender = null
var is_parried = false

func _physics_process(delta):
	position.x += direction * speed * delta

func reflect():
	var last_dir = direction
	direction = -direction
	
	print("reflected: ", direction)
	flip(direction)
	speed *= 2
	is_parried = true

func flip(direction):
	print("direction flor arrow")
	sprite.flip_h = direction == 1
	pass

func _on_area_entered(area):
	if area.is_in_group("hurt_area"):
		queue_free()
	pass # Replace with function body.
