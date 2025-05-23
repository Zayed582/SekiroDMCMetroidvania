extends Area2D

@onready var anim = $AnimatedSprite2D
@onready var parry_area = $ParryTagArea
@onready var parry_shape = $ParryTagArea/CollisionShape2D
@onready var attack_area = $AttackArea  # ✅ This must be an Area2D with monitoring enabled

var velocity := Vector2(0, 250)
var was_parried := false

func _ready():
	add_to_group("parryable")
	if parry_area:
		parry_area.owner = self
		parry_area.monitoring = true
		parry_area.set("is_parryable", true)
		parry_area.add_to_group("parryable")
	anim.play("Idle")

func _physics_process(delta):
	if was_parried:
		position += velocity * delta
	else:
		position.y += velocity.y * delta

func on_parried():
	if was_parried:
		return
	was_parried = true

	print("☀️ Orb parried!")

	# Disable hitbox for damage
	if attack_area:
		attack_area.monitoring = false

	# Disable parry after deflect
	if parry_area:
		parry_area.monitoring = false
		parry_area.set("is_parryable", false)

	anim.modulate = Color(1, 1, 1)
	velocity = Vector2(200, -200).rotated(rotation)

	await get_tree().create_timer(0.6).timeout
	queue_free()

func _on_attack_area_body_entered(body: Node2D) -> void:
	if was_parried:
		return  # Don't damage player if deflected

	if body.name == "Player" or body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage()
			print("🔥 Orb hit the player!")
			queue_free()
		else:
			print("❌ Player has no take_damage() method")
