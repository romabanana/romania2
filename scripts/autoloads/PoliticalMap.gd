extends Node

# ─────────────────────────────────────────
#  PoliticalMap — Autoload
#  Manages faction ownership and paints
#  a 256x256 political map texture
# ─────────────────────────────────────────

const FACTIONS_PATH : String = "res://data/factions.json"
const MAP_SIZE      : int    = 256

# ── Faction data ─────────────────────────
# faction_id (int) → { "name", "color" }
var factions : Dictionary = {}

# ── Political map texture ─────────────────
var political_image   : Image        = null
var political_texture : ImageTexture = null

# ── Reference to the sprite ──────────────
var political_sprite : Sprite2D = null


# ─────────────────────────────────────────
#  Init
# ─────────────────────────────────────────
func setup(sprite: Sprite2D) -> void:
	political_sprite = sprite
	_load_factions()
	_build_texture()


func _load_factions() -> void:
	if not FileAccess.file_exists(FACTIONS_PATH):
		push_error("PoliticalMap: no factions.json at " + FACTIONS_PATH)
		return

	var file := FileAccess.open(FACTIONS_PATH, FileAccess.READ)
	var json := JSON.new()
	var err  := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("PoliticalMap: failed to parse factions.json")
		return

	var data : Dictionary = json.get_data()
	for key in data:
		var id    : int  = int(key)
		var entry        = data[key]
		factions[id] = {
			"name":  entry["name"],
			"color": Color(entry["color"])
		}

	print("PoliticalMap: loaded %d factions" % factions.size())


func _build_texture() -> void:
	# create blank transparent 256x256 image
	political_image = Image.create(MAP_SIZE, MAP_SIZE, false, Image.FORMAT_RGBA8)
	political_image.fill(Color(0, 0, 0, 0))

	# create texture
	political_texture = ImageTexture.create_from_image(political_image)
	
	# paint initial ownership
	for province_id in ProvinceManager.provinces:
		var province_owner = ProvinceManager.provinces[province_id]["owner"]
		if province_owner != null and factions.has(province_owner):
			_paint_province_pixels(province_id, factions[province_owner]["color"])

	# assign to sprite
	political_sprite.texture = political_texture
	political_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	print("PoliticalMap: texture built")


# ─────────────────────────────────────────
#  Ownership
# ─────────────────────────────────────────
func set_province_owner(province_id: int, faction_id: int) -> void:
	if not ProvinceManager.provinces.has(province_id):
		push_error("PoliticalMap: province %d not found" % province_id)
		return

	ProvinceManager.set_province_owner(province_id, faction_id)

	var color : Color
	if faction_id >= 0 and factions.has(faction_id):
		color = factions[faction_id]["color"]
		color.a = 0.2
	else:
		color = Color(0, 0, 0, 0)   # unowned = transparent

	_paint_province_pixels(province_id, color)

func clear_province_owner(province_id: int) -> void:
	set_province_owner(province_id, -1)


func _paint_province_pixels(province_id: int, color: Color) -> void:
	
	var tiles := ProvinceManager.get_province_tiles(province_id)
	for tile in tiles:
		political_image.set_pixel(tile.x, tile.y, color)
	political_texture.update(political_image)


# ─────────────────────────────────────────
#  Accessors
# ─────────────────────────────────────────
func get_faction(id: int) -> Dictionary:
	return factions.get(id, {})

func get_faction_color(id: int) -> Color:
	return factions.get(id, {}).get("color", Color(0, 0, 0, 0))

func get_faction_name(id: int) -> String:
	return factions.get(id, {}).get("name", "Unknown")

func show_overlay(visible: bool) -> void:
	if political_sprite:
		political_sprite.visible = visible

func toggle_overlay() -> void:
	if political_sprite:
		political_sprite.visible = !political_sprite.visible
