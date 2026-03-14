extends PanelContainer

# UI script

@onready var label_title    : Label = $MarginContainer/VBoxContainer/Title
@onready var label_name     : Label = $MarginContainer/VBoxContainer/LabelName
@onready var label_province : Label = $MarginContainer/VBoxContainer/LabelProvince
@onready var label_terrain  : Label = $MarginContainer/VBoxContainer/LabelTerrain
@onready var label_status   : Label = $MarginContainer/VBoxContainer/LabelStatus


func _ready() -> void:
	visible = false


func show_division(division) -> void:
	visible = true
	label_title.text    = "DIVISION"
	label_name.text     = "Tile: %s" % str(division.current_tile)
	label_province.text = "Province: %s" % ProvinceManager.get_province_name(
		MapData.get_province_id(division.current_tile)
	)
	label_terrain.text  = "Terrain: %s" % MapData.TERRAIN_DATA[
		MapData.get_terrain(division.current_tile)
	]["name"]
	label_status.text   = "Status: %s" % ("Moving" if division.is_moving else "Idle")


func hide_panel() -> void:
	visible = false
