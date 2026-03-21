extends Node

# ─────────────────────────────────────────
#  LODManager — Autoload
# ─────────────────────────────────────────

enum State { ULTRA_CLOSE, CLOSE, MID, FAR }

signal state_changed(new_state: State)

const THRESHOLD_ULTRA_CLOSE : float = 0.6
const THRESHOLD_CLOSE       : float = 0.4
const THRESHOLD_MID         : float = 0.1

const HYSTERESIS : float = 0.0

var current_state : State = State.CLOSE

var _tweens : Dictionary = {}  # node instance id → tween

func on_zoom_changed(zoom_value: float) -> void:
	var new_state := _evaluate(zoom_value)
	if new_state == current_state:
		return
	current_state = new_state
	_apply(new_state)
	state_changed.emit(new_state)
	print("LODManager: → %s (zoom %.2f)" % [State.keys()[new_state], zoom_value])


func _evaluate(zoom_value: float) -> State:
	match current_state:
		State.ULTRA_CLOSE:
			if zoom_value < THRESHOLD_ULTRA_CLOSE - HYSTERESIS:
				return State.CLOSE
		State.CLOSE:
			if zoom_value > THRESHOLD_ULTRA_CLOSE :
				return State.ULTRA_CLOSE
			elif zoom_value < THRESHOLD_CLOSE - HYSTERESIS:
				return State.MID
		State.MID:
			if zoom_value > THRESHOLD_CLOSE :
				return State.CLOSE
			elif zoom_value < THRESHOLD_MID - HYSTERESIS:
				return State.FAR
		State.FAR:
			if zoom_value > THRESHOLD_MID :
				return State.MID
	return current_state

func _apply(state: State) -> void:
	match state:
		State.ULTRA_CLOSE:
			_set_group("terrain_map",     false)
			_set_group("top_map",         true)
			_set_group("top_map_lod_1",  false)
			_set_group("top_map_lod_2",  false)
			_set_group("terrain_lod",     false)

		State.CLOSE:
			_set_group("terrain_map",     false)
			_set_group("top_map",         false)
			_set_group("top_map_lod_1",  true)
			_set_group("top_map_lod_2",  false)
			_set_group("terrain_lod",     false)

		State.MID:
			_set_group("terrain_map",     false)
			_set_group("top_map",         false)
			_set_group("top_map_lod_1",  false)
			_set_group("top_map_lod_2",  true)
			_set_group("terrain_lod",     false)

		State.FAR:
			_set_group("terrain_map",     false)
			_set_group("top_map",         false)
			_set_group("top_map_lod_1",  false)
			_set_group("top_map_lod_2",  false)
			_set_group("terrain_lod",     true)


# ─────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────
func _set_group(group: String, value: bool, duration: float = 0.2) -> void:
	var node := get_tree().get_first_node_in_group(group) 
	if !value:
		_fade(node, value, duration)
	else:
		_fade(node, value, 0.0)
	#_fade(node,value,duration)


func _set_overlay(layer_name: String, value: bool, duration: float = 1) -> void:
	if not VisualManager._layers.has(layer_name):
		return
	var node    := VisualManager._layers[layer_name] as CanvasItem
	var opacity := VisualManager.get_default_opacity(layer_name)
	_fade(node, value, duration, opacity)


func _fade(node: CanvasItem, value: bool, duration: float = 0.3, target_opacity: float = 1.0) -> void:
	if not node:
		return
	if value and node.visible and node.modulate.a >= target_opacity - 0.01:
		return
	if not value and not node.visible:
		return

	# kill existing tween for this node
	var id := node.get_instance_id()
	if _tweens.has(id) and is_instance_valid(_tweens[id]):
		_tweens[id].kill()

	var tween := create_tween()
	_tweens[id] = tween

	if value:
		node.visible = true
		tween.tween_property(node, "modulate:a", target_opacity, duration)
	else:
		tween.tween_property(node, "modulate:a", 0.0, duration)
		tween.tween_callback(func(): node.visible = false)
