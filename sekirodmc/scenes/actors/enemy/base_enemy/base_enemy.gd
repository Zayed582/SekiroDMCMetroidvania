class_name BaseEnemy extends CharacterBody2D

#EXPORTS
@export_subgroup("Health")
@export var max_health: int = 3
@export var health: int = 3

@export_subgroup("Variables")
@export var damage = 1
@export var knockback_force := 300.0
@export var knockback_duration := 0.2

@export_subgroup("Physics")
@export var chase_speed: float = 140.0
@export var patrol_speed: float = 120.0
@export var attack_distance: float = 30.0

@export_subgroup("Detectors")
@export var player_detector_area: PackedScene
@export var edge_detector: PackedScene

@export_group("Mechanics")
@export var chase_mechanic: PackedScene
@export var attack_mechanic: PackedScene
@export var parol_mechanic: PackedScene

@export_group("Animations")
@export_subgroup("Hit")
@export var hit_box: PackedScene
@export var hit_sound: AudioStream

@export_subgroup("Hurt")
@export var hurt_box: PackedScene
@export var hurt_sound: AudioStream

@export_subgroup("Die")
@export var die_sound: AudioStream

@export_subgroup("Conditions")
@export var has_navigation = false

@export_subgroup("Toggles")
@export var has_wall_detection = false
@export var has_gravity = false

#NODES
@onready var animation_container = $Animation
@onready var state_machine = $Animation/AnimationTree.get("parameters/playback")
@onready var sprite = $Sprite2D

#VARIABLES
var death_audio = null
var hurt_audio = null
var hit_audio = null
var hit_box_node = null
var hurt_box_node: Area2D = null
var edge_detector_node = null
var player = null
var stop_process = false
var is_on_edge = false
var attack_mechanic_node: Area2D = null


#KNOCKBACK
var knockback_decay: float = 800.0
var knockback_strength = 200

var knockback_timer := 0.0
var is_knockback := false
var knockback_velocity := Vector2.ZERO

#PHYSICS
const GRAVITY = 10000
var direction = 0

enum {
	IDLE,
	CHASE,
	ATTACK,
	PATROL,
	JUMP,
	ON_EDGE,
	HURT,
	DEAD
}
var state = null

#SIGNALS
#signal take_damage(damage_value)

func _ready():
	init_dependencies()
	init_signals()
	pass


func init_dependencies():
	if hit_box:
		hit_box_node = add_node(hit_box)
		hit_box_node.init({"damage": damage})
	if hurt_box:
		var hurt_node = add_node(hurt_box)
		hurt_node.init({"parent": self})
	if hit_sound:
		var sound_node = add_sound_node(hit_sound, { "volume_db": -2 })
		hit_audio = sound_node
	if die_sound:
		var sound_node = add_sound_node(die_sound, { "volume_db": -10 })
		death_audio = sound_node
	if hurt_sound:
		var sound_node = add_sound_node(hurt_sound, { "volume_db": -2 })
		hurt_audio = sound_node
	if player_detector_area:
		var player_detector = add_node(player_detector_area)
		player_detector.init({"parent": self})
	if chase_mechanic:
		var chase_mechanic_node = add_node(chase_mechanic)
		chase_mechanic_node.init({
			"parent": self, 
			"chase_speed": chase_speed,
			"attack_distance": attack_distance
		})
	if attack_mechanic:
		attack_mechanic_node = add_node(attack_mechanic)
		attack_mechanic_node.init({
			"parent": self
		})
	if parol_mechanic:
		var parol_mechanic_node = add_node(parol_mechanic)
		parol_mechanic_node.init({
			"parent": self,
			"patrol_speed": patrol_speed
		})
	if edge_detector:
		edge_detector_node = add_node(edge_detector)
		edge_detector_node.position = Vector2(0,40)
	pass

func init_signals():
	#connect("take_damage", _on_take_damage)
	pass

func _physics_process(delta):
	handle_gravity(delta)
	handle_knockback(delta)
	handle_flips()
	handle_wall_detection()
	if has_gravity: move_and_slide()


func add_node(scene: PackedScene):
	var child = scene.instantiate()
	add_child(child)
	return child

func add_sound_node(sound_stream, sound_settings = {}):
	var volume_db = sound_settings.volume_db
	if !volume_db: volume_db = 0
	
	var new_audio_stream = AudioStreamPlayer.new()
	new_audio_stream.stream = sound_stream
	new_audio_stream.volume_db = volume_db
	add_child(new_audio_stream)
	return new_audio_stream
	pass

func take_damage(pos, damage):
	if stop_process: return
	stop_process = true
	
	health -= damage
	apply_knockback(pos)
	GameManager.emit_signal("shake_camera",0.2, 4.0)
	GameManager.emit_signal("add_hit_particle", damage, global_position)
	#velocity.x = 0
	
	if health <= 0:
		silence_monitoring_node()
		state_machine.start("die")
		GameManager.emit_signal("spawn_coin", global_position, 2)
	else:
		temporarily_disable_movement()
		state_machine.travel("hurt")
		if hurt_audio: hurt_audio.play()
		pass
	pass

func temporarily_disable_movement():
	stop_process = true
	await get_tree().create_timer(0.4).timeout
	stop_process = false
	pass

func start_attack():
	if !hit_box_node: return
	
	hit_box_node.monitoring = true
	hit_box_node.monitorable = true
	await get_tree().create_timer(0.01).timeout
	hit_box_node.monitoring = false
	hit_box_node.monitorable = false
	pass

func travel(state_name):
	state_machine.travel(state_name)
	pass

func set_direction(dir) -> void:
	
	#if !dir:
		#if player.position.x > position.x:
			#dir = 1
		#elif PlayerManager.player.position.x < position.x:
			#dir = -1
	#print("Direction: ", dir)
	direction = dir
	animation_container.scale.x = dir
	sprite.flip_h = dir > 0

func apply_knockback(from_position: Vector2):
	var direction = (global_position - from_position).normalized()
	knockback_velocity = direction * knockback_force
	knockback_timer = knockback_duration
	is_knockback = true

func handle_knockback(delta):
	if is_knockback:
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_knockback = false
			knockback_velocity = Vector2.ZERO
		velocity = knockback_velocity
		floor_stop_on_slope = false
		move_and_slide()
	pass

func handle_parry(body):
	apply_knockback(body.global_position)
	pass

func set_state(_state):
	state = _state
	pass


func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	pass

func silence_monitoring_node(_bool = true):
	if hit_box_node: 
		hit_box_node.set_deferred("monitoring", !_bool)
		hit_box_node.set_deferred("monitorable", !_bool)
	if hurt_box_node: 
		hurt_box_node.set_deferred("monitoring", !_bool)
		hurt_box_node.set_deferred("monitorable", !_bool)
	pass

func handle_flips():
	if edge_detector_node: edge_detector_node.scale.x = direction
	pass

func handle_wall_detection():
	if is_on_wall() and is_on_floor():
		direction = -direction
	pass
