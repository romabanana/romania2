extends Node

# ─────────────────────────────────────────
#  GridManager — Autoload
#  Add this as an Autoload in:
#  Project → Project Settings → Autoload
#  Name it: GridManager
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
var grid  : Dictionary  = {}
var astar : AStarGrid2D = AStarGrid2D.new()

# ── References ───────────────────────────
var terrain_map : TileMapLayer = null


# ─────────────────────────────────────────
#  Build grid + astar from TileMapLayer
# ─────────────────────────────────────────
func build_from_tilemap(tilemap: TileMapLayer) -> void:
	terrain_map = tilemap
	grid.clear()

	# -- build grid dictionary --
	for cell in tilemap.get_used_cells():
		var atlas_coords := tilemap.get_cell_atlas_coords(cell)
		var terrain      : Terrain = TERRAIN_MAP.get(atlas_coords, Terrain.PLAIN)
		var province_id : int = ProvinceManager.get_province_id(cell)

		grid[cell] = {
			"terrain":     terrain,
			"province_id": province_id,
			"city_id":     -1,
			"unit":        null,
			"structures":  [],
		}

	# -- setup astar --
	var used_rect := tilemap.get_used_rect()
	astar.region   = used_rect
	astar.cell_shape = AStarGrid2D.CELL_SHAPE_ISOMETRIC_RIGHT
	astar.cell_size  = Vector2(256.0, 128.0)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	astar.default_compute_heuristic  = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()

	# mark impassable tiles as solid
	for cell in grid:
		if not is_passable(cell):
			astar.set_point_solid(cell, true)

	print("GridManager: built %d cells, astar ready" % grid.size())


# ─────────────────────────────────────────
#  Pathfinding
# ─────────────────────────────────────────
func get_tile_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not is_passable(to):
		return []
	if not astar.is_in_boundsv(from) or not astar.is_in_boundsv(to):
		return []
	var raw : Array[Vector2i] = astar.get_id_path(from, to)
	# remove starting tile so division doesn't snap back to it
	if not raw.is_empty():
		raw.remove_at(0)
	return raw


# ─────────────────────────────────────────
#  Accessors
# ─────────────────────────────────────────
func get_cell(cell: Vector2i) -> Dictionary:
	return grid.get(cell, {})

func get_terrain(cell: Vector2i) -> Terrain:
	return grid.get(cell, {}).get("terrain", Terrain.PLAIN)

func get_province_id(cell: Vector2i) -> int:
	return grid.get(cell, {}).get("province_id", 1)
	
func is_passable(cell: Vector2i) -> bool:
	var terrain := get_terrain(cell)
	return TERRAIN_DATA[terrain]["passable"]

func get_move_cost(cell: Vector2i) -> int:
	var terrain := get_terrain(cell)
	return TERRAIN_DATA[terrain]["move_cost"]

func get_defense_bonus(cell: Vector2i) -> int:
	var terrain := get_terrain(cell)
	return TERRAIN_DATA[terrain]["defense"]

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
