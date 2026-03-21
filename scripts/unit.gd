extends Node2D

# ─────────────────────────────────────────
#  Unit
#  Node2D
#  ├── Sprite2D
#  └── SelectionCircle (Node2D)
# ─────────────────────────────────────────

@export var move_speed : float = 2.0

@export var unit_data : UnitData = null

var current_tile      : Vector2i        = Vector2i(0, 0)
var path              : Array[Vector2i] = []
var pending_path      : Array[Vector2i] = []
var is_selected       : bool            = false
var is_moving         : bool            = false
var hours_accumulated : float           = 0.0

# Unit UI
@onready var unit_card : UnitCard = $UnitCard

@onready var sprite           : Sprite2D = $Sprite2D
@onready var selection_circle : Node2D   = $SelectionCircle

var tilemap   : TileMapLayer = null
var path_line : Line2D       = null

var faction_id : int = -1


func _ready() -> void:
	z_index = 10
	selection_circle.visible = false
	sprite.scale = Vector2(0.4, 0.4)
	GameClock.tick.connect(_on_tick)
	_build_path_line()
	
	#unit_card.scale = Vector2(0.4, 0.4)
	
	# Initialize unit data if not set
	if not unit_data:
		var data_file_path = "res://resources/units/Test_Unit.tres"
		if FileAccess.file_exists(data_file_path):
			var data = load(data_file_path)
			unit_data = data
			print("Unit: Default UnitData loaded")
			
			unit_card.set_unit(unit_data)
		else:
			print("Unit: No resource found in: ", data_file_path)
		#unit_data = UnitData.new()
		#unit_data.unit_name = "Test Unit"
		#unit_data.unit_type = UnitData.UnitType.INFANTRY

	await get_tree().process_frame
	# add to tilemap not to self
	tilemap.add_child(path_line)


func _build_path_line() -> void:
	path_line = Line2D.new()
	path_line.width         = 6.0
	path_line.default_color = Color(1.0, 0.9, 0.2, 0.7)
	path_line.joint_mode    = Line2D.LINE_JOINT_ROUND
	path_line.end_cap_mode  = Line2D.LINE_CAP_ROUND
	path_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	path_line.visible       = false
	path_line.z_index       = 9  # just below unit




func init(tile: Vector2i, map: TileMapLayer) -> void:
	tilemap         = map
	current_tile    = tile
	global_position = tilemap.to_global(tilemap.map_to_local(tile))
	UnitManager.set_unit(tile, self)


# ─────────────────────────────────────────
#  Selection
# ─────────────────────────────────────────
func select() -> void:
	is_selected = true
	_update_path_line()
	queue_redraw()


func deselect() -> void:
	is_selected  = false
	path_line.visible = false
	queue_redraw()


# ─────────────────────────────────────────
#  Movement orders
# ─────────────────────────────────────────
func move_to(target_tile: Vector2i) -> void:
	cancel_movement()
	var new_path : Array[Vector2i] = Pathfinder.get_tile_path(current_tile, target_tile)
	if new_path.is_empty():
		print("Unit: no path found to ", target_tile)
		return

	if is_moving:
		pending_path = new_path
	else:
		path              = new_path
		is_moving         = true
		hours_accumulated = 0.0

	_update_path_line()


func cancel_movement() -> void:
	path.clear()
	pending_path.clear()
	is_moving         = false
	hours_accumulated = 0.0
	_update_path_line()


# ─────────────────────────────────────────
#  Clock driven movement
# ─────────────────────────────────────────
func _on_tick(delta_hours: float) -> void:
	if not is_moving:
		return

	hours_accumulated += delta_hours

	if hours_accumulated >= move_speed:
		hours_accumulated = 0.0
		_step()


func _step() -> void:
	if not pending_path.is_empty():
		path = pending_path
		pending_path.clear()

	if path.is_empty():
		is_moving = false
		_update_path_line()
		return

	var next_tile  : Vector2i = path.pop_front()
	var target_pos := tilemap.to_global(tilemap.map_to_local(next_tile))

	# update grid
	UnitManager.clear_unit(current_tile)
	current_tile = next_tile
	UnitManager.set_unit(current_tile, self)

	# smooth tween FROM current visual pos TO new tile
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_position", target_pos, 0.3)

	_update_path_line()

	# update UI panel
	if SelectionManager.selected_unit == self:
		var panel = get_tree().get_first_node_in_group("selection_panel")
		if panel:
			panel.show_division(self)


# ─────────────────────────────────────────
#  Path line
# ─────────────────────────────────────────
func _update_path_line() -> void:
	path_line.clear_points()

	if not is_selected or path.is_empty():
		path_line.visible = false
		return

	path_line.visible = true

	# start from current tile center, not unit visual position
	path_line.add_point(tilemap.map_to_local(current_tile))

	for tile in path:
		path_line.add_point(tilemap.map_to_local(tile))
		
		
func _exit_tree() -> void:
	if path_line:
		path_line.queue_free()
# ─────────────────────────────────────────
#  Visuals
# ─────────────────────────────────────────
func _draw() -> void:
	if is_selected:
		draw_ellipse(Vector2.ZERO, 120.0, 60.0, Color(1, 1, 1, 0.6), false, 10.0)
