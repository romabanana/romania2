extends Control

# ─────────────────────────────────────────
#  ProvincePanel
#  Shows info for selected province.
# ─────────────────────────────────────────

@onready var label_name    : Label = $VBoxContainer/LabelName
@onready var label_owner   : Label = $VBoxContainer/LabelOwner
@onready var label_tiles   : Label = $VBoxContainer/LabelTiles
@onready var label_units   : Label = $VBoxContainer/LabelUnits


func setup(province_id: int) -> void:
	if province_id == -1:
		return

	var province := ProvinceManager.get_province(province_id)
	if province.is_empty():
		return

	label_name.text  = "[ %s ]" % province.get("name", "Unknown")

	var owner_id : int = ProvinceManager.get_province_owner(province_id)
	if owner_id != null and owner_id >= 0:
		var faction := FactionManager.get_faction(owner_id)
		label_owner.text = "Owner: %s" % faction.get("name", "Unknown")
		label_owner.add_theme_color_override("font_color", faction.get("color", Color.WHITE))
	else:
		label_owner.text = "Owner: Unowned"
		label_owner.add_theme_color_override("font_color", Color.GRAY)

	label_tiles.text = "Tiles: %d" % province.get("tiles", []).size()

	# count units in province
	var unit_count := 0
	for tile in province.get("tiles", []):
		if UnitManager.is_occupied(tile):
			unit_count += 1
	label_units.text = "Units: %d" % unit_count
