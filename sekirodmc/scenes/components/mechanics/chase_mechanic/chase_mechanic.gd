extends Node2D

@export var chase_speed = 0
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var parent = null
var attack_distance = 0
var offset = Vector2(0,-30)

func init(data):
	parent = data.parent
	chase_speed = data.chase_speed
	attack_distance = data.attack_distance
	pass

func _ready():
	nav_agent.velocity_computed.connect(_on_nav_velocity_computed)
	pass

func _physics_process(delta):
	nav_agent.set_velocity(Vector2.ZERO)
	handle_chase()
	pass

func handle_chase():
	if !parent or !parent.player: return
	if parent.state != parent.CHASE: return
	if parent.stop_process: return
	
	if nav_agent.target_position != parent.player.global_position:
		nav_agent.set_target_position(parent.player.global_position)

	if nav_agent.is_navigation_finished():
		parent.velocity = Vector2.ZERO
	else:
		var next_point = nav_agent.get_next_path_position()
		var direction = sign(next_point.x - parent.global_position.x)
		parent.set_direction(direction)
		var new_velocity = (next_point - parent.global_position + offset).normalized() * chase_speed
		
		if nav_agent.avoidance_enabled:
			nav_agent.set_velocity(new_velocity)
		else:
			_on_nav_velocity_computed(new_velocity)
	pass

func _on_nav_velocity_computed(suggested_velocity: Vector2):
	parent.velocity = suggested_velocity.normalized() * chase_speed
	parent.move_and_slide()
