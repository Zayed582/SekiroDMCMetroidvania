extends Area2D

var direction = 1
var speed = 400
var damage = 1

func _ready():
	pass # Replace with function body.

func _process(delta):
	position.x += direction * speed * delta
	pass


func reflect():
	direction = -direction
