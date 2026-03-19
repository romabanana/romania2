extends Node

# ─────────────────────────────────────────
#  SelectionManager — Autoload
#  Tracks what is currently selected.
#  Only player faction units can be selected.
# ─────────────────────────────────────────

# ── Signals ──────────────────────────────
signal unit_selected(unit)
signal province_selected(province_id: int)
signal deselected()

# ── State ─────────────────────────────────
var selected_unit = null
var selected_province= -1

# ─────────────────────────────────────────
#  Input
# ─────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	var clicked_tile := _get_clicked_tile()
	if clicked_tile == Vector2i(-1, -1):
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		var unit := UnitManager.get_unit_at(clicked_tile)
		if unit != null:
			# only select units belonging to player faction
			if unit.faction_id == PlayerController.faction_id:
				_select_unit(unit)
			else:
				deselect_all()
		else:
			# clicked empty tile — select province
			selected_province = ProvinceManager.get_province_id(clicked_tile)
			if selected_province != -1:
				province_selected.emit(selected_province)
			_deselect_unit()

	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if selected_unit != null:
			selected_unit.move_to(clicked_tile)


# ─────────────────────────────────────────
#  Selection
# ─────────────────────────────────────────
func _deselect_unit() -> void:
	if selected_unit != null:
		selected_unit.deselect()
	selected_unit = null

func _select_unit(unit) -> void:
	_deselect_unit()
	selected_unit = unit
	selected_unit.select()
	unit_selected.emit(unit)



func deselect_all() -> void:
	_deselect_unit()
	selected_province = -1
	deselected.emit()


# ─────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────
func _get_clicked_tile() -> Vector2i:
	var tm := get_tree().get_first_node_in_group("terrain_map") as TileMapLayer
	if not tm:
		push_error("SelectionManager: no node in group 'terrain_map'")
		return Vector2i(-1, -1)
	return tm.local_to_map(tm.get_local_mouse_position())
