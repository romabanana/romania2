extends Node2D

# ─────────────────────────────────────────
#  Division
#  Node2D
#  ├── Sprite2D
#  └── SelectionCircle (Node2D)
# ─────────────────────────────────────────

@export var move_speed : float = 0.1   # seconds per tile

var current_tile : Vector2i     = Vector2i(0, 0)
var path         : Array[Vector2i] = []
var is_selected  : bool         = false
var is_moving    : bool         = false

@onready var sprite           : Sprite2D = $Sprite2D
@onready var selection_circle : Node2D   = $SelectionCircle

var tilemap : TileMapLayer = null
var pending_path : Array[Vector2i] = []

func _ready() -> void:
	z_index = 10
	selection_circle.visible = false
	sprite.scale = Vector2(0.4, 0.4)


func init(tile: Vector2i, map: TileMapLayer) -> void:
	tilemap         = map
	current_tile    = tile
	global_position = tilemap.to_global(tilemap.map_to_local(tile))
	GridManager.set_unit(tile, self)


func select() -> void:
	is_selected = true
	queue_redraw()


func deselect() -> void:
	is_selected = false
	queue_redraw()

func move_to(target_tile: Vector2i) -> void:
#	if is_moving:
#		return

	var new_path := GridManager.get_tile_path(current_tile, target_tile)
	print("from: ", current_tile, " to: ", target_tile, " path: ", new_path)
	var province_id := GridManager.get_province_id(target_tile)
	print(ProvinceManager.get_province_name(province_id))
	
	if new_path.is_empty():
		print("Division: no path found")
		return
	if is_moving:
		# store it, will switch after current tile finishes
		pending_path = new_path
	else:
		path = new_path
		_walk_path()
	

func _walk_path() -> void:
	if not pending_path.is_empty():
		path = pending_path
		pending_path.clear()
	
	if path.is_empty():
		is_moving = false
		return
	
	is_moving = true
	var next_tile : Vector2i = path.pop_front()
	_move_to_tile(next_tile)


func _move_to_tile(tile: Vector2i) -> void:
	GridManager.clear_unit(current_tile)
	current_tile    = tile
	var target_pos  := tilemap.to_global(tilemap.map_to_local(tile))
	GridManager.set_unit(tile, self)

	if SelectionManager.selected_division == self:
		var panel = get_tree().get_first_node_in_group("selection_panel")
		if panel:
			panel.show_division(self)
			
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_pos, move_speed)
	tween.tween_callback(_walk_path)


func _draw() -> void:
	if is_selected:
		draw_ellipse(Vector2.ZERO, 120.0, 60.0, Color(1, 1, 1, 0.6), false, 10.0)
