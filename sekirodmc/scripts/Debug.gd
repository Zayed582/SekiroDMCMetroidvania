extends MarginContainer

@onready var state_label = $HBoxContainer/VBoxContainer/PlayerLabel2

var states = [
	"IDLE",
	"RUN",
	"SPRINT",
	"JUMP",
	"ATTACK",
	"ATTACK 2",
	"ATTACK 3",
	"PARRY",
	"BLOCK",
	"BLOCK_HIT",
	"CAN_PARRY"
]

func _ready():
	GameManager.connect("update_player_debug_state", update_player_debug_state)
	pass

func update_player_debug_state(text):
	update_state_label(text)
	pass

func update_state_label(current_state):
	var text := ""
	for i in states.size():
		var state = states[i]
		if state == current_state:
			text += "[b][color=black]%s[/color][/b]" % state
		else:
			text += state
		if i < states.size() - 1:
			text += " → "
	state_label.text = text
