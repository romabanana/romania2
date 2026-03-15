extends Node

# ─────────────────────────────────────────
#  Pathfinder — Autoload
#  Owns AStarGrid2D and path queries
#  "how do I get from A to B?"
# ─────────────────────────────────────────

var astar : AStar2D = AStar2D.new()


# ─────────────────────────────────────────
#  Build from TerrainManager
#  Call after TerrainManager.build()
# ─────────────────────────────────────────
func build() -> void:
	astar.clear()

	# add all passable points
	for cell in TerrainManager.grid:
		if TerrainManager.is_passable(cell):
			astar.add_point(_id(cell), Vector2(cell))

	# connect 8 isometric neighbors
	for cell in TerrainManager.grid:
		if not TerrainManager.is_passable(cell):
			continue
		for neighbor in _neighbors(cell):
			if TerrainManager.grid.has(neighbor) and TerrainManager.is_passable(neighbor):
				astar.connect_points(_id(cell), _id(neighbor), true)

	print("Pathfinder: built with %d points" % astar.get_point_count())


# ─────────────────────────────────────────
#  Pathfinding
# ─────────────────────────────────────────
func get_tile_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not TerrainManager.is_passable(to) or not TerrainManager.grid.has(to):
		return []

	var id_path := astar.get_id_path(_id(from), _id(to))
	var result  : Array[Vector2i] = []

	for id in id_path:
		result.append(_cell(id))

	if not result.is_empty():
		result.remove_at(0)

	return result


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
