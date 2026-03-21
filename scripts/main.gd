extends Node

# ─────────────────────────────────────────
#  Main
#  Initializes map, systems and visuals.
# ─────────────────────────────────────────

const ATLAS_ID     := 1
const TOP_ATLAS_ID := 76 #Old 256x256 tile tex
const TOP_ATLAS_LOD_ID := 0

@onready var terrain_map : TileMapLayer = $TerrainMap
@onready var top_map : TileMapLayer = $TopMap_half
@onready var top_map_lod_1 : TileMapLayer = $TopMap_quarter
@onready var top_map_lod_2 : TileMapLayer = $TopMap_octave


@export var map_path     : String = "res://maps/map_01.dat"
@export var top_map_path : String = "res://maps/top_map_01.dat"


func _ready() -> void:
	_load()
	ProvinceManager.load_provinces()
	FactionManager.load_factions()
	TerrainManager.build(terrain_map)
	Pathfinder.build()
	PoliticalMap.setup($PoliticalMap)
	_setup_overlays()
	_setup_water()
	_register_visuals()
	await _bake_border()
	# setup unit spawning
	UnitManager.unit_parent = $Units
	UnitManager.tilemap     = $TerrainMap
	
	# spawn test units
	UnitManager.spawn(Vector2i(25, 84), 1)   # player unit
	UnitManager.spawn(Vector2i(25, 85), 2) # enemy unit
	
	# 
	FactionManager.capture_province(19,1)
	
	

func _load() -> void:
	if not FileAccess.file_exists(map_path):
		push_error("Main: no map file at " + map_path)
		return

	var file := FileAccess.open(map_path, FileAccess.READ)
	var data : Dictionary = file.get_var()
	file.close()
	terrain_map.clear()
	for cell in data:
		terrain_map.set_cell(cell, ATLAS_ID, data[cell])

	if not FileAccess.file_exists(top_map_path):
		push_error("Main: no top map file at " + top_map_path)
		return

	var top_file := FileAccess.open(top_map_path, FileAccess.READ)
	var top_data : Dictionary = top_file.get_var()
	top_file.close()
	top_map.clear()
	for cell in top_data:
		top_map.set_cell(cell, TOP_ATLAS_LOD_ID, top_data[cell]) #128px tile
		top_map_lod_1.set_cell(cell, TOP_ATLAS_LOD_ID, top_data[cell]) #64px tile
		top_map_lod_2.set_cell(cell, TOP_ATLAS_LOD_ID, top_data[cell]) #32px tile

	print("Main: maps loaded")


func _setup_overlays() -> void:
	_fit_overlay($ProvinceSprite, 1)
	_fit_overlay($PoliticalMap, 1)
	_fit_overlay($BorderMap, 16)


func _fit_overlay(sprite: Sprite2D, tile_size: int = 1) -> void:
	var png_size := 256.0 * tile_size
	var origin   := Vector2(128.0, 0.0)
	var x_axis   := Vector2(32768.0, 16384.0) / png_size
	var y_axis   := (Vector2(-32512.0, 16384.0) - Vector2(256.0, 0.0)) / png_size
	sprite.transform = Transform2D(x_axis, y_axis, origin)
	sprite.modulate  = Color(1, 1, 1, 0.2)
	print("overlay transform origin: ", origin, " x: ", x_axis, " y: ", y_axis)


func _setup_water() -> void:
	var poly    := $Water as Polygon2D
	var center  := Vector2(128.0, 16384.0)
	var width   := 33280.0
	var height  := 16384.0
	var padding := 8000.0
	var points  := 64
	var polygon := PackedVector2Array()
	for i in points:
		var angle := (float(i) / points) * TAU
		polygon.append(center + Vector2(
			cos(angle) * (width + padding),
			sin(angle) * (height + padding)
		))
	poly.polygon = polygon


func _register_visuals() -> void:
	VisualManager.register("water",    $Water,        1.0)
	VisualManager.register("province", $ProvinceSprite, 0.3)
	VisualManager.register("political",$PoliticalMap,  0.3)
	VisualManager.register("border",   $BorderMap,    0.3)
#	VisualManager.register_shader("aberration",  $Camera2D/crtCanvas/CRT, "aberration",       0.005)
#	VisualManager.register_shader("scanlines",   $Camera2D/crtCanvas/CRT, "scanline_strength", 0.2)
#	VisualManager.register_shader("faction_border",   $PoliticalMap, "border_strength", 0.9)
#	VisualManager.register_shader("faction_color",   $PoliticalMap, "inner_strength", 0.2)
#	VisualManager.register_shader("water_border",   $PoliticalMap, "water_border_strength", 0.5)
	
	# setup LOD sprite
	_fit_overlay($TerrainLOD, 8)
	$TerrainLOD.visible = false
	$TerrainLOD.modulate = Color(1,1,1,1)

func _bake_border() -> void:
	var border_sprite := $BorderMap as Sprite2D
	if not border_sprite:
		return
	# fix opacitiy
	border_sprite.modulate       = Color(1, 1, 1, 0.9)
	
	var bake_viewport := SubViewport.new()
	bake_viewport.size = Vector2i(4096, 4096)
	bake_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	bake_viewport.transparent_bg = true
	add_child(bake_viewport)

	var bake_rect := TextureRect.new()
	
	bake_rect.texture        = border_sprite.texture
	bake_rect.material       = border_sprite.material
	bake_rect.size           = Vector2(4096, 4096)
	bake_rect.position       = Vector2.ZERO
	bake_viewport.add_child(bake_rect)

	# wait two frames for SubViewport to render
	await get_tree().process_frame
	await get_tree().process_frame
	# convert to ImageTexture before freeing viewport
	var img := bake_viewport.get_texture().get_image()
	var baked_texture := ImageTexture.create_from_image(img)

	border_sprite.texture  = baked_texture  # now a real ImageTexture, not ViewportTexture
	border_sprite.material = null
	bake_viewport.queue_free()
	print("Border baked")
