extends Control

# ─────────────────────────────────────────
#  UnitPanel
#  Shows info for selected unit.
#  Works for friendly and enemy units.
# ─────────────────────────────────────────

@onready var label_name     : Label = $VBoxContainer/LabelName
@onready var label_faction  : Label = $VBoxContainer/LabelFaction
@onready var label_type     : Label = $VBoxContainer/LabelType
@onready var label_manpower : Label = $VBoxContainer/LabelManpower
@onready var label_status   : Label = $VBoxContainer/LabelStatus
@onready var label_tile     : Label = $VBoxContainer/LabelTile
@onready var label_province : Label = $VBoxContainer/LabelProvince


func setup(unit) -> void:
	if not unit:
		return

	var faction  := FactionManager.get_faction(unit.faction_id)
	var is_enemy : bool = unit.faction_id != PlayerController.faction_id ##dafsas

	label_name.text     = "[ %s ]" % ("Enemy Unit" if is_enemy else "Your Unit")
	label_name.add_theme_color_override("font_color",
		faction.get("color", Color.WHITE))

	label_faction.text  = "Faction: %s" % faction.get("name", "Unknown")
	label_type.text     = "Type: %s" % unit.get("unit_type") if unit.get("unit_type") else "Type: —"
	label_manpower.text = "Manpower: %d / %d" % [
		unit.get("manpower") if unit.get("manpower") else 0,
		unit.get("max_manpower") if unit.get("max_manpower") else 0
	]
	label_status.text   = "Status: %s" % ("Moving" if unit.is_moving else "Idle")
	label_tile.text     = "Tile: %s" % str(unit.current_tile)

	var province_id := ProvinceManager.get_province_id(unit.current_tile)
	label_province.text = "Province: %s" % ProvinceManager.get_province_name(province_id)
