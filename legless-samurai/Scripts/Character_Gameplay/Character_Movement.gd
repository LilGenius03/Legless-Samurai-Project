extends CharacterBody3D
var aim_direction: Vector3 = Vector3.ZERO
enum State {IDLE, AIMING, BLOCKING, PARRYING, STUNNED}
var current_state: State = State.IDLE


var is_aiming : bool
var is_blocking: bool
var is_parry_successful: bool
var is_stunned: bool
@onready var aim_raycast: RayCast3D = $Aiming_RayCast
@onready var animation_tree = $AnimationTree_Legless_Samurai
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

func _onready():
	animation_tree.active = true
	state_machine.travel("Idle Animation Test")
func _physics_process(delta):
	
	if current_state == State.IDLE:
		state_machine.travel("Idle Animation Test")
		if Input.is_action_pressed("Aiming"):
			current_state = State.AIMING
			_update_aim_raycast()
	
	elif current_state == State.AIMING:
		if not Input.is_action_pressed("Aiming"):
			current_state = State.IDLE
			aim_direction = Vector3.ZERO
	
	match current_state:
		State.IDLE:
			_handle_idle(delta)
		State.AIMING:
			_handle_aiming(delta)
	pass

func _handle_idle(_delta):
	print("idle")
	pass

func _handle_aiming(_detla):
	
	if not aim_raycast:
		print("AimRay is Missing!!!!!")
		return
	
	_update_aim_raycast()
	
	
	if aim_raycast.is_colliding():
		var hit_point = aim_raycast.get_collision_point()
		aim_direction = (hit_point - global_transform.origin).normalized()
	
	else:
		aim_direction = -global_transform.basis.z.normalized()
	
	pass
func _handle_blocking():
	if Input.is_action_pressed("Blocking") && !is_blocking:
		print("blocking")
		is_blocking = true

func _handle_parrying():
	print("parrying")

func _handle_stunned():
	print("stunned")

func _update_aim_raycast():
	if not aim_raycast:
		return
	
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	
	var ray_from = camera.project_ray_origin(mouse_pos)
	var ray_normal = camera.project_ray_normal(mouse_pos)
	
	var player_x = global_position.x
	
	if abs(ray_normal.x) < 0.001:
		return
	
	aim_raycast.global_position = global_position + Vector3(0,1,0)
	
	var distance = (player_x - ray_from.x) / ray_normal.x
	var target_point = ray_from + (ray_normal * distance)
	
	aim_raycast.global_position = global_position + Vector3(0, 1, 0)
	
	var direction = target_point - aim_raycast.global_position
	
	direction.x = 0 
	aim_raycast.target_position = direction.normalized() * 10.0
