class_name Drone extends CharacterBody3D

var landed = true
var takeoff_threshold = 10
var motors

var up_speed = 2
var down_speed = 1.5

var yaw_speed = 1
var current_yaw_speed = 0
var yaw_acceleration = 0.8
var yaw_deceleration = 6
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
		print("Acceleration: " + str(acceleration))
	
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
	var y_acceleration = handle_vertical_movement(delta)
	if y_acceleration < 0: # Can't accelerate downward
		y_acceleration = 0
	acceleration.y += y_acceleration
	
	return acceleration

func handle_vertical_movement(delta):
	print("Desired: " + str(desired_height))
	print("Current: " + str(self.position.y))
	return $PID.handle_movement(desired_height - self.position.y, delta)

func handle_throttle_input():
	if Input.is_action_pressed("throttle_up"):
		desired_height = global_position.y + 4
	elif Input.is_action_pressed("throttle_down"):
		desired_height = global_position.y - 1
	
	if Input.is_action_just_released("throttle_up") or Input.is_action_just_released("throttle_down"):
		desired_height = global_position.y
