extends CharacterBody2D

@export var dash_speed := 3000.0
@export var dash_duration := 0.15
@export var dash_delay := 0.2

@onready var anim = $AnimatedSprite2D
@onready var parry_area = $ParryTagArea
@onready var attack_area = $AttackArea

var dash_direction := Vector2.ZERO

func _ready():
	print("🟢 Clone is alive in the scene")

	
	anim.play("Idle")
	parry_area.monitoring = false
	parry_area.set("is_parryable", false)
	attack_area.monitoring = false

func start_dash(direction: Vector2) -> void:
	print("➡️ start_dash called")
	dash_direction = direction.normalized()
	await _run_delayed_dash()

func _run_delayed_dash() -> void:
	print("⏳ Clone dash starting after delay")
	await get_tree().create_timer(dash_delay).timeout
	print("💨 Clone begins dashing!")


	var elapsed = 0.0
	while elapsed < dash_duration:
		velocity = dash_direction * dash_speed
		move_and_slide()
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	velocity = Vector2.ZERO
	parry_area.monitoring = false
	parry_area.set("is_parryable", false)
	attack_area.monitoring = false

	queue_free()
