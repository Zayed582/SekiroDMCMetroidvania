extends MarginContainer


@onready var health_bar = $ColorRect/VBoxContainer/HealthBar
@onready var mana_bar = $ColorRect/VBoxContainer/ManaBar
@onready var stamina_bar = $ColorRect/VBoxContainer/StaminaBar
@onready var mana_progress_bar = $ColorRect/VBoxContainer/ManaBar/ManaBar2

func _ready():
	GameManager.connect("set_health", _on_set_health)
	GameManager.connect("set_mana", _on_set_mana)
	GameManager.connect("set_stamina", _on_set_stamina)
	GameManager.connect("set_mana_progress", _on_set_mana_progress)
	GameManager.connect("set_max_health", _on_set_max_health)
	GameManager.connect("set_max_mana", _on_set_max_mana)
	GameManager.connect("set_max_stamina", _on_set_max_stamina)
	pass

func _on_set_health(value):
	health_bar.value = value
	print("health value", value)
	pass

func _on_set_max_health(value):
	health_bar.max_value = value
	health_bar.value = value
	print("max value", value)
	pass

func _on_set_mana(value):
	mana_bar.value = value
	pass

func _on_set_mana_progress(value):
	mana_progress_bar.value = value
	pass

func _on_set_max_mana(value):
	mana_bar.max_value = value
	mana_bar.value = value
	mana_progress_bar.max_value = value
	mana_progress_bar.value = value
	pass

func _on_set_stamina(value):
	stamina_bar.value = value
	pass

func _on_set_max_stamina(value):
	stamina_bar.max_value = value
	stamina_bar.value = value
	pass
