extends Node

# ─────────────────────────────────────────
#  Pathfinder — Autoload
#  Owns AStarGrid2D and path queries
#  "how do I get from A to B?"
# ─────────────────────────────────────────

var astar : AStarGrid2D = AStarGrid2D.new()

func build() -> void:
	var used_rect := TerrainManager.terrain_map.get_used_rect()
	astar.region     = used_rect
	astar.cell_shape = AStarGrid2D.CELL_SHAPE_ISOMETRIC_RIGHT
	astar.cell_size  = Vector2(256.0, 128.0)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	astar.default_compute_heuristic  = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()

	for cell in TerrainManager.grid:
		if not TerrainManager.is_passable(cell):
			astar.set_point_solid(cell, true)

	
func get_tile_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not TerrainManager.is_passable(to):
		return []
	if not astar.is_in_boundsv(from) or not astar.is_in_boundsv(to):
		return []
	var raw : Array[Vector2i] = astar.get_id_path(from, to)
	if not raw.is_empty():
		raw.remove_at(0)
	return raw


# ─────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────
func _neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i(-1, -1),
		cell + Vector2i(+1, +1),
		cell + Vector2i(-1, +1),
		cell + Vector2i(+1, -1),
		cell + Vector2i(0,  -1),
		cell + Vector2i(0,  +1),
		cell + Vector2i(-1,  0),
		cell + Vector2i(+1,  0),
	]
	
# AStar2D identifies points by a single integer ID, not by Vector2i.
# So you need a way to convert back and forth between your grid coordinates
# and that integer.
# This limits the map size to 10000x10000 tiles (currently 256x256 :p).
func _id(cell: Vector2i) -> int:
	return cell.x * 10000 + cell.y

func _cell(id: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(id / 100000, id % 100000)
