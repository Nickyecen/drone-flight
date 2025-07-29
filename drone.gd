class_name Drone extends CharacterBody3D

var landed = true
var takeoff_threshold = 10
var motors

var up_speed = 5
var up_acceleration = 0.1
var down_speed = 3
var down_acceleration = 0.2
var vertical_deceleration = 0.9
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

var break_speed = Vector3(0, 0.9, 0)
var home_point = Vector3.ZERO
var relative_height = 0

func _ready() -> void:
	motors = [$Model/ArmFR/Motor, $Model/ArmFL/Motor, $Model/ArmBL/Motor, $Model/ArmBR/Motor]

func _process(delta: float) -> void:
	var direction = self.velocity
	direction.y = 0
	var norm_direction = direction.normalized()
	
	var yaw = self.global_rotation.y
	var right_direction = norm_direction.cross(Vector3.UP).rotated(Vector3.UP, yaw)
	$Model.basis = Basis().rotated(right_direction, clamp(direction.length(), -0.2, 0.2))
	
	if landed:
		if Input.is_action_pressed("throttle_up"):
			for motor in motors:
				motor.throttle += 2*delta
				if motor.throttle >= takeoff_threshold:
					landed = false
					home_point = self.position
		else:
			for motor in motors:
				motor.throttle -= delta

func _physics_process(delta: float) -> void:
	control(delta)
	
	self.rotate_y(current_yaw_speed*delta)
	self.move_and_slide()

func control(delta):
	if not landed:
		control_throttle(delta)
		control_yaw(delta)
		control_pitch(delta)
		control_roll(delta)

func control_roll(delta):
	var right = -Vector3(1, 0, 0).rotated(Vector3(0, 1, 0), self.rotation.y)
	var right_velocity_mag = self.velocity.dot(right)
	var right_velocity = right_velocity_mag*right
	
	self.velocity -= right_velocity
	
	if Input.is_action_pressed("right"):
		if right_velocity_mag < right_speed:
			right_velocity += right_acceleration*right
	elif Input.is_action_pressed("left"):
		if right_velocity_mag > -left_speed:
			right_velocity -= left_acceleration*right
	else:
		right_velocity *= roll_deceleration
	
	self.velocity += right_velocity

func control_pitch(delta):
	var forward = Vector3(0, 0, 1).rotated(Vector3(0, 1, 0), self.rotation.y)
	var forward_velocity_mag = self.velocity.dot(forward)
	var forward_velocity = forward_velocity_mag*forward
	
	self.velocity -= forward_velocity
	
	if Input.is_action_pressed("forward"):
		if forward_velocity_mag < forward_speed:
			forward_velocity += forward_acceleration*forward
	elif Input.is_action_pressed("backward"):
		if forward_velocity_mag > -backward_speed:
			forward_velocity -= backward_acceleration*forward
	else:
		forward_velocity *= pitch_deceleration
	
	self.velocity += forward_velocity
		
func control_yaw(delta):
	if Input.is_action_pressed("yaw_left"):
		current_yaw_speed += yaw_acceleration*delta
		if current_yaw_speed > yaw_speed:
			current_yaw_speed = yaw_speed
	elif Input.is_action_pressed("yaw_right"):
		current_yaw_speed -= yaw_acceleration*delta
		if current_yaw_speed < -yaw_speed:
			current_yaw_speed = -yaw_speed
	else:
		current_yaw_speed *= (1 - yaw_deceleration*delta)

func control_throttle(delta):
	if Input.is_action_pressed("throttle_up"):
		if self.velocity.y < up_speed:
			self.velocity.y += up_acceleration
	elif Input.is_action_pressed("throttle_down"):
		if self.velocity.y > -down_speed:
			self.velocity.y -= down_acceleration
	else:
		self.velocity.y *= vertical_deceleration

	if Input.is_action_just_released("throttle_up") or Input.is_action_just_released("throttle_down"):
		relative_height = position.y - home_point.y
