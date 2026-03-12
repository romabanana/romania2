@tool
extends Node

# ─────────────────────────────────────────
#  Map Generator
#  Attach this script to any Node in your
#  scene that is a parent of TileMapLayer
# ─────────────────────────────────────────

const GRID_SIZE    := 256
const ATLAS_ID     := 41

const TILE_LAND    := Vector2i(4, 0)
const TILE_WATER   := Vector2i(5, 0)

# noise thresholds — tweak these to get more/less water
const WATER_THRESHOLD := 0.0   # below this value = water

@export var noise_seed    : int   = 0       # 0 = random each run
@export var noise_scale   : float = 0.5     # lower = bigger landmasses
@export var water_level   : float = 0.0     # raise for more water, lower for less

@export_group("Map Tools")

@export var generate_map : bool = false :
	set(value):
		if value and Engine.is_editor_hint():
			generate()

@export var save_map : bool = false :
	set(value):
		if value and Engine.is_editor_hint():
			_save()

@export var load_map : bool = false :
	set(value):
		if value and Engine.is_editor_hint():
			_load()

@export var map_path : String = "res://maps/map_01.dat"
@onready var tilemap : TileMapLayer = $TileMapLayer


func _ready() -> void:
	pass 
	#generate()


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
	var data := {}
	for cell in tilemap.get_used_cells():
		data[cell] = tilemap.get_cell_atlas_coords(cell)
	
	var file := FileAccess.open(map_path, FileAccess.WRITE)
	file.store_var(data)
	file.close()
	print("Map saved → ", map_path)


func _load() -> void:
	if not FileAccess.file_exists(map_path):
		push_error("No map file found at: " + map_path)
		return
	
	var file := FileAccess.open(map_path, FileAccess.READ)
	var data : Dictionary = file.get_var()
	file.close()
	
	tilemap.clear()
	for cell in data:
		tilemap.set_cell(cell, ATLAS_ID, data[cell])
	print("Map loaded ← ", map_path)
