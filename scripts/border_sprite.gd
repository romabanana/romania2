extends Sprite2D

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_B:
			self.visible = !self.visible
