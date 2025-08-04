extends AirBaseEnemy

@export_category("BaseEnemy")

#EXPORTS
@export_subgroup("Health")
@export var max_health: int = 3
@export var current_health: int = 3

@export_subgroup("Physics")
@export var chase_speed: float = 140.0
@export var patrol_speed: float = 120.0
@export var attack_distance: float = 30.0

@export_subgroup("Detectors")
@export var player_detector_area: PackedScene

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

#SIGNALS
signal take_damage(damage_value)

#NODES
@onready var animation_player: AnimationPlayer = $Animation/AnimationPlayer
@onready var state_machine = $Animation/AnimationTree.get("parameters/playback")
@onready var sprite = $Sprite2D

#NODES
var death_audio = null
var hurt_audio = null
var hit_audio = null
var hit_box_node = null

#PLAYER
var player = null

#PROCESS
var stop_process = false

#CONDITION
var is_on_edge = false

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
		var attack_mechanic_node = add_node(attack_mechanic)
		attack_mechanic_node.init({
			"parent": self
		})
	if parol_mechanic:
		var parol_mechanic_node = add_node(parol_mechanic)
		parol_mechanic_node.init({
			"parent": self,
			"patrol_speed": patrol_speed
		})
	pass

func init_signals():
	connect("take_damage", _on_take_damage)
	pass

#func _physics_process(delta):


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

func _on_take_damage(amount: int) -> void:
	current_health -= amount
	velocity.x = 0
	if current_health <= 0:
		stop_process = true
		state_machine.start("die")
		if death_audio: 
			death_audio.play()
	else:
		temporarily_disable_movement()
		state_machine.travel("hurt")
		if hurt_audio: hurt_audio.play()

func temporarily_disable_movement():
	stop_process = true
	await get_tree().create_timer(0.4).timeout
	stop_process = false
	pass

func start_attack():
	if !hit_box_node: return
	
	hit_box_node.monitoring = true
	await get_tree().create_timer(0.2).timeout
	hit_box_node.monitoring = false
	pass

func travel(state_name):
	state_machine.travel(state_name)
	pass

func set_direction(dir = null) -> void:
	
	if !dir:
		if player.position.x > position.x:
			dir = 1
		elif player.position.x < position.x:
			dir = -1
	print("Direction: ", dir)
	sprite.flip_h = dir > 0
