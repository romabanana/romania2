extends Label

func _process(_delta: float) -> void:
	var fps     := Engine.get_frames_per_second()
	var ram     := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var draw    := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	self.text  = "FPS: %d | RAM: %.1f MB | Draw calls: %d" % [fps, ram, draw]
