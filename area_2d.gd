extends Area2D

var is_parryable = false

func on_parried():
	get_parent().on_parried()

func _ready():
	add_to_group("parryable")
	await get_tree().process_frame  # Let the node finish loading
	await get_tree().create_timer(0.6).timeout  # Optional delay
	monitoring = true  # Enable collision detection

# No need for _process anymore — it's removed
