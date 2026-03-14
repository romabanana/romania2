extends Node

# ─────────────────────────────────────────
#  SelectionManager — Autoload
#  This scripts will handle "selection". Right now has many trash of testing.
#  Too much to think.
# ─────────────────────────────────────────

var selected_division = null   # current selected Division node

# read from groups
@onready var tilemap : TileMapLayer = get_tree().get_first_node_in_group("terrain_map")
@onready var selection_panel = get_tree().get_first_node_in_group("selection_panel")

func _ready() -> void:
	await get_tree().process_frame

func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			deselect_all()
			return
	
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return

	var clicked_tile := _get_clicked_tile()
	if clicked_tile == Vector2i(-1, -1):
			return

	# left click — select
	if event.button_index == MOUSE_BUTTON_LEFT:
		var unit_on_tile = MapData.get_cell(clicked_tile).get("unit", null)
		if unit_on_tile != null:
			_select(unit_on_tile)
		else:
			deselect_all()

	# right click — move selected unit
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if selected_division != null:
			selected_division.move_to(clicked_tile)

func _select(division) -> void:
	if selected_division != null:
		selected_division.deselect()
	selected_division = division
	selected_division.select()
	selection_panel.show_division(division)


func deselect_all() -> void:
	if selected_division != null:
		selected_division.deselect()
	selected_division = null
	selection_panel.hide_panel()



func _get_clicked_tile() -> Vector2i:
	if not tilemap:
		tilemap = get_tree().get_first_node_in_group("terrain_map")
	if not tilemap:
		push_error("SelectionManager: no node in group 'terrain_map'")
		return Vector2i(-1, -1)
	var local_pos := tilemap.get_local_mouse_position()
	return tilemap.local_to_map(local_pos)

# Just for testing
func _spawn_test_division(tile: Vector2i) -> void:
	if not tilemap:
		tilemap = get_tree().get_first_node_in_group("terrain_map")

	var division_scene := Node2D.new()

	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/textures/icon.svg")
	sprite.name = "Sprite2D"
	division_scene.add_child(sprite)

	var circle := Node2D.new()
	circle.name = "SelectionCircle"
	division_scene.add_child(circle)

	division_scene.set_script(load("res://scripts/division.gd"))
	get_tree().current_scene.add_child(division_scene)
	division_scene.init(tile, tilemap)
	print("Test division spawned at tile: ", tile)
