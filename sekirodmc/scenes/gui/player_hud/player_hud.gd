extends MarginContainer


@onready var health_bar = $Sprite2D/HealthBar
@onready var mana_bar = $Sprite2D/ManaBar
@onready var stamina_bar = $Sprite2D/StaminaBar

func set_health(value):
	health_bar.value = value
	pass

func set_max_health(value):
	health_bar.max_value = value
	health_bar.value = value
	pass

func set_mana(value):
	mana_bar.value = value
	pass

func set_max_mana(value):
	mana_bar.max_value = value
	mana_bar.value = value
	pass

func set_stamina(value):
	stamina_bar.value = value
	pass

func set_max_stamina(value):
	stamina_bar.max_value = value
	stamina_bar.value = value
	pass
