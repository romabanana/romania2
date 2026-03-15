extends Node

# ─────────────────────────────────────────
#  UnitManager — Autoload
#  Owns unit positions on the grid
#  "what unit is on this tile?"
# ─────────────────────────────────────────

# tile → unit node
var units : Dictionary = {}


func set_unit(cell: Vector2i, unit) -> void:
	units[cell] = unit


func clear_unit(cell: Vector2i) -> void:
	units.erase(cell)


func get_unit_at(cell: Vector2i):
	return units.get(cell, null)


func is_occupied(cell: Vector2i) -> bool:
	return units.has(cell)


func get_all_units() -> Array:
	return units.values()


func get_unit_tile(unit) -> Vector2i:
	for cell in units:
		if units[cell] == unit:
			return cell
	return Vector2i(-1, -1)
