extends ColorRect

var aberration_enabled : bool = true
var scanline_enabled : bool = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_C:
			aberration_enabled = !aberration_enabled
			var value := 0.005 if aberration_enabled else 0.0
			material.set_shader_parameter("aberration", value)
		if event.keycode == KEY_X:
			scanline_enabled = !scanline_enabled
			var value := 0.2 if scanline_enabled else 0.0
			material.set_shader_parameter("scanline_strength", value)
