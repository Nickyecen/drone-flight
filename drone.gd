class_name Drone extends CharacterBody3D

var landed = true
var takeoff_threshold = 10
var motors

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
	
		# Limits speed
		if self.velocity.y + acceleration.y*delta > up_speed:
			self.velocity.y = up_speed
		elif self.velocity.y + acceleration.y*delta < -down_speed:
			self.velocity.y = -down_speed
		else:
			self.velocity += acceleration*delta
	
	self.move_and_slide()

func control(delta):
	var acceleration = Vector3.ZERO
	
	handle_throttle_input()
	handle_yaw_input(delta)
	handle_pitch_input()
	handle_roll_input()
	
	var y_acceleration = handle_vertical_movement(delta)
	if y_acceleration < 0: # Can't accelerate downward
		y_acceleration = 0
	acceleration.y += y_acceleration
	
	var pitch_acceleration = handle_pitch_movement(delta)
	acceleration += -pitch_acceleration*basis.z
	
	var roll_acceleration = handle_roll_movement(delta)
	acceleration += roll_acceleration*basis.x
	
	return acceleration

func handle_pitch_movement(delta):
	#print("Desired: " + str(desired_position_pitch))
	#print("Current: " + str(self.position))
	var forward = -basis.z
	
	var pos = position
	pos.y = 0
	desired_position_pitch.y = 0
	
	var delta_pos = forward.dot(desired_position_pitch - pos)
	
	return $Pitch_PID.handle_movement(delta_pos, delta)

func handle_roll_movement(delta):
	print("Desired: " + str(desired_position_roll))
	print("Current: " + str(self.position))
	var right = basis.x
	
	var pos = position
	pos.y = 0
	desired_position_roll.y = 0
	
	var delta_pos = right.dot(desired_position_roll - pos)
	
	return $Roll_PID.handle_movement(delta_pos, delta)

func handle_vertical_movement(delta):
	#print("Desired: " + str(desired_height))
	#print("Current: " + str(self.position.y))
	return $Y_PID.handle_movement(desired_height - self.position.y, delta)

func handle_pitch_input():
	var forward = -basis.z
	
	if Input.is_action_pressed("forward"):
		desired_position_pitch = global_position + forward
	elif Input.is_action_pressed("backward"):
		desired_position_pitch = global_position - forward
	
	if Input.is_action_just_released("forward") or Input.is_action_just_released("backward"):
		desired_position_pitch = global_position

func handle_roll_input():
	var right = basis.x
	
	if Input.is_action_pressed("right"):
		desired_position_roll = global_position + right
	elif Input.is_action_pressed("left"):
		desired_position_roll = global_position - right
	
	if Input.is_action_just_released("right") or Input.is_action_just_released("left"):
		desired_position_pitch = global_position

func handle_yaw_input(delta):
	if Input.is_action_pressed("yaw_left"):
		self.rotate(Vector3.UP, yaw_speed * delta)
	elif Input.is_action_pressed("yaw_right"):
		self.rotate(Vector3.UP, -yaw_speed * delta)
	
	if Input.is_action_just_released("yaw_right") or Input.is_action_just_released("yaw_left"):
		desired_yaw = basis.get_euler().y

func handle_throttle_input():
	if Input.is_action_pressed("throttle_up"):
		desired_height = global_position.y + 4
	elif Input.is_action_pressed("throttle_down"):
		desired_height = global_position.y - 1
	
	if Input.is_action_just_released("throttle_up") or Input.is_action_just_released("throttle_down"):
		desired_height = global_position.y
