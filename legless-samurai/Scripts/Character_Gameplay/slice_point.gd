extends Area3D

var activated := false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(_on_area_entered)





func _on_area_entered(area: Area3D) -> void:
	if activated:
		return

	if not area.is_in_group("sword_hitbox"):
		return

	activated = true

	var samurai := area.get_parent()

	while samurai != null:

		if samurai.is_in_group("LS_Samurai"):
			if samurai.has_method("slice_point_hit"):
				samurai.slice_point_hit(self)
			return

		samurai = samurai.get_parent()
		
