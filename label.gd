extends Label

func _process(delta: float) -> void:
	text = str($"../Drone".desired_position)
