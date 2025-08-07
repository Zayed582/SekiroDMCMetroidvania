extends Area2D

var parent = null

func init(data):
	parent = data.parent
	pass

func _on_area_entered(area):
	if area.get("damage"): parent.take_damage(global_position, area.damage)
	if area.get_parent().has_method("_destroy"): area.get_parent()._destroy()
	
	if area.is_in_group("projectile"):
		parent.take_damage(global_position, area.damage)
		area.queue_free()
	pass # Replace with function body.
