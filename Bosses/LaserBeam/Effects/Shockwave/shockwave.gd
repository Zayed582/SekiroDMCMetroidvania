extends Area2D

@export var expand_speed := 200
@export var duration := 1.0

@onready var anim = $AnimatedSprite2D
@onready var parry_area = $ParryTagArea
@onready var attack_area = $AttackArea

var timer := 0.0
var was_parried := false
var velocity := Vector2(250, 0)  # optional if you want to reflect

func _ready():
	scale = Vector2(0.2, 1)  # starts small
	add_to_group("parryable")

	if parry_area:
		parry_area.owner = self
		parry_area.monitoring = true
		parry_area.set("is_parryable", true)
		parry_area.add_to_group("parryable")

	anim.play("Idle")

func _process(delta):
	timer += delta

	if was_parried:
		position += velocity.rotated(rotation) * delta
	else:
		scale.x += expand_speed * delta  # Expand outward (radial shockwave)

	if timer >= duration:
		queue_free()

func on_parried():
	if was_parried:
		return
	was_parried = true

	print("💥 Shockwave parried!")

	# Disable further hit
	if attack_area:
		attack_area.monitoring = false

	if parry_area:
		parry_area.monitoring = false
		parry_area.set("is_parryable", false)

	anim.modulate = Color(1, 1, 1)
	velocity = Vector2(250, -100)  # Reflect angle, tweak as needed

	await get_tree().create_timer(0.6).timeout
	queue_free()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if was_parried:
		return  # Already reflected, don't deal damage

	if body.name == "Player" or body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage()
			print("💢 Shockwave hit the player!")
		else:
			print("❌ Player has no take_damage method!")
