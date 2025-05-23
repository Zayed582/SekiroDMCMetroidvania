extends Area2D

@onready var anim = $AnimatedSprite2D
@onready var collision = $CollisionShape2D
@onready var parry_area: Area2D = $ParryTagArea
@onready var attack_area = $AttackArea

var parryable := false
var was_reflected := false

func _ready() -> void:
	add_to_group("parryable")
	if parry_area:
		parry_area.owner = self  # ✅ So player finds on_parried()
	anim.scale = Vector2(6, 7)
	attack_area.monitoring = false  # Start disabled
	await start_beam()

func start_beam():
	# CHARGE
	anim.play("Charge")
	await anim.animation_finished

	# FIRE LOOP
	collision.disabled = false
	attack_area.monitoring = true  # ✅ Enable attack hitbox
	if parry_area:
		parryable = true
		parry_area.monitoring = true
		parry_area.set("is_parryable", true)
		print("🟢 Beam parryable during FIRE:", parry_area.name)

	await play_fire_loop()

	if not was_reflected:
		await fade_and_destroy()

func reflect_beam():
	if was_reflected:
		return

	was_reflected = true
	parryable = false

	# Disable parry
	if parry_area:
		parry_area.monitoring = false
		parry_area.set("is_parryable", false)

	attack_area.monitoring = false  # Stop damaging

	print("⚡ Beam was parried and reflected!")

	# ✨ Diagonal reflect logic
	var player = get_node_or_null("/root/World/Player")
	if player:
		var offset = Vector2(250, -250)  # Diagonal up-back
		if not player.facing_right:
			offset.x *= -1  # Flip X for left-facing

		global_position = player.global_position + offset
		rotation = deg_to_rad(-45 if player.facing_right else -135)

		anim.play("Reflect")  # Optional reflect anim
	else:
		print("❌ No player found")

	await get_tree().create_timer(0.5).timeout
	await fade_and_destroy()

func fade_and_destroy():
	collision.disabled = true
	attack_area.monitoring = false

	if parry_area:
		parry_area.monitoring = false
		parry_area.set("is_parryable", false)

	anim.play("Fade")
	await anim.animation_finished
	queue_free()

func on_parried():
	print("💥 Beam on_parried() triggered!")
	await reflect_beam()

func play_fire_loop():
	# Play Fire animation and stop before looping part
	anim.play("Fire")
	await get_tree().process_frame

	# Wait until we reach frame 5 (start of loop)
	while anim.frame < 5:
		await get_tree().process_frame

	# Loop frames 5–7 manually
	var loop_timer := 2.0
	while loop_timer > 0:
		for frame in [5, 6, 7]:
			anim.frame = frame
			await get_tree().create_timer(0.08).timeout
			loop_timer -= 0.08

func _on_attack_area_body_entered(body: Node2D) -> void:
	if was_reflected:
		return  # ✅ No damage after parry

	if body.name == "Player" or body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage()
			print("💢 Beam hit the player!")
