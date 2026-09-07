extends CharacterBody3D

enum State {
IDLE, 
AIMING, 
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

@onready var animation_tree = $AnimationTree_Legless_Samurai
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

@export var aim_target: Node3D
@export var aim_debug_marker: Marker3D

#@onready var Bone_Target: ModifierBoneTarget3D = $"Legless Samurai Test_Armature/Skeleton3D/ModifierBoneTarget3D"
@onready var look_at_modifier: LookAtModifier3D = ($"Legless Samurai Test_Armature/Skeleton3D/LookAtModifier3D")
@onready var arm_ik: TwoBoneIK3D = ($"Legless Samurai Test_Armature/Skeleton3D/TwoBoneIK3D")

func _ready() -> void:
	animation_tree.active = true
	state_machine.travel("Idle Animation Test")
	#state_machine.travel("Aiming_Animation_Right")

func _physics_process(_delta: float) -> void:
	
	match current_state:
		State.IDLE:
			_handle_idle()

		State.AIMING:
			_handle_aiming()

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

func _handle_aiming() -> void:
	if not Input.is_action_pressed("Aiming"):
		_exit_aiming()
		return
	
	_update_aim_target()
	_check_aim_direction()
	pass

func _enter_aiming() -> void:
	current_state = State.AIMING
	
	look_at_modifier.influence = 1.0
	arm_ik.influence = 1.0
	state_machine.travel("Aiming_Animation_Right")
	#var condition_active = animation_tree.get("parameters/conditions/is_aiming")
	#print("Condition 'is_aiming' is: ", condition_active)

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
	rotation.y += PI
	

func _handle_blocking():
	if Input.is_action_pressed("Blocking"):
		print("blocking")
	

func _handle_parrying():
	print("parrying")

func _handle_stunned():
	print("stunned")

func _update_aim_target():
	
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

	
	#Bone_Target.global_position = (
		#global_position
		#+ aim_direction * 2.0
	#)
