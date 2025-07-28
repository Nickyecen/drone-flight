extends Node3D

@export var clock_wise: bool = true
var throttle = 0:
	set(value):
		if value < 0:
			throttle = 0
		else: 
			throttle = value

func _process(delta: float) -> void:
	var directional_throttle = throttle
	if clock_wise:
		directional_throttle = -throttle
	$RotatingPiece.rotate(Vector3(0, 1, 0), directional_throttle * 0.1)
