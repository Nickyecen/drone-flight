extends Node

@export var k_p = 20.0
@export var k_i = 5.0
@export var k_d = 10.0

var error_integral = 0
var last_error = 0

func handle_movement(error: int, delta: float):
	error_integral += error * delta
	var error_derivative = (error - last_error)/delta
	last_error = error
	
	return k_p * error + k_i * error_integral + k_d * error_derivative
