extends Camera2D

# ─────────────────────────────────────────
#  RTS Camera 2D  –  Godot 4
# ─────────────────────────────────────────
#  Features:
#    • Edge-scroll (mouse near screen borders)
#    • WASD / Arrow-key panning
#    • Middle-mouse drag panning
#    • Scroll-wheel zoom (clamped)
#    • Optional world boundary clamping

#	Thanks Claude :)
# ─────────────────────────────────────────
# --- Pan settings ---
@export var pan_speed: float = 600.0          # pixels/sec for keyboard & edge scroll
@export var edge_scroll_margin: int = 20      # px from screen edge that triggers scroll
@export var edge_scroll_enabled: bool = true

# --- Drag settings ---
@export var drag_button: MouseButton = MOUSE_BUTTON_RIGHT

# --- Zoom settings ---
#@export var zoom_speed: float = 0.15          # fraction per scroll tick
#@export var zoom_min: float = 0.01
#@export var zoom_max: float = 3.0
#@export var zoom_smoothing: float = 5.0      # lerp speed; set 0 for instant

# --- World boundary (optional) ---
@export var use_limits: bool = true
@export var limit_rect: Rect2 = Rect2(1,1, 1,1)

# ── internal state ──────false────────────────
var _drag_active: bool = false
var _drag_origin: Vector2 = Vector2.ZERO   # mouse pos when drag started
var _cam_origin: Vector2 = Vector2.ZERO    # camera pos when drag started
var _target_zoom: Vector2 = Vector2.ONE

# New zoom
const ZOOM_LEVELS : Array[float] = [1.0, 0.25, 0.1, 0.05]
var current_zoom_level : int = 0


func _ready() -> void:
	_target_zoom = zoom
	

func _process(delta: float) -> void:
	_handle_keyboard_pan(delta)
	if edge_scroll_enabled:
		_handle_edge_scroll(delta)
	#_handle_zoom_smoothing(delta)
	if use_limits:
		_clamp_to_limits()


func _unhandled_input(event: InputEvent) -> void:
	# ── Middle-mouse drag ──────────────────
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == drag_button:
			if mb.pressed:
				_drag_active = true
				_drag_origin = mb.position
				_cam_origin  = global_position
			else:
				_drag_active = false

		# ── Zoom via scroll wheel ──────────────
		#elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			#_zoom_toward(mb.position, -1)
		#elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			#_zoom_toward(mb.position, 1)

	# ── Mouse motion drag ──────────────────
	if event is InputEventMouseMotion and _drag_active:
		var mm := event as InputEventMouseMotion
		# Move opposite to drag direction (grab-world feel)
		global_position = _cam_origin - (mm.position - _drag_origin) / zoom


# ── Keyboard / WASD panning ───────────────────────────────────────────────────
func _handle_keyboard_pan(delta: float) -> void:
	var dir := Vector2.ZERO

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1

	if dir != Vector2.ZERO:
		global_position += dir.normalized() * pan_speed * delta / zoom.x


# ── Edge scrolling ────────────────────────────────────────────────────────────
func _handle_edge_scroll(delta: float) -> void:
	if _drag_active:
		return  # don't edge-scroll while dragging

	var mouse := get_viewport().get_mouse_position()
	var vp    := get_viewport().get_visible_rect().size
	var dir   := Vector2.ZERO

	if mouse.x < edge_scroll_margin:
		dir.x -= 1
	elif mouse.x > vp.x - edge_scroll_margin:
		dir.x += 1

	if mouse.y < edge_scroll_margin:
		dir.y -= 1
	elif mouse.y > vp.y - edge_scroll_margin:
		dir.y += 1

	if dir != Vector2.ZERO:
		global_position += dir.normalized() * pan_speed * delta / zoom.x


# ── Zoom toward cursor ────────────────────────────────────────────────────────
#func _zoom_toward(screen_pos: Vector2, direction: int) -> void:
	#var old_zoom   := zoom
	#var new_zoom_v := clampf(
		#_target_zoom.x * (1.0 + zoom_speed * -direction),
		#zoom_min, zoom_max
	#)
	#_target_zoom = Vector2(new_zoom_v, new_zoom_v)
#
	## Shift camera so the point under the cursor stays fixed
	#var world_before := screen_to_world(screen_pos, old_zoom)
	#var world_after  := screen_to_world(screen_pos, _target_zoom)
	#global_position += world_before - world_after
#
#
#func _handle_zoom_smoothing(delta: float) -> void:
	#if zoom_smoothing > 0.0:
		#zoom = zoom.lerp(_target_zoom, zoom_smoothing * delta)
	#else:
		#zoom = _target_zoom
#

# ── Helper: convert a screen point to world coords at a given zoom ────────────
func screen_to_world(screen_pos: Vector2, z: Vector2) -> Vector2:
	var vp_size := get_viewport().get_visible_rect().size
	return global_position + (screen_pos - vp_size * 0.5) / z


# ── Clamp camera to world boundary ───────────────────────────────────────────
func _clamp_to_limits() -> void:
	var vp_half := get_viewport().get_visible_rect().size * 0.5 / zoom
	global_position.x = clampf(
		global_position.x,
		limit_rect.position.x + vp_half.x,
		limit_rect.end.x      - vp_half.x
	)
	global_position.y = clampf(
		global_position.y,
		limit_rect.position.y + vp_half.y,
		limit_rect.end.y      - vp_half.y
	)


func zoom_in() -> void:
	if current_zoom_level <= 0:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var old_zoom  := zoom
	current_zoom_level -= 1
	_apply_zoom(mouse_pos, old_zoom)

func zoom_out() -> void:
	if current_zoom_level >= ZOOM_LEVELS.size() - 1:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var old_zoom  := zoom
	current_zoom_level += 1
	_apply_zoom(mouse_pos, old_zoom)

func _apply_zoom(mouse_pos: Vector2, old_zoom: Vector2) -> void:
	var new_zoom_val := ZOOM_LEVELS[current_zoom_level]
	var new_zoom     := Vector2(new_zoom_val, new_zoom_val)

	# shift camera so point under cursor stays fixed
	var vp_size      := get_viewport().get_visible_rect().size
	var world_before := global_position + (mouse_pos - vp_size * 0.5) / old_zoom
	var world_after  := global_position + (mouse_pos - vp_size * 0.5) / new_zoom
	var cursor_offset       := world_before - world_after

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "zoom", new_zoom, 0.2)
	tween.parallel().tween_property(self, "global_position", global_position + cursor_offset, 0.2)
