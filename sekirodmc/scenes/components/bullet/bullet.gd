extends Area2D

var direction = 1
var speed = 400
var damage = 1
var sender = null
var is_parried = false

func _ready():
	pass # Replace with function body.

func _process(delta):
	position += direction * speed * delta
	pass


func reflect():
	direction = -direction
	speed *= 2
	is_parried = true
