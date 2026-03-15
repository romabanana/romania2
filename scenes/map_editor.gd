@tool
extends Node

# Map size
const GRID_SIZE    := 256

# Textures References
# ATLAS_ID --> TerrainMap
# TOP_ATLAS_ID --> TopMap

const ATLAS_ID     := 1
const TILE_LAND    := Vector2i(0, 0)
const TILE_WATER   := Vector2i(1, 0)

const TOP_ATLAS_ID := 76

# This way to get the scenes due to @tool
var tilemap : TileMapLayer :
	get:
		return get_node_or_null("TerrainMap")

var topmap : TileMapLayer :
	get:
		return get_node_or_null("TopMap")



@export_group("Map Tools")
@export var save_map : bool = false :
	set(value):
		if value and Engine.is_editor_hint():
			_save()

@export var load_map : bool = false :
	set(value):
		if value and Engine.is_editor_hint():
			_load()
			
@export var export_png : bool = false :
	set(value):
		if value and Engine.is_editor_hint():
			export_map_png()


@export var map_path : String = "res://maps/map_01.dat"
@export var top_map_path : String = "res://maps/top_map_01.dat"
@export var png_path : String = "res://maps/map_01.png"

func _save() -> void:
	# save terrain map
	var data := {}
	for cell in tilemap.get_used_cells():
		data[cell] = tilemap.get_cell_atlas_coords(cell)
	var file := FileAccess.open(map_path, FileAccess.WRITE)
	file.store_var(data)
	file.close()
	
	# save top map
	var top_data := {}
	for cell in topmap.get_used_cells():
		top_data[cell] = topmap.get_cell_atlas_coords(cell)
	var top_file := FileAccess.open(top_map_path, FileAccess.WRITE)
	top_file.store_var(top_data)
	top_file.close()
	
	print("Maps saved")



# Loads both terrain and top maps to paths specified. Generates the top map
# in case it doesn't exists.

func _load() -> void:
	if not FileAccess.file_exists(map_path):
		push_error("No map file found at: " + map_path)
		return
	
	# load terrain map
	var file := FileAccess.open(map_path, FileAccess.READ)
	var data : Dictionary = file.get_var()
	file.close()
	tilemap.clear()
	for cell in data:
		tilemap.set_cell(cell, ATLAS_ID, data[cell])
	
# load top map if it exists, otherwise generate it
	if FileAccess.file_exists(top_map_path):
		var top_file := FileAccess.open(top_map_path, FileAccess.READ)
		var top_data : Dictionary = top_file.get_var()
		top_file.close()
		topmap.clear()
		for cell in top_data:
			topmap.set_cell(cell, TOP_ATLAS_ID, top_data[cell])
		print("Maps loaded")
	else:
		# generate top map and save it
		_generate_top_map(data)
		_save()

# TopMap generator. It overlays the tiles acording to the terrain underneath.
# Not of much use in the future now the map is saved.

func _generate_top_map(data: Dictionary) -> void:
	var land_cells : Array[Vector2i] = []
	for cell in data:
		if data[cell] == TILE_LAND:
			land_cells.append(cell)
	topmap.set_cells_terrain_connect(land_cells, 0, 0, false) #false for setting coast too
	print("Top map generated")

# Exports map to png. Path is hardcoded.

func export_map_png() -> void:
	var image := Image.create(GRID_SIZE, GRID_SIZE, false, Image.FORMAT_RGB8)
	
	for x in GRID_SIZE:
		for y in GRID_SIZE:
			var cell := Vector2i(x, y)
			var atlas := tilemap.get_cell_atlas_coords(cell)
			
			var color : Color
			match atlas:
				Vector2i(0, 0): color = Color(0.4, 0.7, 0.3)   # plain - green
				Vector2i(1, 0): color = Color(0.2, 0.4, 0.8)   # water - blue
				Vector2i(5, 0): color = Color(0.6, 0.6, 0.6)   # urban - grey
				_:              color = Color(0, 0, 0)          # unknown - black
			
			image.set_pixel(x, y, color)
	
	image.save_png(png_path)
	print("PNG exported → ", png_path)
