extends Node

# ─────────────────────────────────────────
#  LODManager — Autoload
#  Manages visibility of game elements
#  based on camera zoom level.
#
#  States:
#  CLOSE  → zoom > 0.5   full detail
#  MID    → zoom > 0.15  reduced detail
#  FAR    → zoom <= 0.15 overview
#
#  Called directly by Camera2D on zoom change.
#  Other systems connect to state_changed signal.
# ─────────────────────────────────────────

enum State { CLOSE, MID, FAR }

signal state_changed(new_state: State)

const THRESHOLD_CLOSE : float = 0.15
const THRESHOLD_MID   : float = 0.05 

var current_state : State = State.CLOSE


func on_zoom_changed(zoom_value: float) -> void:
	var new_state := _evaluate(zoom_value)
	if new_state == current_state:
		return
	current_state = new_state
	_apply(new_state)
	state_changed.emit(new_state)
	print("LODManager: → %s (zoom %.2f)" % [State.keys()[new_state], zoom_value])


func _evaluate(zoom_value: float) -> State:
	if zoom_value > THRESHOLD_CLOSE:
		return State.CLOSE
	elif zoom_value > THRESHOLD_MID:
		return State.MID
	else:
		return State.FAR


func _apply(state: State) -> void:
	match state:
		State.CLOSE:
			_set_tilemap(true)
			_set_top_map(true)
			_set_lod(false)
			_set_overlays(false)

		State.MID:
			_set_tilemap(false)
			_set_top_map(false)
			_set_lod(false)
			_set_overlays(true)

		State.FAR:
			_set_tilemap(false)
			_set_top_map(false)
			_set_lod(true)
			_set_overlays(true)


# ─────────────────────────────────────────
#  Visibility helpers
# ─────────────────────────────────────────

# updated _fade with target opacity
func _fade(node: CanvasItem, value: bool, duration: float = 0.3, target_opacity: float = 1.0) -> void:
	if not node:
		return
	var tween := create_tween()
	if value:
		node.visible = true
		tween.tween_property(node, "modulate:a", target_opacity, duration)
	else:
		tween.tween_property(node, "modulate:a", 0.0, duration)
		tween.tween_callback(func(): node.visible = false)
func _set_tilemap(value: bool) -> void:
	var tm := get_tree().get_first_node_in_group("terrain_map") as TileMapLayer
	_fade(tm, value)


func _set_top_map(value: bool) -> void:
	var tm := get_tree().get_first_node_in_group("top_map") as TileMapLayer
	_fade(tm, value)


func _set_lod(value: bool) -> void:
	var lod := get_tree().get_first_node_in_group("terrain_lod") as CanvasItem
	_fade(lod, value)

func _set_overlays(value: bool) -> void:
	for layer in ["political"]:
		if VisualManager._layers.has(layer):
			var opacity := VisualManager.get_default_opacity(layer)
			_fade(VisualManager._layers[layer], value, 0.3, opacity)

	_fade(VisualManager._layers["province"], !value, 0.3, 0.1)
	_fade(VisualManager._layers["border"], !value, 0.3, 0.1)
	
