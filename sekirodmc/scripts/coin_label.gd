extends Label

func _ready():
	GameManager.connect("add_coin", _on_add_coin)
	_on_add_coin()
	pass


func _on_add_coin():
	text = str(GameManager.coins)
	pass 
