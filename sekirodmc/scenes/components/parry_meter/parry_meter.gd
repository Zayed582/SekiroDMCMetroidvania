extends Node2D

@export var max_amount = 2
@onready var progress_bar = $ProgressBar
@onready var stun_sprite = $StunSprite
@onready var cooldown_timer = $CooldownTimer 

@onready var delay_value = DEFAULT_DELAY_VALUE
@onready var decay_value = DEFAULT_DECAY_VALUE

var sender = null

const ACTIVE_PARRY_DELAY_VALUE = 1.0
const ACTIVE_PARRY_DECAY_VALUE = 0.05
const DEFAULT_DELAY_VALUE = 1.0
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
	if progress_bar.value <= 0.01 and progress_bar.visible:
		progress_bar.value = 0
		progress_bar.visible = false
		pass
	
func set_parry_details(_amount, _sender):
	show()
	sender = _sender
	progress_bar.value += _amount
	decay_value = DEFAULT_DECAY_VALUE
	
	set_process(false)
	if progress_bar.value >= progress_bar.max_value:
		if !GameManager.parriable_enemies.has(sender):
			GameManager.parriable_enemies.append(sender)
		delay_value = ACTIVE_PARRY_DELAY_VALUE
		can_parry = true
		stun_sender()
	cooldown_timer.start(delay_value)
	pass

func stun_sender():
	sender.stop_process = true
	show_stun_sprite()
	await get_tree().create_timer(1).timeout
	hide_stun_sprite()
	progress_bar.visible = false
	sender.stop_process = false
	pass

func show_stun_sprite():
	progress_bar.hide()
	stun_sprite.show()
	pass

func hide_stun_sprite():
	#hide()
	progress_bar.show()
	stun_sprite.hide()
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
