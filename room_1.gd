extends Node2D

func _ready():
	await get_tree().process_frame

	if Global.last_spawn_name != "":
		var spawn = get_node_or_null(Global.last_spawn_name)
		if spawn:
			get_node("Player").global_position = spawn.global_position
