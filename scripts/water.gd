extends Polygon2D

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			self.visible = !self.visible
