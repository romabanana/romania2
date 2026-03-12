extends Node

# ─────────────────────────────────────────
#  ProvinceManager — Autoload
#  Add this as an Autoload in:
#  Project → Project Settings → Autoload
#  Name it: ProvinceManager
# ─────────────────────────────────────────

const PNG_PATH  : String = "res://maps/map_01_provinces.png"
const JSON_PATH : String = "res://data/provinces.json"

# ── Main data structures ─────────────────

# Vector2i → province_id
var province_map : Dictionary = {}

# province_id → province data
var provinces : Dictionary = {}


# ─────────────────────────────────────────
#  Load provinces from PNG + JSON
# ─────────────────────────────────────────
func load_provinces() -> void:
	province_map.clear()
	provinces.clear()

	# -- load JSON --
	if not FileAccess.file_exists(JSON_PATH):
		push_error("ProvinceManager: no provinces.json at " + JSON_PATH)
		return

	var file := FileAccess.open(JSON_PATH, FileAccess.READ)
	var json  := JSON.new()
	var err   := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("ProvinceManager: failed to parse provinces.json")
		return

	# build provinces dictionary from JSON
	# key in json is "R,G,B" string
	var json_data : Dictionary = json.get_data()
	var color_to_province : Dictionary = {}  # "R,G,B" → province data

	for color_key in json_data:
		var data    : Dictionary = json_data[color_key]
		var id      : int        = data["id"]
		var province_owner   : int        = data["owner"]
		provinces[id] = {
			"id":    id,
			"name":  data["name"],
			"tiles": [],
			"units": [],
			"owner": province_owner,
		}
		color_to_province[color_key] = id

	# -- load PNG --
	if not FileAccess.file_exists(PNG_PATH):
		push_error("ProvinceManager: no PNG at " + PNG_PATH)
		return

	var image := Image.load_from_file(PNG_PATH)
	if not image:
		push_error("ProvinceManager: failed to load PNG")
		return

	var width  := image.get_width()
	var height := image.get_height()

	for x in width:
		for y in height:
			var pixel     : Color  = image.get_pixel(x, y)
			if pixel.a > 0: #dumb fix to not read the water
				var color_key : String = "%02x%02x%02x" % [
					int(pixel.r * 255),
					int(pixel.g * 255),
					int(pixel.b * 255)
				]
				if color_to_province.has(color_key):
					var province_id : int    = color_to_province[color_key]
					var cell        : Vector2i = Vector2i(x, y)

					province_map[cell] = province_id
					provinces[province_id]["tiles"].append(cell)

	print("ProvinceManager: loaded %d provinces, %d tiles assigned" % [
		provinces.size(),
		province_map.size()
	])
	


# ─────────────────────────────────────────
#  Accessors
# ─────────────────────────────────────────

func get_province_id(cell: Vector2i) -> int:
	return province_map.get(cell, -1)   # -1 = unassigned

func get_province(id: int) -> Dictionary:
	return provinces.get(id, {})

func get_province_at(cell: Vector2i) -> Dictionary:
	var id := get_province_id(cell)
	if id == -1:
		return {}
	return provinces[id]

func get_province_tiles(id: int) -> Array:
	return provinces.get(id, {}).get("tiles", [])
 
func get_province_name(id: int) -> String:
	return provinces.get(id, {}).get("name", "Unknown")
	
func get_province_owner(id: int) -> Variant:
	return provinces.get(id, {}).get("owner", null)

func set_province_owner(id: int, province_owner) -> void:
	if provinces.has(id):
		provinces[id]["owner"] = province_owner

func add_unit(id: int, unit) -> void:
	if provinces.has(id):
		provinces[id]["units"].append(unit)

func remove_unit(id: int, unit) -> void:
	if provinces.has(id):
		provinces[id]["units"].erase(unit)

func get_units(id: int) -> Array:
	return provinces.get(id, {}).get("units", [])

# get all provinces owned by a specific owner
func get_provinces_by_owner(province_owner) -> Array:
	var result := []
	for id in provinces:
		if provinces[id]["owner"] == province_owner:
			result.append(id)
	return result
