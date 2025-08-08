class_name Drone extends CharacterBody3D

var landed = true
var takeoff_threshold = 10
var motors

var max_acceleration_vert = 20
var max_acceleration_hor = 10

var up_speed = 2
var down_speed = 1.5

var yaw_speed = 0.5
var current_yaw_speed = 0

var forward_speed = 10
var forward_acceleration = 0.1
var backward_speed = 10
var backward_acceleration = 0.1
var pitch_deceleration = 0.9
var right_speed = 10
var right_acceleration = 0.1
var left_speed = 10
var left_acceleration = 0.1
var roll_deceleration = 0.9

var desired_height = 0
var desired_yaw = 0
var desired_position_pitch = Vector3.ZERO
var desired_position_roll = Vector3.ZERO

var desired_position = Vector3.ZERO

var break_speed = Vector3(0, 0.9, 0)
var home_point = Vector3.ZERO
var relative_height = 0

func _ready() -> void:
	motors = [$Model/ArmFR/Motor, $Model/ArmFL/Motor, $Model/ArmBL/Motor, $Model/ArmBR/Motor]

func _process(delta: float) -> void:
	var direction = self.velocity
	direction.y = 0
	var norm_direction = direction.normalized()
	
	if landed: # Prepares takeoff
		if Input.is_action_pressed("throttle_up"):
			for motor in motors:
				motor.throttle += 3*delta
				if motor.throttle >= takeoff_threshold:
					landed = false
					home_point = self.position
		else:
			for motor in motors:
				motor.throttle -= delta

func _physics_process(delta: float) -> void:
	var acceleration = get_gravity()
	if not landed:
		# Change acceleration based on input
		acceleration += control(delta)
	
		self.velocity += acceleration*delta
		
		# Limits speed
		if self.velocity.y > up_speed:
			self.velocity.y = up_speed
		elif self.velocity.y < -down_speed:
			self.velocity.y = -down_speed
	
	self.move_and_slide()

func control(delta):
	var acceleration = Vector3.ZERO
	
	handle_input(delta)

	acceleration = handle_movement(delta)
	
	if acceleration.y < 0: # Can't accelerate downward
		acceleration.y = 0
	elif acceleration.y > max_acceleration_vert:
		acceleration.y = max_acceleration_vert
	
	var hor_acceleration = Vector2(acceleration.x, acceleration.z)
	if hor_acceleration.length() > max_acceleration_hor:
		var new_hor_acceleration = max_acceleration_hor * hor_acceleration.normalized()
		acceleration.x = new_hor_acceleration.x
		acceleration.z = new_hor_acceleration.y
	
	return acceleration

func handle_input(delta):
	handle_yaw_input(delta)
	
	var throttle_pos = handle_throttle_input()
	var pitch_pos = handle_pitch_input()
	var roll_pos = handle_roll_input()
	
	var new_desired_position = Vector3.ZERO
	var drone_coord_position = position.rotated(Vector3.DOWN, basis.get_euler().y)
	var drone_coord_desired_pos = desired_position.rotated(Vector3.DOWN, basis.get_euler().y)
	
	if throttle_pos != null:
		new_desired_position.y = drone_coord_position.y + throttle_pos
	else:
		new_desired_position.y = drone_coord_desired_pos.y
	
	if pitch_pos != null:
		new_desired_position.z = drone_coord_position.z - pitch_pos
	else:
		new_desired_position.z = drone_coord_desired_pos.z
		
	if roll_pos != null:
		new_desired_position.x = drone_coord_position.x + roll_pos
	else:
		new_desired_position.x = drone_coord_desired_pos.x
	
	desired_position = new_desired_position.rotated(Vector3.UP, basis.get_euler().y)

func handle_movement(delta):
	var delta_pos = desired_position - position
	
	var delta_height = delta_pos.y
	var delta_hor_pos = delta_pos
	delta_hor_pos.y = 0
	
	var acceleration = Vector3.ZERO
	
	acceleration.x = $X_PID.handle_movement(delta_hor_pos.x, delta)
	acceleration.z = $Z_PID.handle_movement(delta_hor_pos.z, delta)
	acceleration.y = $Y_PID.handle_movement(delta_height, delta)
	
	return acceleration

func handle_pitch_input():
	if Input.is_action_pressed("forward"):
		return 1
	elif Input.is_action_pressed("backward"):
		return -1
	
	if Input.is_action_just_released("forward") or Input.is_action_just_released("backward"):
		return 0
	
	return null

func handle_roll_input():
	var right = basis.x
	
	if Input.is_action_pressed("right"):
		return 1
	elif Input.is_action_pressed("left"):
		return -1
	
	if Input.is_action_just_released("right") or Input.is_action_just_released("left"):
		return 0
	
	return null

func handle_yaw_input(delta):
	if Input.is_action_pressed("yaw_left"):
		self.rotate(Vector3.UP, yaw_speed * delta)
	elif Input.is_action_pressed("yaw_right"):
		self.rotate(Vector3.UP, -yaw_speed * delta)

func handle_throttle_input():
	if Input.is_action_pressed("throttle_up"):
		return 3
	elif Input.is_action_pressed("throttle_down"):
		return -1
	
	if Input.is_action_just_released("throttle_up") or Input.is_action_just_released("throttle_down"):
		return 0
	
	return null
