extends Camera3D
@export var player_target: NodePath
@export var offset = Vector3(-6.0, 0.5, 0.0)
@export var smooth_speed = 5.0

var _fixed_rotation: Vector3

func _ready():
	_fixed_rotation = rotation

func _process(delta):
	if player_target.is_empty():
		return

	var target: Node3D = get_node(player_target)
	if target == null:
		return

	var fixed_x = 0.0
	var target_pos = Vector3(fixed_x, target.global_position.y, target.global_position.z)

	var desired_position = target_pos + offset

	global_position = global_position.lerp(desired_position, smooth_speed * delta)

	global_rotation = _fixed_rotation
