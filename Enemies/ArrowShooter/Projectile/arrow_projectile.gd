extends Area2D

@export var speed := 600
@export var lifetime := 5.0

var direction := Vector2.ZERO
var was_parried := false

@onready var sprite = $Sprite2D
@onready var attack_area = $AttackArea
@onready var parry_area = $ParryTagArea

func _ready():
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	parry_area.owner = self
	parry_area.monitoring = true
	parry_area.set("is_parryable", true)
	add_to_group("parryable")

	# Auto delete after X seconds
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func initialize(dir: Vector2, spd: float):
	direction = dir.normalized()
	speed = spd
	rotation = direction.angle()

func _physics_process(delta):
	# Slightly faster when reflected
	var current_speed = speed * (1.5 if was_parried else 1.0)
	position += direction * current_speed * delta

func on_parried():
	if was_parried:
		return

	was_parried = true
	print("✅ Arrow was parried!")

	# Flip direction
	direction = -direction
	rotation = direction.angle()

	# Change visual to indicate reflection
	sprite.modulate = Color(1, 0.8, 0.4)

	# Disable parry area
	parry_area.monitoring = false
	parry_area.set("is_parryable", false)

	# Re-enable attack area so it can damage enemies
	attack_area.monitoring = true
	attack_area.set_deferred("monitoring", true)
	add_to_group("reflected_projectile")

func _on_attack_area_body_entered(body: Node2D) -> void:
	print("🚨 Arrow hit something:", body)

	if not is_instance_valid(body):
		print("❌ Invalid body!")
		return

	var root = body
	while root and root.get_parent() and not root.is_in_group("player") and not root.is_in_group("enemies"):
		root = root.get_parent()

	if not root:
		print("❌ Root resolution failed — no parent found!")
		return

	print("🔍 Root object resolved as:", root.name)

	if was_parried:
		print("🟡 Arrow was reflected, checking for enemies...")
		if root.is_in_group("enemies"):
			print("💥 Reflected arrow hit enemy:", root.name)
			if root.has_method("take_damage"):
				root.take_damage(1)
				print("✅ Enemy took damage!")
			else:
				print("❌ Enemy has no take_damage()")

			if root.has_method("apply_posture_damage"):
				root.apply_posture_damage(30)
				print("🌀 Enemy took posture damage!")
			else:
				print("❌ Enemy has no apply_posture_damage()")

			queue_free()
		else:
			print("❌ Reflected arrow hit non-enemy:", root.name)
	else:
		print("🔴 Arrow is normal, checking for player...")
		if root.is_in_group("player"):
			print("🔥 Arrow hit the player!")
			if root.has_method("take_damage"):
				root.take_damage()
			else:
				print("❌ Player has no take_damage()")
			queue_free()
		else:
			print("❌ Arrow hit non-player object:", root.name)
