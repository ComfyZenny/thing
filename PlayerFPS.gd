extends CharacterBody3D

var cmd = {
	forward_move 	= 0.0,
	right_move 		= 0.0,
	up_move 		= 0.0
}

@export var x_mouse_sensitivity = .05
@export var y_mouse_sensitivity = .05
@export var gravity = 32
@export var friction = 6.0
@export var move_speed = 15.0
@export var crouch_move_speed = 9.0
@export var run_acceleration = 14.0
@export var run_deacceleration = 10.0
@export var air_acceleration = 2.0
@export var air_deacceleration = 2.0
@export var air_control = 0.3
@export var side_strafe_acceleration = 0
@export var side_strafe_speed = 1.0
@export var jump_speed = 11
@export var move_scale = 1.0
@export var ground_snap_tolerance = 1
@export var crouchslide_friction = 1
@export var default_friction = 6
@export var air_control_acceleration = 80
@export var dash_speed_ground = 200
@export var dash_speed_air = 80
@export var dash_cooldown = 1

@export var health = 1000
@export var max_health = 1000

var move_direction_norm = Vector3()
var player_velocity = Vector3()
var up = Vector3(0,1,0)
var wish_jump = false;
var crouching_speed = 20
var standing_height = 2.5
var crouch_height = 1.0
var jump_count = 0
var head_hit = false
var is_crouching = false
var is_crouchsliding = false
var is_dashing = false
var can_dash = true

var player_abilities = {
	doublejump = false,
	triplejump = false,
	crouchslide = false,
	air_control = true,
	dash = false,
}
##### Make store scene, give each node script "player_abilitiy."ability" = true", find abilities by searching "player_abilities."

@onready var head = $Head
@onready var pcap = $CollisionShape3D
@onready var head_checker = $Head/HeadCheck
@onready var dash_timer = $DashTimer
@onready var label_left = $"HUD Stats/MarginContainer/Control/HBoxContainer/VBoxContainer/LabelLeft"
@onready var label_forward = $"HUD Stats/MarginContainer/Control/HBoxContainer2/VBoxContainer2/LabelForward"
@onready var label_back = $"HUD Stats/MarginContainer/Control/HBoxContainer2/VBoxContainer2/VBoxContainer2/LabelBack"
@onready var label_jump = $"HUD Stats/MarginContainer/Control/HBoxContainer3/VBoxContainer/Control/LabelJump"
@onready var label_right_2 = $"HUD Stats/MarginContainer/Control/HBoxContainer3/VBoxContainer/Control2/LabelRight2"
@onready var label_crouch = $"HUD Stats/MarginContainer/Control/HBoxContainer3/VBoxContainer/Control3/LabelCrouch"



func _ready():
	set_physics_process(true)
	floor_snap_length = 0.15
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	label_crouch.visible = false

func _physics_process(delta):
	queue_jump()
	if is_on_floor():
		ground_move(delta)
		jump_count = 0
		
	else:
		air_move(delta)
		if Input.is_action_just_pressed("jump") and player_abilities.doublejump and jump_count < 1:
			player_velocity.y = jump_speed
			jump_count += 1
		if Input.is_action_just_pressed("jump") and player_abilities.triplejump and jump_count < 2:
			player_velocity.y = jump_speed
			jump_count += 1
			
	if head_checker.is_colliding():
		head_hit = true
	
	if head_hit == true:
		player_velocity.y -= 2
	
	if Input.is_action_just_released("ability") and player_abilities.crouchslide:
		is_crouching = false
		is_crouchsliding = false
	
	if dash_timer.is_stopped():
		can_dash = true
	
	set_velocity(player_velocity)
	set_up_direction(up)
	set_floor_stop_on_slope_enabled(true)
	move_and_slide()
	player_velocity = velocity

func snap_to_ground(from):
	#var from = global_transform.origin
	var to = from + -global_transform.basis.y * ground_snap_tolerance
	var space_state = get_world_3d().get_direct_space_state()
	
	var result = space_state.intersect_ray(to)
	if !result.is_empty():
		global_transform.origin.y = result.position.y

func set_movement_dir():
	cmd.forward_move = 0.0
	cmd.right_move = 0.0
	cmd.forward_move += int(Input.is_action_pressed("move_forward"))
	cmd.forward_move -= int(Input.is_action_pressed("move_backward"))
	cmd.right_move += int(Input.is_action_pressed("move_right"))
	cmd.right_move -= int(Input.is_action_pressed("move_left"))
	if Input.is_action_pressed("move_left"):
		label_left.visible = true
	else:
		label_left.visible = false
	if Input.is_action_pressed("move_forward"):
		label_forward.visible = true
	else:
		label_forward.visible = false
	if Input.is_action_pressed("move_right"):
		label_right_2.visible = true
	else:
		label_right_2.visible = false
	if Input.is_action_pressed("move_backward"):
		label_back.visible = true
	else:
		label_back.visible = false

func queue_jump():
	if Input.is_action_pressed("jump") and !wish_jump:
		wish_jump = true
		is_crouchsliding = false
		label_jump.visible = true
	else:
		label_jump.visible = false
	if Input.is_action_just_released("jump"):
		wish_jump = false

func air_move(delta):
	var wishdir = Vector3()
	var wishvel = air_acceleration
	var accel = 0.0
	
	var scale = cmd_scale()
	
	set_movement_dir()
	
	wishdir += transform.basis.x * cmd.right_move
	wishdir -= transform.basis.z * cmd.forward_move
	
	var wishspeed = wishdir.length()
	
	wishdir = wishdir.normalized()
	move_direction_norm = wishdir
	
	var wishspeed2 = wishspeed
	if player_velocity.dot(wishdir) < 0:
		accel = air_deacceleration
	else:
		accel = air_acceleration
	
	if(cmd.forward_move == 0) and (cmd.right_move != 0):
		if player_abilities.air_control:
			side_strafe_acceleration = air_control_acceleration
		if wishspeed > side_strafe_speed:
			wishspeed = side_strafe_speed
		accel = side_strafe_acceleration
		
	accelerate(wishdir, wishspeed, accel, delta)
	if air_control > 0:
		air_controller(wishdir, wishspeed2, delta)
		
	player_velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("ability") and player_abilities.dash:
		if can_dash == true:
			player_velocity = wishdir * dash_speed_air
			can_dash = false
			dash_timer.start(dash_cooldown)

func air_controller(wishdir, wishspeed, delta):
	var zspeed = 0.0
	var speed = 0.0
	var dot = 0.0
	var k = 0.0
	
	if (abs(cmd.forward_move) < 0.001) or (abs(wishspeed) < 0.001):
		return
	zspeed = player_velocity.y
	player_velocity.y = 0
	
	speed = player_velocity.length()
	player_velocity = player_velocity.normalized()
	
	dot = player_velocity.dot(wishdir)
	k = 32.0
	k *= air_control * dot * dot * delta
	
	if dot > 0:
		player_velocity.x = player_velocity.x * speed + wishdir.x * k
		player_velocity.y = player_velocity.y * speed + wishdir.y * k 
		player_velocity.z = player_velocity.z * speed + wishdir.z * k 
		
		player_velocity = player_velocity.normalized()
		move_direction_norm = player_velocity
	
	player_velocity.x *= speed 
	player_velocity.y = zspeed 
	player_velocity.z *= speed 

func ground_move(delta):
	var wishdir = Vector3()
	
	if (!wish_jump):
		apply_friction(1.0, delta)
	else:
		apply_friction(0, delta)
	
	set_movement_dir()
	
	var scale = cmd_scale()
	
	wishdir += transform.basis.x * cmd.right_move
	wishdir -= transform.basis.z * cmd.forward_move
	
	wishdir = wishdir.normalized()
	move_direction_norm = wishdir
	
	var wishspeed = wishdir.length()
	
	if is_crouching and not is_crouchsliding:
		pcap.shape.height -= crouching_speed * delta
		head.transform.origin.y -= crouching_speed * delta
		wishspeed *= crouch_move_speed
		friction = default_friction
	elif not head_hit:
		pcap.shape.height += crouching_speed * delta
		wishspeed *= move_speed
		friction = default_friction
		if not is_crouchsliding:
			head.transform.origin.y += crouching_speed * delta
	if is_crouchsliding:
		pcap.shape.height -= crouching_speed * delta
		head.transform.origin.y -= crouching_speed * delta
		friction = crouchslide_friction
		
	pcap.shape.height = clamp(pcap.shape.height, crouch_height, standing_height)
	head.transform.origin.y = clamp(head.transform.origin.y, crouch_height, standing_height)
	
	accelerate(wishdir, wishspeed, run_acceleration, delta)
	
	player_velocity.y = 0.0
	
	if wish_jump:
		player_velocity.y = jump_speed
		wish_jump = false
	
	if Input.is_action_just_pressed("ability") and player_abilities.dash:
		if can_dash == true:
			player_velocity = wishdir * dash_speed_ground
			can_dash = false
			dash_timer.start(dash_cooldown)

func apply_friction(t, delta):
	var vec = player_velocity
	var speed = 0.0
	var newspeed = 0.0
	var control = 0.0
	var drop = 0.0
	
	vec.y = 0.0
	speed = vec.length()
	drop = 0.0
	
	if is_on_floor():
		if speed < run_deacceleration:
			control = run_deacceleration
		else:
			control = speed
		drop = control * friction * delta * t
	
	newspeed = speed - drop;
	if newspeed < 0:
		newspeed = 0
	if speed > 0:
		newspeed /= speed
	
	player_velocity.x *= newspeed
	player_velocity.z *= newspeed

func accelerate(wishdir, wishspeed, accel, delta):
	var addspeed = 0.0
	var accelspeed = 0.0
	var currentspeed = 0.0
	
	currentspeed = player_velocity.dot(wishdir)
	addspeed = wishspeed - currentspeed
	if addspeed <=0:
		return
	accelspeed = accel * delta * wishspeed
	if accelspeed > addspeed:
		accelspeed = addspeed
	
	player_velocity.x += accelspeed * wishdir.x
	player_velocity.z += accelspeed * wishdir.z

func cmd_scale():
	var var_max = 0
	var total = 0.0
	var scale = 0.0
	
	var_max = int(abs(cmd.forward_move))
	if(abs(cmd.right_move) > var_max):
		var_max = int(abs(cmd.right_move))
	if var_max <= 0:
		return 0
	
	total = sqrt(cmd.forward_move * cmd.forward_move + cmd.right_move * cmd.right_move)
	scale = move_speed * var_max / (move_scale * total)
	
	return scale

func _input(ev):
	if (ev is InputEventMouseMotion):
		rotate_y(-deg_to_rad(ev.relative.x) * x_mouse_sensitivity)
		head.rotate_x(-deg_to_rad(ev.relative.y) * y_mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
