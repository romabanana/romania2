@tool
extends Node

const ATLAS_ID = 1
const TILE_LAND = Vector2i(0, 0)
const TILE_WATER = Vector2i(1, 0)

@export_group("Tiles Generator")
@export var provinces_png_path: String = "res://maps/my_provinces.png"
@export var output_map_path: String = "res://maps/my_map.dat"
@export var validate_size: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			_check_size()

@export var generate_map: bool = false :
	set(value):
		if value and Engine.is_editor_hint():
			_generate_terrain()


func _generate_terrain() -> void:
	var image = load(provinces_png_path) as Image
	if not image:
		push_error("cannot load PNG: " + provinces_png_path)
		return
	
	var width = image.get_width()
	var height = image.get_height()
	
	print("Size of PNG: %d × %d" % [width, height])
	
	var terrain_data = {}
	
	for x in width:
		for y in height:
			var pixel = image.get_pixel(x, y)
			var cell = Vector2i(x, y)
			
			if pixel.a == 0:
				terrain_data[cell] = TILE_WATER
			else:
				terrain_data[cell] = TILE_LAND
	
	# save
	var file = FileAccess.open(output_map_path, FileAccess.WRITE)
	file.store_var(terrain_data)
	file.close()
	
	print("Tilemap has been generated.")
	print("  - Size: %d × %d" % [width, height])
	print("  - Amount of tiles: %d" % terrain_data.size())
	print("  - saved in: %s" % output_map_path)


func _check_size() -> void:
	var image = load(provinces_png_path) as Image
	if not image:
		push_error("tiles_generator: cannot load PNG")
		return
	
	var width = image.get_width()
	var height = image.get_height()
	
	if not _is_power_of_two(width) or not _is_power_of_two(height):
		push_warning("It is recommended that PNG size be a power of 2 (256, 512, 1024, 2048, etc.)")
		print("   Current size: %d × %d" % [width, height])
	else:
		print("✓ PNG size is appropriate: %d × %d" % [width, height])


func _is_power_of_two(n: int) -> bool:
	return n > 0 and (n & (n - 1)) == 0
