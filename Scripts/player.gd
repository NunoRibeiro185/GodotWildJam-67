extends CharacterBody3D


var speed = 0.0
var jump_speed = 30
var mouse_sensitivity = 0.002

@onready var camera = $Head/Camera3D
@onready var flashlight = $Head/Camera3D/Lemon/Flashlight
@onready var animation_player = $AnimationPlayer
@onready var lemon = $Head/Camera3D/Lemon

const WALK_SPEED = 15.0
const SPRINT_SPEED = 25.0
const CROUCH_SPEED = 5.0

var _is_crouching = false

#Bob Variable
const BOB_FREQ = 0.7
const BOB_AMP = 0.20
var t_bob = 0.0

#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.fov = BASE_FOV
	
func _physics_process(delta):
	velocity.y += -gravity * delta
	
	#if is_on_floor() and Input.is_action_just_pressed("jump"):
		#velocity.y = jump_speed
	
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = !flashlight.visible
	
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
		if _is_crouching:
			toggle_crouch()
	else:
		speed = WALK_SPEED
	
	if _is_crouching:
		speed = CROUCH_SPEED
		
	var input = Input.get_vector("left", "right", "forward", "back")
	var movement_dir = transform.basis * Vector3(input.x, 0, input.y)
	velocity.x = movement_dir.x * speed
	velocity.z = movement_dir.z * speed
	
	_rotate_step_up_separation_ray()
	move_and_slide()
	_snap_down_the_stairs()
	_juice_camera(delta)
	
func _juice_camera(delta):
	#bobbing
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	#FOV
	var velocity_clamped = clamp(velocity.length(), WALK_SPEED - 3, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
func _headbob(time):
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ/2) * BOB_AMP
	return pos

#region Stairs
var _was_on_floor_last_frame = false
var _snapped_to_stairs_last_frame = false
@onready var step_down = $Step_Down
func _snap_down_the_stairs():
	var did_snap = false
	if not is_on_floor() and velocity.y <= 0 and (_was_on_floor_last_frame or _snapped_to_stairs_last_frame) and step_down.is_colliding():
		var body_test_result = PhysicsTestMotionResult3D.new()
		var params = PhysicsTestMotionParameters3D.new()
		var max_step_down = -4.5
		params.from = self.global_transform
		params.motion = Vector3(0, max_step_down, 0)
		if PhysicsServer3D.body_test_motion(self.get_rid(), params, body_test_result):
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true
			
	_was_on_floor_last_frame = is_on_floor()
	_snapped_to_stairs_last_frame = did_snap

@onready var stairs_collision_shape = $StairsCollisionShape
@onready var stairs_collision_shape_r = $StairsCollisionShape_R
@onready var stairs_collision_shape_l = $StairsCollisionShape_L
@onready var initial_stair_collision_shape_dist = abs(stairs_collision_shape.position.z)

@onready var ray_cast_3d_f = $StairsCollisionShape/RayCast3D
@onready var ray_cast_3d_l = $StairsCollisionShape_L/RayCast3D
@onready var ray_cast_3d_r = $StairsCollisionShape_R/RayCast3D

var _last_xz_vel : Vector3 = Vector3(0,0,0)

func _rotate_step_up_separation_ray():

	var xz_vel = velocity * Vector3(1,0,1)
	
	if xz_vel.length() < 1.0:
		xz_vel = _last_xz_vel
	else:
		_last_xz_vel = xz_vel
	
	var xz_f_ray_pos = xz_vel.normalized() * initial_stair_collision_shape_dist
	stairs_collision_shape.global_position.x = self.global_position.x + xz_f_ray_pos.x
	stairs_collision_shape.global_position.z = self.global_position.z + xz_f_ray_pos.z
	
	var xz_l_ray_pos = xz_f_ray_pos.rotated(Vector3(0,1.0,0), deg_to_rad(-50))
	stairs_collision_shape_l.global_position.x = self.global_position.x + xz_l_ray_pos.x
	stairs_collision_shape_l.global_position.z = self.global_position.z + xz_l_ray_pos.z
	
	var xz_r_ray_pos = xz_f_ray_pos.rotated(Vector3(0,1.0,0), deg_to_rad(50))
	stairs_collision_shape_r.global_position.x = self.global_position.x + xz_r_ray_pos.x
	stairs_collision_shape_r.global_position.z = self.global_position.z + xz_r_ray_pos.z
	
	ray_cast_3d_f.force_raycast_update()
	ray_cast_3d_l.force_raycast_update()
	ray_cast_3d_r.force_raycast_update()
	var max_slope_ang_dot = Vector3(0,1,0).rotated(Vector3(1.0,0,0), self.floor_max_angle).dot(Vector3(0,1,0))
	var any_too_steep = false
	if ray_cast_3d_f.is_colliding() and ray_cast_3d_f.get_collision_normal().dot(Vector3(0,1,0)) < max_slope_ang_dot:
		any_too_steep = true
	if ray_cast_3d_l.is_colliding() and ray_cast_3d_l.get_collision_normal().dot(Vector3(0,1,0)) < max_slope_ang_dot:
		any_too_steep = true
	if ray_cast_3d_r.is_colliding() and ray_cast_3d_r.get_collision_normal().dot(Vector3(0,1,0)) < max_slope_ang_dot:
		any_too_steep = true
	
	stairs_collision_shape.disabled = any_too_steep
	stairs_collision_shape_l.disabled = any_too_steep
	stairs_collision_shape_r.disabled = any_too_steep
#endregion

func toggle_crouch():
	if _is_crouching:
		print("UNCROUCH")
		animation_player.play("Crouch", -1, -CROUCH_SPEED, true)
	elif !_is_crouching:
		print("CROUCH")
		animation_player.play("Crouch", -1, CROUCH_SPEED)
	_is_crouching = !_is_crouching

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x, -deg_to_rad(70), deg_to_rad(70))
	
	if Input.is_action_just_pressed("crouch"):
		toggle_crouch()
		
	if Input.is_action_just_pressed("shoot"):
		lemon.shoot()
