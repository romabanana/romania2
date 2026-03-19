extends Control

const MAP_SIZE     : int   = 256
const MINIMAP_SIZE : float = 256.0
const TERRAIN_PNG  : String = "res://maps/map_01.png"

const VIEWPORT_COLOR : Color = Color(1.0, 1.0, 0.0, 0.8)
const VIEWPORT_WIDTH : float = 1.5

var camera         : Camera2D   = null
var terrain_poly   : Polygon2D  = null
var _last_cam_pos  : Vector2    = Vector2.ZERO
var _last_cam_zoom : Vector2    = Vector2.ONE

var political_poly : Polygon2D = null
var show_political : bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	camera = get_tree().get_first_node_in_group("camera")
	_build_terrain_poly()
	await get_tree().process_frame
	await get_tree().process_frame
	_build_political_poly()
	queue_redraw()

func _build_terrain_poly() -> void:
	var tex := load(TERRAIN_PNG) as Texture2D
	if not tex:
		return

	terrain_poly = Polygon2D.new()
	terrain_poly.texture = tex
	terrain_poly.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# fit diamond into MINIMAP_SIZE
	# diamond is wider than tall (2:1 ratio) so fit to width
	var half := MINIMAP_SIZE / 2.0

	terrain_poly.polygon = PackedVector2Array([
		Vector2(half,         0.0),         # top
		Vector2(MINIMAP_SIZE, half),         # right
		Vector2(half,         MINIMAP_SIZE), # bottom
		Vector2(0.0,          half)          # left
	])

	terrain_poly.uv = PackedVector2Array([
		Vector2(0,   0),
		Vector2(256, 0),
		Vector2(256, 256),
		Vector2(0,   256)
	])
	terrain_poly.z_index = -1  # render below everything
	add_child(terrain_poly)


func _process(_delta: float) -> void:
	if not camera:
		return
	if camera.global_position != _last_cam_pos or camera.zoom != _last_cam_zoom:
		_last_cam_pos  = camera.global_position
		_last_cam_zoom = camera.zoom
		queue_redraw()


func _draw() -> void:
	for unit in UnitManager.get_all_units():
		var pos   := _grid_to_minimap(unit.current_tile)
		var color := FactionManager.get_faction_color(unit.faction_id)
		draw_circle(pos, 3.0, color)

	if camera:
		_draw_viewport_rect()


func _draw_viewport_rect() -> void:
	var vp_size  := get_viewport().get_visible_rect().size
	var half_vp  := vp_size / camera.zoom / 2.0
	var world_tl := camera.global_position - half_vp
	var world_br := camera.global_position + half_vp

	var tm := get_tree().get_first_node_in_group("terrain_map") as TileMapLayer
	if not tm:
		return

	var tl := _world_to_minimap(world_tl, tm)
	var tr := _world_to_minimap(Vector2(world_br.x, world_tl.y), tm)
	var br := _world_to_minimap(world_br, tm)
	var bl := _world_to_minimap(Vector2(world_tl.x, world_br.y), tm)

	draw_polyline([tl, tr, br, bl, tl], VIEWPORT_COLOR, VIEWPORT_WIDTH)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_move_camera_to(event.position)
			get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_move_camera_to(event.position)
		get_viewport().set_input_as_handled()

func _grid_to_minimap(tile: Vector2i) -> Vector2:
	var half := MINIMAP_SIZE / 2.0
	# isometric projection: grid x goes right, grid y goes down
	var fx := float(tile.x) / float(MAP_SIZE)
	var fy := float(tile.y) / float(MAP_SIZE)
	return Vector2(
		(fx - fy) * half + half,
		(fx + fy) * half
	)


func _minimap_to_grid(minimap_pos: Vector2) -> Vector2i:
	var half := MINIMAP_SIZE / 2.0
	var nx   := (minimap_pos.x - half) / half  # -1 to 1
	var ny   := minimap_pos.y / half            # 0 to 2
	var fx   := (nx + ny) / 2.0
	var fy   := (ny - nx) / 2.0
	return Vector2i(
		clamp(int(fx * MAP_SIZE), 0, MAP_SIZE - 1),
		clamp(int(fy * MAP_SIZE), 0, MAP_SIZE - 1)
	)


func _world_to_minimap(world_pos: Vector2, tm: TileMapLayer) -> Vector2:
	var tile := tm.local_to_map(tm.to_local(world_pos))
	return _grid_to_minimap(tile)


func _move_camera_to(minimap_pos: Vector2) -> void:
	var tm := get_tree().get_first_node_in_group("terrain_map") as TileMapLayer
	if not tm or not camera:
		return
	var tile               := _minimap_to_grid(minimap_pos)
	camera.global_position  = tm.to_global(tm.map_to_local(tile))
	queue_redraw()

func mark_dirty() -> void:
	queue_redraw()
	
	
func _build_political_poly() -> void:
	political_poly         = Polygon2D.new()
	political_poly.texture = PoliticalMap.political_texture
	political_poly.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	political_poly.polygon = terrain_poly.polygon
	political_poly.uv      = terrain_poly.uv
	political_poly.modulate = Color(1, 1, 1, 0.6)  # semi transparent
	political_poly.visible = false
	political_poly.z_index = 0  # above terrain poly
	add_child(political_poly)

	FactionManager.province_owner_changed.connect(func(_a, _b):
		political_poly.texture = PoliticalMap.political_texture)


func toggle_political() -> void:
	political_poly.visible = !political_poly.visible
