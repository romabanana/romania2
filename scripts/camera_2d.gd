extends Camera2D

# ─────────────────────────────────────────
#  RTS Camera 2D  –  Godot 4
# ─────────────────────────────────────────

# --- Pan settings ---
@export var pan_speed          : float       = 600.0
@export var edge_scroll_margin : int         = 20
@export var edge_scroll_enabled: bool        = true

# --- Drag settings ---
@export var drag_button : MouseButton = MOUSE_BUTTON_RIGHT

# --- Zoom settings ---
@export var zoom_speed    : float = 0.05
@export var zoom_min      : float = 0.1
@export var zoom_max      : float = 1.0
@export var zoom_smoothing: float = 5.0

# --- World boundary ---
@export var use_limits  : bool  = true
@export var limit_rect  : Rect2 = Rect2(1, 1, 1, 1)

# ── Internal state ────────────────────────
var _drag_active  : bool    = false
var _drag_origin  : Vector2 = Vector2.ZERO
var _cam_origin   : Vector2 = Vector2.ZERO
var _target_zoom  : Vector2 = Vector2.ONE


func _ready() -> void:
	_target_zoom = zoom


func _process(delta: float) -> void:
	_handle_keyboard_pan(delta)
	if edge_scroll_enabled:
		_handle_edge_scroll(delta)
	_handle_zoom_smoothing(delta)
	if use_limits:
		_clamp_to_limits()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		if mb.button_index == drag_button:
			if mb.pressed:
				_drag_active = true
				_drag_origin = mb.position
				_cam_origin  = global_position
			else:
				_drag_active = false

		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_toward(mb.position, -1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_toward(mb.position, 1)

	if event is InputEventMouseMotion and _drag_active:
		var mm := event as InputEventMouseMotion
		global_position = _cam_origin - (mm.position - _drag_origin) / zoom


func _handle_keyboard_pan(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1
	if dir != Vector2.ZERO:
		global_position += dir.normalized() * pan_speed * delta / zoom.x


func _handle_edge_scroll(delta: float) -> void:
	if _drag_active:
		return
	var mouse := get_viewport().get_mouse_position()
	var vp    := get_viewport().get_visible_rect().size
	var dir   := Vector2.ZERO
	if mouse.x < edge_scroll_margin:            dir.x -= 1
	elif mouse.x > vp.x - edge_scroll_margin:  dir.x += 1
	if mouse.y < edge_scroll_margin:            dir.y -= 1
	elif mouse.y > vp.y - edge_scroll_margin:  dir.y += 1
	if dir != Vector2.ZERO:
		global_position += dir.normalized() * pan_speed * delta / zoom.x


func _zoom_toward(screen_pos: Vector2, direction: int) -> void:
	var old_zoom   := zoom
	var new_zoom_v := clampf(
		_target_zoom.x * (1.0 + zoom_speed * -direction),
		zoom_min, zoom_max
	)
	_target_zoom = Vector2(new_zoom_v, new_zoom_v)

	var world_before := screen_to_world(screen_pos, old_zoom)
	var world_after  := screen_to_world(screen_pos, _target_zoom)
	global_position  += world_before - world_after

	LODManager.on_zoom_changed(_target_zoom.x)

func _handle_zoom_smoothing(delta: float) -> void:
	if zoom_smoothing > 0.0:
		zoom = zoom.lerp(_target_zoom, zoom_smoothing * delta)
	else:
		zoom = _target_zoom


func screen_to_world(screen_pos: Vector2, z: Vector2) -> Vector2:
	var vp_size := get_viewport().get_visible_rect().size
	return global_position + (screen_pos - vp_size * 0.5) / z


func _clamp_to_limits() -> void:
	var vp_half := get_viewport().get_visible_rect().size * 0.5 / zoom
	global_position.x = clampf(global_position.x,
		limit_rect.position.x + vp_half.x,
		limit_rect.end.x      - vp_half.x)
	global_position.y = clampf(global_position.y,
		limit_rect.position.y + vp_half.y,
		limit_rect.end.y      - vp_half.y)
