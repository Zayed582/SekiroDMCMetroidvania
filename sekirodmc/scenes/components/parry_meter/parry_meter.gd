extends Node2D

@export var max_amount = 2
@onready var progress_bar = $ProgressBar
@onready var cooldown_timer =$CooldownTimer 

@onready var delay_value = DEFAULT_DELAY_VALUE
@onready var decay_value = DEFAULT_DECAY_VALUE

var sender = null

const ACTIVE_PARRY_DELAY_VALUE = 4.0
const ACTIVE_PARRY_DECAY_VALUE = 0.1
const DEFAULT_DELAY_VALUE = 2.0
const DEFAULT_DECAY_VALUE = 0.006

var can_parry = false

func _ready():
	progress_bar.max_value = max_amount
	GameManager.connect("clear_parrys", clear_parry)
	pass

func init(details):
	sender = details.parent
	pass

func _process(delta):
	progress_bar.value = move_toward(progress_bar.value, 0.0, decay_value)

func set_parry_details(_amount, _sender):
	sender = _sender
	progress_bar.value += _amount
	decay_value = DEFAULT_DECAY_VALUE
	
	set_process(false)
	if progress_bar.value >= progress_bar.max_value:
		if !GameManager.parriable_enemies.has(sender):
			GameManager.parriable_enemies.append(sender)
		delay_value = ACTIVE_PARRY_DELAY_VALUE
		can_parry = true
	cooldown_timer.start(delay_value)
	pass

func clear_parry():
	delay_value = DEFAULT_DELAY_VALUE
	decay_value = ACTIVE_PARRY_DECAY_VALUE
	can_parry = false
	if GameManager.parriable_enemies.has(sender):
		GameManager.parriable_enemies.erase(sender)
	
	set_process(true)
	pass

func _on_cooldown_timer_timeout():
	if can_parry:
		clear_parry()
	set_process(true)
	pass # Replace with function body.
