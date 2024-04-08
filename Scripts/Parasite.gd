extends CharacterBody3D

const WALKING_SPEED = 3.0
const RUNNING_SPEED = 25.0

var speed : float
var health := 10
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#State Machine
var state_machine
enum states {IDLE, WALKING, CHASING, ATTACKING, DEATH}
var current_state =  states.IDLE
@onready var animation_tree = $AnimationTree
@onready var nav = $NavigationAgent3D as NavigationAgent3D
@onready var ray = $RayCast3D
@onready var armature = $RootNode
@onready var move_timer = $MoveTimer
@onready var player = $"../Player"

@onready var vision = $RootNode/Node3D/Vision
@onready var hearing_low = $RootNode/Node3D/HearingLow
@onready var hearing_high = $RootNode/Node3D/HearingHigh
@onready var lost = $RootNode/Node3D/Lost
@onready var vision_line = $VisionLine

var player_in_range = false
var lost_player = false

func _ready():
	randomize()
	state_machine = animation_tree.get("parameters/playback")
	speed = 0
	
func change_state(state):
	match state:
		states.IDLE:
			current_state = states.IDLE
			state_machine.travel("Idle")
			speed = 0.00001
			move_timer.start()
		states.WALKING:
			current_state = states.WALKING
			state_machine.travel("Walking")
			speed = WALKING_SPEED
			nav.max_speed = speed
		states.CHASING:
			current_state = states.CHASING
			state_machine.travel("Chasing")
			speed = RUNNING_SPEED
			nav.max_speed = speed
			move_to(player.global_position)
			move_timer.stop()
		states.ATTACKING:
			vision.monitoring = false
			hearing_low.monitoring = false
			hearing_high.monitoring = false
			player.caught = true
			player.look_at(global_position)
			await get_tree().create_timer(0.5).timeout
			current_state = states.ATTACKING
			state_machine.travel("Attacking")
			speed = 0.00001
		states.DEATH:
			current_state = states.DEATH
			state_machine.travel("Death")
			speed = 0.0

func _process(delta):
	if(current_state != states.CHASING):
		if _check_ray_to_player():
			change_state(states.CHASING)
	if(current_state == states.CHASING):
		if lost_player:
			if !_check_ray_to_player():
				change_state(states.IDLE)
				

func _check_ray_to_player():
	if player_in_range:
		vision_line.target_position = player.global_position - armature.global_position
		add_child(vision_line)
		if vision_line.is_colliding():
			if(vision_line.get_collider().is_in_group("player")):
				lost_player = false
				return true
		

func _physics_process(delta):
	var target = nav.get_next_path_position()
	var pos = global_transform.origin
	var normal = ray.get_collision_normal()
	
	if current_state == states.CHASING:
		move_to(player.global_position)
		
	print(current_state)
	if(global_position.distance_to(player.global_position) <= 5):
		change_state(states.ATTACKING)
		
	if normal.length_squared() < 0.001:
		normal = Vector3(0,1,0)
	
	velocity = (target - pos).slide(normal).normalized() * speed
	armature.rotation.y = lerp_angle(armature.rotation.y, atan2(velocity.x, velocity.z), delta * 10)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	_rotate_step_up_separation_ray()
	move_and_slide()
	
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

func move_to(target_pos):
	var closest_pos = NavigationServer3D.map_get_closest_point(get_world_3d().get_navigation_map(), target_pos)
	nav.set_target_position(closest_pos)

func get_random_position_in_sphere (radius : float) -> Vector3:
	var x1 = randi_range(-1, 1)
	var x2 = randi_range(-1, 1)
	
	while x1*x1 + x2*x2 >= 1:
		x1 = randi_range(-1, 1)
		x2 = randi_range(-1, 1)
	var random_pos_on_unit_sphere = Vector3(
		1 - 2 * (x1*x1 + x2*x2),
		0,
		1 - 2 * (x1*x1 + x2*x2)
	)
	
	random_pos_on_unit_sphere.x = global_position.x
	random_pos_on_unit_sphere.z = global_position.z
	
	random_pos_on_unit_sphere.x *= randi_range(-radius, radius)
	random_pos_on_unit_sphere.z *= randi_range(-radius, radius)
	
	return random_pos_on_unit_sphere

func _on_body_part_hit(damage):
	health -= damage
	if health <= 0:
		queue_free()

func _on_navigation_agent_3d_navigation_finished():
	if(current_state == states.WALKING):
		change_state(states.IDLE)
		move_timer.start()

func _on_move_timer_timeout():
	var sphere_point = get_random_position_in_sphere(20)
	move_to(sphere_point)
	change_state(states.WALKING)

func _on_vision_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		print("Player in range: ", player_in_range)


func _on_vision_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		print("Player in range: ", player_in_range)


func _on_lost_body_exited(body):
	if body.is_in_group("player"):
		lost_player = true
