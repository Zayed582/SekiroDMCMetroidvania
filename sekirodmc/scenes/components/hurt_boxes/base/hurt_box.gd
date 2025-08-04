extends Area2D

var parent = null

func init(data):
	parent = data.parent
	pass

func _on_area_entered(area):
	if area.damage: parent.emit_signal("take_damage", area.damage)
	if area.get_parent().has_method("_destroy"): area.get_parent()._destroy()
	pass # Replace with function body.
