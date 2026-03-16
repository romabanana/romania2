extends Node

# ─────────────────────────────────────────
#  UnitManager — Autoload
#  Owns unit positions and spawning.
# ─────────────────────────────────────────

const UNIT_SCENE : PackedScene = preload("res://scenes/units/unit.tscn")

# tile → unit node
var units       : Dictionary   = {}

# set from Main._ready()
var unit_parent : Node         = null
var tilemap     : TileMapLayer = null


# ─────────────────────────────────────────
#  Spawn
# ─────────────────────────────────────────
func spawn(tile: Vector2i, faction_id: int) -> Node2D:
	if not unit_parent:
		push_error("UnitManager: unit_parent not set")
		return null
	if not tilemap:
		push_error("UnitManager: tilemap not set")
		return null
	if is_occupied(tile):
		push_error("UnitManager: tile %s already occupied" % tile)
		return null

	var unit := UNIT_SCENE.instantiate() as Node2D
	unit_parent.add_child(unit)
	unit.faction_id = faction_id
	unit.init(tile, tilemap)
	FactionManager.register_unit(faction_id, unit)

	print("UnitManager: spawned unit for faction %d at %s" % [faction_id, tile])
	return unit


func despawn(unit: Node2D) -> void:
	var tile := get_unit_tile(unit)
	if tile != Vector2i(-1, -1):
		clear_unit(tile)
	FactionManager.unregister_unit(unit.faction_id, unit)
	unit.queue_free()


# ─────────────────────────────────────────
#  Position tracking
# ─────────────────────────────────────────
func set_unit(cell: Vector2i, unit) -> void:
	units[cell] = unit


func clear_unit(cell: Vector2i) -> void:
	units.erase(cell)


func get_unit_at(cell: Vector2i) -> Node2D:
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


func get_faction_units(faction_id: int) -> Array:
	var result := []
	for unit in units.values():
		if unit.faction_id == faction_id:
			result.append(unit)
	return result
