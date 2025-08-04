extends Node2D

@export var airborne = false
@onready var patrol_cooldown_timer = $Timer
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var parent = null
var patrol_target = Vector2.ZERO
var patrol_speed = 100

const PATROL_MAX_DISTANCE = 1000
const PATROL_MIN_DISTANCE = 100

func _ready():
	nav_agent.velocity_computed.connect(_on_nav_velocity_computed)
	pass

func init(data):
	parent = data.parent
	patrol_speed = data.patrol_speed
	pass


func _physics_process(delta):
	handle_patrol()
	pass

func handle_patrol():
	if parent.stop_process: return
	if parent.is_on_edge: return

	if parent.state == parent.IDLE and patrol_cooldown_timer.is_stopped():
		parent.travel("patrol")
		patrol_cooldown_timer.start()
		print("Patrol - Generating Patrol point")
	
	if parent.state != parent.PATROL: return
	
	if nav_agent.target_position != patrol_target:
		nav_agent.set_target_position(patrol_target)

	if nav_agent.is_navigation_finished():
		parent.velocity = Vector2.ZERO
		parent.set_state(parent.IDLE)
	else:
		var next_point = nav_agent.get_next_path_position()
		var new_velocity = (next_point - parent.global_position).normalized() * patrol_speed
		
		if nav_agent.avoidance_enabled:
			nav_agent.set_velocity(new_velocity)
		else:
			_on_nav_velocity_computed(new_velocity)
	
	await nav_agent.path_changed
	
	if !nav_agent.is_target_reachable():
		parent.set_state(parent.IDLE)
	pass

func _on_nav_velocity_computed(suggested_velocity: Vector2):
	parent.velocity = suggested_velocity.normalized() * patrol_speed
	parent.move_and_slide()

func generate_patrol_target():
	randomize()
	var rand_vec = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	var rand_x = randi_range(PATROL_MIN_DISTANCE,PATROL_MAX_DISTANCE) * rand_vec.x
	var rand_y = randi_range(PATROL_MIN_DISTANCE,PATROL_MAX_DISTANCE) * rand_vec.y
	
	var distance = Vector2.ZERO
	
	if airborne:
		distance = Vector2(rand_x, rand_y)
	else:
		distance = Vector2(rand_x, 0)
	patrol_target = parent.global_position + distance
	pass

func check_if_stucked():
	#if stuck reroute
	pass


func _on_timer_timeout():
	if parent.state != parent.IDLE: return
	generate_patrol_target()
	parent.set_state(parent.PATROL)
	parent.set_direction(sign(patrol_target.x - parent.global_position.x))
	print("Patrolling...")
	pass # Replace with function body.
