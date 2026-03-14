extends Node

# ─────────────────────────────────────────
#  MapData — Autoload
#  Stores all tile data and terrain queries
#  
# ─────────────────────────────────────────

# ── Enums ────────────────────────────────
enum Terrain { PLAIN, WATER, URBAN }

# ── Atlas coord → Terrain mapping ────────
const ATLAS_ID := 1

const TERRAIN_MAP := {
	Vector2i(0, 0): Terrain.PLAIN,
	Vector2i(1, 0): Terrain.WATER,
	Vector2i(5, 0): Terrain.URBAN,
}

# ── Terrain properties ───────────────────
const TERRAIN_DATA := {
	Terrain.PLAIN: {
		"passable":  true,
		"move_cost": 1,
		"defense":   0,
		"name":      "Plain"
	},
	Terrain.WATER: {
		"passable":  false,
		"move_cost": 99,
		"defense":   0,
		"name":      "Water"
	},
	Terrain.URBAN: {
		"passable":  true,
		"move_cost": 2,
		"defense":   2,
		"name":      "Urban"
	},
}

# ── Grid storage ─────────────────────────
var grid        : Dictionary   = {}
var terrain_map : TileMapLayer = null


# ─────────────────────────────────────────
#  Build grid from TileMapLayer
# ─────────────────────────────────────────
func build(tilemap: TileMapLayer) -> void:
	terrain_map = tilemap
	grid.clear()

	for cell in tilemap.get_used_cells():
		var atlas_coords := tilemap.get_cell_atlas_coords(cell)
		var terrain      : Terrain = TERRAIN_MAP.get(atlas_coords, Terrain.PLAIN)

		grid[cell] = {
			"terrain":     terrain,
			"province_id": ProvinceManager.get_province_id(cell),
			"city_id":     -1,
			"unit":        null,
			"structures":  [],
		}

	print("MapData: built %d cells" % grid.size())


# ─────────────────────────────────────────
#  Tile queries
# ─────────────────────────────────────────
func get_cell(cell: Vector2i) -> Dictionary:
	return grid.get(cell, {})

func get_terrain(cell: Vector2i) -> Terrain:
	return grid.get(cell, {}).get("terrain", Terrain.PLAIN)

func is_passable(cell: Vector2i) -> bool:
	return TERRAIN_DATA[get_terrain(cell)]["passable"]

func get_move_cost(cell: Vector2i) -> int:
	return TERRAIN_DATA[get_terrain(cell)]["move_cost"]

func get_defense_bonus(cell: Vector2i) -> int:
	return TERRAIN_DATA[get_terrain(cell)]["defense"]

func get_province_id(cell: Vector2i) -> int:
	return grid.get(cell, {}).get("province_id", -1)

func is_occupied(cell: Vector2i) -> bool:
	return grid.get(cell, {}).get("unit", null) != null

func set_unit(cell: Vector2i, unit) -> void:
	if grid.has(cell):
		grid[cell]["unit"] = unit

func clear_unit(cell: Vector2i) -> void:
	if grid.has(cell):
		grid[cell]["unit"] = null

func get_cells_of_terrain(terrain: Terrain) -> Array:
	var result := []
	for cell in grid:
		if grid[cell]["terrain"] == terrain:
			result.append(cell)
	return result
