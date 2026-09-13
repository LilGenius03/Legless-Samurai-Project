extends Area3D

var activated := false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if activated:
		return
	
	if body is CharacterBody3D:
		activated = true
		body.slice_point_hit(self)
