extends Node

# ─────────────────────────────────────────
#  PoliticalMap — Autoload
#  Purely visual — paints province ownership
#  onto a texture. Reacts to FactionManager.
# ─────────────────────────────────────────

var map_size : int = 256

# ── Texture ───────────────────────────────
var political_image   : Image        = null
var political_texture : ImageTexture = null
var political_sprite  : Sprite2D     = null


# ─────────────────────────────────────────
#  Init
# ─────────────────────────────────────────
func setup(sprite: Sprite2D, map_size_input: int = 256) -> void:
	political_sprite = sprite
	map_size         = map_size_input

	_build_texture()

	# listen to ownership changes
	FactionManager.province_owner_changed.connect(_on_ownership_changed)

	print("PoliticalMap: ready")


func _build_texture() -> void:
	political_image = Image.create(map_size, map_size, false, Image.FORMAT_RGBA8)
	political_image.fill(Color(0, 0, 0, 0))
	
	political_texture = ImageTexture.create_from_image(political_image)
	
	# paint initial ownership from current province data
	for province_id in ProvinceManager.provinces:
		var province_owner = ProvinceManager.get_province_owner(province_id)
		if province_owner != null and province_owner >= 0:
			var color := FactionManager.get_faction_color(province_owner)
			color.a   = 1.0
			_paint_province_pixels(province_id, color)

	political_sprite.texture        = political_texture
	political_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	print("PoliticalMap: texture built")


# ─────────────────────────────────────────
#  React to ownership changes
# ─────────────────────────────────────────
func _on_ownership_changed(province_id: int, faction_id: int) -> void:
	var color : Color
	if faction_id >= 0:
		color   = FactionManager.get_faction_color(faction_id)
		color.a = 1.0
	else:
		color = Color(0, 0, 0, 0)

	_paint_province_pixels(province_id, color)


func _paint_province_pixels(province_id: int, color: Color) -> void:
	var tiles := ProvinceManager.get_province_tiles(province_id)
	for tile in tiles:
		political_image.set_pixel(tile.x, tile.y, color)
	political_texture.update(political_image)


# ─────────────────────────────────────────
#  Visibility
# ─────────────────────────────────────────
func show_overlay(value: bool) -> void:
	if political_sprite:
		political_sprite.visible = value

func toggle_overlay() -> void:
	if political_sprite:
		political_sprite.visible = !political_sprite.visible
