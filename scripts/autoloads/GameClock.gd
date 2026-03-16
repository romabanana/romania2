extends Node

# ─────────────────────────────────────────
#  GameClock — Autoload
#  Manages game time in hours.
#  1 real second = hours_per_second game hours
# ─────────────────────────────────────────

# ── Signals ──────────────────────────────
signal tick(delta_hours: float)
signal hour_passed(hour: int)
signal day_passed(day: int)
signal paused(state: bool)

# ── Settings ─────────────────────────────
var hours_per_second : float = 1.0
var start_hour       : int   = 6
var start_day        : int   = 1

# ── State ─────────────────────────────────
var is_paused   : bool  = false
var total_hours : float = 0.0

# ── Derived ───────────────────────────────
var current_hour : int :
	get: return (start_hour + int(total_hours)) % 24

var current_day : int :
	get: return start_day + int((total_hours + start_hour)/ 24.0)


func _process(delta: float) -> void:
	if is_paused:
		return

	var delta_hours := delta * hours_per_second
	var prev_hour   := current_hour
	var prev_day    := current_day

	total_hours     += delta_hours

	tick.emit(delta_hours)

	if current_hour != prev_hour:
		hour_passed.emit(current_hour)

	if current_day != prev_day:
		day_passed.emit(current_day)


func toggle_pause() -> void:
	is_paused = !is_paused
	paused.emit(is_paused)
	print("GameClock: %s — %s" % [
		"PAUSED" if is_paused else "RUNNING",
		get_time_string()
	])

func pause() -> void:
	is_paused = true
	paused.emit(true)

func unpause() -> void:
	is_paused = false
	paused.emit(false)

func get_time_string() -> String:
	return "Day %d  %02d:00" % [current_day, current_hour]
