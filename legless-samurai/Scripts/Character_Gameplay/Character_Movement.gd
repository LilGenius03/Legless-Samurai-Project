extends CharacterBody3D

enum State {
IDLE, 
AIMING,
LAUNCHING,
BLOCKING, 
PARRYING, 
STUNNED
}
var current_state: State = State.IDLE
var aim_direction: Vector3 = Vector3.ZERO
var aim_target_position: Vector3 = Vector3.ZERO
# 1 = facing +Z -1 = facing -Z
var facing_direction := 1

const AIM_FLIP_DEAD_ZONE:= 0.05
var original_visual_rotation_y := 0.0

var launch_direction: Vector3 = Vector3.ZERO
var launch_speed: float = 0.0

var slice_window_timer := 0.0
var saved_velocity: Vector3 = Vector3.ZERO

var can_midair_slice := false

@export var max_pull_distance := 5.0
@export var max_launch_speed := 20.0
@export var gravity := 25.0

@export var slice_window_duration := 0.5
@export var slice_slowdown := 0.5

@onready var animation_tree = $AnimationTree_Legless_Samurai
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

@onready var aim_visual: Node3D = $Aim_Visual
@onready var aim_cylinder: MeshInstance3D = $Aim_Visual/Aim_Cylinder

@export var aim_target: Node3D
@export var aim_debug_marker: Marker3D

#@onready var Bone_Target: ModifierBoneTarget3D = $"Legless Samurai Test_Armature/Skeleton3D/ModifierBoneTarget3D"
@onready var ik_target: Node3D = $"Legless Samurai Test_Armature/Skeleton3D/IK_Target"
@onready var look_at_modifier: LookAtModifier3D = ($"Legless Samurai Test_Armature/Skeleton3D/LookAtModifier3D")
@onready var arm_ik: TwoBoneIK3D = ($"Legless Samurai Test_Armature/Skeleton3D/TwoBoneIK3D")
@onready var visual_root: Node3D = $"Legless Samurai Test_Armature/Skeleton3D"

func _ready() -> void:
	animation_tree.active = true
	state_machine.travel("Idle Animation Test")
	original_visual_rotation_y = visual_root.rotation.y


func _physics_process(_delta: float) -> void:
	
	match current_state:
		State.IDLE:
			_handle_idle()

		State.AIMING:
			_handle_aiming(_delta)

		State.LAUNCHING:
			_handle_launching(_delta)
	

		State.BLOCKING:
			_handle_blocking()

		State.PARRYING:
			_handle_parrying()

		State.STUNNED:
			_handle_stunned()
	pass

func _handle_idle() -> void:
	if Input.is_action_pressed("Aiming"):
		_enter_aiming()
	pass

func _handle_aiming(delta: float) -> void:
	if not Input.is_action_pressed("Aiming"):
		_launch_samurai()
		return
	
	_update_aim_target()
	_check_aim_direction()
	_update_ik_target()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		move_and_slide()
	pass

func _enter_aiming() -> void:
	current_state = State.AIMING
	aim_visual.visible = true
	look_at_modifier.influence = 0.0
	arm_ik.influence = 1.0
	state_machine.travel("Aiming_Animation_Right")
	
	#This will be the code for the real character model
	
	#if facing_direction == 1:
		#state_machine.travel("Aiming_Animation_Right")
	#else:
		#state_machine.travel("Aiming_Animation_Right")


func _exit_aiming() -> void:
	current_state = State.IDLE
	aim_direction = Vector3.ZERO
	arm_ik.influence = 0.0
	look_at_modifier.influence = 0.0
	
	state_machine.travel("Idle Animation Test")

func _check_aim_direction() -> void:
	var world_offset := aim_target_position - global_position

	if facing_direction == 1:
		if world_offset.z < -AIM_FLIP_DEAD_ZONE:
			_flip_facing()
	elif facing_direction == -1:
		if world_offset.z > AIM_FLIP_DEAD_ZONE:
			_flip_facing()
		
	

func _flip_facing() -> void:
	facing_direction *= -1

	if facing_direction == 1:
		visual_root.rotation.y = original_visual_rotation_y
	else:
		visual_root.rotation.y = original_visual_rotation_y + PI
	

func _update_ik_target() -> void:
	
	# aim_direction points from the Samurai toward the mouse.
	# We want the IK to point in the opposite direction.
	var launch_aim_direction := -aim_direction
	
	# Keep aiming on the Y/Z gameplay plane.
	launch_aim_direction.x = 0.0
	
	if launch_aim_direction.length() <= 0.01:
		return
	
	launch_aim_direction = launch_aim_direction.normalized()
	
	# Place the IK target in front of the Samurai
	# in the direction he is going to launch.
	ik_target.global_position = (global_position + launch_aim_direction * 2.0)

func _handle_launching(delta: float) -> void:
	
	if slice_window_timer > 0.0:
		slice_window_timer -= delta
		var slowed_velocity := launch_direction * launch_speed * slice_slowdown
		
		velocity.z = slowed_velocity.z
	
	else:
		velocity.z = launch_direction.z * launch_speed
	
	velocity.y -= gravity * delta
	
	move_and_slide()
	
	if can_midair_slice and Input.is_action_pressed("Aiming"):
		_enter_aiming()
		return
	
	if is_on_floor() and velocity.y <= 0.0:
		velocity = Vector3.ZERO
		can_midair_slice = false
		current_state = State.IDLE
	

func _handle_blocking():
	if Input.is_action_pressed("Blocking"):
		print("blocking")
		
	

func _get_pull_strength() -> float:
	var pull_distance := global_position.distance_to(aim_target_position)
	var pull_strength := pull_distance / max_pull_distance
	
	return clamp(pull_strength, 0.0, 1.0)
	

func _launch_samurai() -> void:
	current_state = State.LAUNCHING
	aim_visual.visible = false
	
	can_midair_slice = false
	
	var pull_strength := _get_pull_strength()
	
	#The mouse direction is the direction we pulled.
	#Launch the opposite direction we pulled.
	launch_direction = -aim_direction
	
	#keep it 2.5D.
	launch_direction.x = 0.0
	launch_direction = launch_direction.normalized()
	
	launch_speed = max_launch_speed * pull_strength
	velocity = launch_direction * launch_speed
	


func _handle_parrying():
	print("parrying")

func _handle_stunned():
	print("stunned")

func _update_aim_target() -> void:
	
	var camera := get_viewport().get_camera_3d()
	
	if camera == null:
		return
	
	
	var mouse_position := get_viewport().get_mouse_position()
	
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_direction := camera.project_ray_normal(mouse_position)
	
	if abs(ray_direction.x) < 0.001:
		return

	var distance := (global_position.x - ray_origin.x) / ray_direction.x

	aim_target_position = ray_origin + ray_direction * distance
	
	aim_target.global_position = aim_target_position
	aim_debug_marker.global_position = aim_target_position
	
	aim_direction = (
		aim_target_position - global_position
	).normalized()
	
	_update_aim_visual()

func _update_aim_visual() -> void:
	var start_position := global_position
	var end_position := aim_target_position
	
	var direction := end_position - start_position
	var distance := direction.length()
	
	if distance <= 0.01:
		aim_visual.visible = false
		return
	
	aim_visual.visible = true
	
	#Visual halfway between the Samurai and the Aim Target
	aim_visual.global_position = ( start_position + end_position) / 2.0
	
	#Point aim visual towards the Aim Target.
	aim_visual.look_at(end_position, Vector3.UP)
	
	aim_cylinder.scale = Vector3(0.03, distance, 0.03)

func slice_point_hit(_slice_point: Area3D) -> void:
	print("SAMURAI RECEIVED SLICE POINT")
	
	can_midair_slice = true
	
	slice_window_timer = slice_window_duration
	
	saved_velocity = velocity
