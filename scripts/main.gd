@tool
extends Node

# ─────────────────────────────────────────
# Main  
# ─────────────────────────────────────────

const GRID_SIZE    := 256
const ATLAS_ID     := 1
const TOP_ATLAS_ID := 76

const TILE_LAND    := Vector2i(0, 0)
const TILE_WATER   := Vector2i(1, 0)

# noise thresholds — tweak these to get more/less water
const WATER_THRESHOLD := 0.0   # below this value = water
var tilemap : TileMapLayer :
	get:
		return get_node_or_null("TerrainMap")

var topmap : TileMapLayer :
	get:
		return get_node_or_null("TopMap")

@export var noise_seed    : int   = 0       # 0 = random each run
@export var noise_scale   : float = 0.5     # lower = bigger landmasses
@export var water_level   : float = 0.0     # raise for more water, lower for less

@export_group("Map Tools")


@export var tile_0 : bool = false :
	set(value):
		if value and Engine.is_editor_hint():
			return GridManager.get_terrain(Vector2i.ZERO)

@export var generate_map : bool = false :
	set(value):
		print("setter fired, value: ", value, " is_editor: ", Engine.is_editor_hint(), " tilemap: ", tilemap)
		if value and Engine.is_editor_hint():
			generate()
			GridManager.build_from_tilemap(tilemap)


@export var save_map : bool = false :
	set(value):
		if value and Engine.is_editor_hint():
			_save()

@export var load_map : bool = false :
	set(value):
		if value and Engine.is_editor_hint():
			_load()
			GridManager.build_from_tilemap(tilemap)

@export var export_png : bool = false :
	set(value):
		if value and Engine.is_editor_hint():
			export_map_png()


@export var map_path : String = "res://maps/map_01.dat"
@export var top_map_path : String = "res://maps/top_map_01.dat"


func _ready() -> void:
	if not Engine.is_editor_hint():
		_load()
		ProvinceManager.load_provinces()
		GridManager.build_from_tilemap(tilemap)
		setup_overlay($ProvinceSprite)
		setup_overlay($PoliticalMap)
		setup_overlay($BorderMap, 16)
		PoliticalMap.setup($PoliticalMap)
		
		setup_polygon($Water)
		setup_polygon($Clouds)
		
	# assign owner texture to sprite shader)
	await get_tree().process_frame  # wait one frame for managers to load

func generate() -> void:
	
	print("generating...")
	var noise := FastNoiseLite.new()
	noise.noise_type    = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency     = noise_scale * 0.01
	noise.seed          = noise_seed if noise_seed != 0 else randi()

	# optional: fractal layering gives more natural coastlines
	noise.fractal_type    = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5

	for x in GRID_SIZE:
		for y in GRID_SIZE:
			var value     : float    = noise.get_noise_2d(x, y)
			var atlas_pos : Vector2i = TILE_WATER if value < water_level else TILE_LAND
			tilemap.set_cell(Vector2i(x, y), ATLAS_ID, atlas_pos)

	print("Map generated — seed: ", noise.seed)

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


func _generate_top_map(data: Dictionary) -> void:
	var land_cells : Array[Vector2i] = []
	for cell in data:
		if data[cell] == TILE_LAND:
			land_cells.append(cell)
	topmap.set_cells_terrain_connect(land_cells, 0, 0, false) #false for setting coast too
	print("Top map generated")
	
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
	
	image.save_png("res://maps/map_01.png")
	print("PNG exported → res://maps/map_01.png")
	
func setup_overlay(sprite : Sprite2D, tile_size : int = 1) -> void:
	#Harcoded as fuck..
	#var sprite := sprite  # Sprite2D with your PNG, centered = false
	
	# PNG goes from (0,0) to (256,256)
	# we want (0,0) → top-left of diamond, (256,0) → top-right, (0,256) → bot-left
	
	var png_size := 256.0 * tile_size
	
	# origin = where PNG (0,0) maps to = top-left of diamond
	var origin := Vector2(128.0, 0.0)
	
	# x axis = direction from top-left to top-right, scaled by png_size
	var x_axis := (Vector2(32768.0, 16384.0)) / png_size
	
	# y axis = direction from top-left to bot-left, scaled by png_size
	var y_axis := (Vector2(-32512.0, 16384.0) - Vector2(256.0, 0.0)) / png_size
	
	sprite.transform = Transform2D(x_axis, y_axis, origin)
	sprite.modulate  = Color(1, 1, 1, 0.3)
	
func setup_polygon(poly : Polygon2D) -> void:

	var center := Vector2(128.0, 16384.0)  # center of your diamond
	var width  := 33280.0  # half width
	var height := 16384.0  # half height
	var padding := 8000.0
	var points  := 64  # more points = rounder

	var polygon := PackedVector2Array()
	for i in points:
		var angle := (float(i) / points) * TAU
		# ellipse shape matching diamond proportions
		var x := cos(angle) * (width + padding)
		var y := sin(angle) * (height + padding)
		polygon.append(center + Vector2(x, y))

	poly.polygon = polygon
