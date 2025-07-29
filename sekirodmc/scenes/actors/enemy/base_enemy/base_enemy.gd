class_name BaseEnemy extends CharacterBody2D

#EXPORTS
@export_category("BaseEnemy")
@export var health = 3
@export var damage = 1

@export_group("Animations")
@export_subgroup("Hit")
@export var hit_box: PackedScene
@export var hit_sound: AudioStream

@export_subgroup("Hurt")
@export var hurt_box: PackedScene
@export var hurt_sound: AudioStream

@export_subgroup("Detectors")
@export var edge_detector: PackedScene


@export_subgroup("Toggles")
@export var has_wall_detection = false

# INITIALISIATIONS
@onready var state_machine = $Animation/AnimationTree.get("parameters/playback")

#NODES

var hit_box_node: Area2D = null
var hurt_box_node: Area2D = null
var edge_detector_node = null

#PHYSICS
const GRAVITY = 10000
var direction = 0

#VARIABLES
var stop_process = false

#KNOCKBACK
var knockback_decay: float = 800.0
var knockback_strength = 200

func _ready():
	init_dependencies()
	pass

func init_dependencies():
	if hit_box:
		hit_box_node = add_node(hit_box)
	if hurt_box:
		hurt_box_node = add_node(hurt_box)
	if edge_detector:
		edge_detector_node = add_node(edge_detector)
		edge_detector_node.position = Vector2(0,40)
	pass

func _physics_process(delta):
	handle_gravity(delta)
	handle_knockback(delta)
	handle_flips()
	handle_wall_detection()


func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	pass

func handle_knockback(delta):
	if velocity.length() > 0:
		global_position.x += velocity.x * delta
		velocity = velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	pass

func apply_knockback(from_position: Vector2, strength: float):
	var direction = global_position.direction_to(from_position).normalized()
	velocity = -direction * strength

func add_node(scene: PackedScene):
	var child = scene.instantiate()
	add_child(child)
	return child

func silence_monitoring_node():
	if hit_box_node: 
		hit_box_node.set_deferred("monitoring", false)
		hit_box_node.set_deferred("monitorable", false)
	if hurt_box_node: 
		hurt_box_node.set_deferred("monitoring", false)
		hurt_box_node.set_deferred("monitorable", false)
	pass

func handle_flips():
	if edge_detector_node: edge_detector_node.scale.x = direction
	pass

func handle_wall_detection():
	if is_on_wall() and is_on_floor():
		direction = -direction
	pass

func take_damage(pos, damage):
	health -= damage
	state_machine.travel("hurt")
	apply_knockback(pos, knockback_strength)
	GameManager.emit_signal("shake_camera",0.2, 4.0)
	GameManager.emit_signal("add_hit_particle", damage, global_position)
	stop_process = true
	
	if health <= 0:
		silence_monitoring_node()
		state_machine.start("die")
		GameManager.emit_signal("spawn_coin", global_position, 2)
		pass
	
	await get_tree().create_timer(1).timeout
	stop_process = false
	pass
