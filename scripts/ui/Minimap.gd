extends Control

# ─────────────────────────────────────────
#  Minimap
#  Shows terrain, units and camera viewport.
#  Click to move camera.
# ─────────────────────────────────────────

const MAP_SIZE     : int   = 256
const MINIMAP_SIZE : float = 200.0

const TERRAIN_PNG  : String = "res://maps/map_01.png"

# ── References ────────────────────────────
var camera     : Camera2D  = null
var terrain_tex: Texture2D = null

# ── Colors ────────────────────────────────
const VIEWPORT_COLOR : Color = Color(1.0, 1.0, 0.0, 0.8)
const VIEWPORT_WIDTH : float = 1.5


func _ready() -> void: 
	custom_minimum_size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)

	# load terrain texture
	terrain_tex = load(TERRAIN_PNG) as Texture2D

	# find camera
	camera = get_tree().get_first_node_in_group("camera")

	# redraw every frame for unit dots and viewport rect
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# ── terrain background ─────────────────
	if terrain_tex:
		draw_texture_rect(terrain_tex, Rect2(Vector2.ZERO, Vector2(MINIMAP_SIZE, MINIMAP_SIZE)), false)

	# ── unit dots ──────────────────────────
	for unit in UnitManager.get_all_units():
		var pos    := _grid_to_minimap(unit.current_tile)
		var color  := FactionManager.get_faction_color(unit.faction_id)
		draw_circle(pos, 2.5, color)

	# ── camera viewport rectangle ──────────
	if camera:
		_draw_viewport_rect()


func _draw_viewport_rect() -> void:
	var vp_size    := get_viewport().get_visible_rect().size
	var zoom       := camera.zoom
	var cam_pos    := camera.global_position

	# world bounds of what camera sees
	var half_vp    := vp_size / zoom / 2.0
	var world_tl   := cam_pos - half_vp
	var world_br   := cam_pos + half_vp

	# convert world corners to minimap space
	var mini_tl    := _world_to_minimap(world_tl)
	var mini_br    := _world_to_minimap(world_br)
	var rect       := Rect2(mini_tl, mini_br - mini_tl)

	draw_rect(rect, VIEWPORT_COLOR, false, VIEWPORT_WIDTH)


# ─────────────────────────────────────────
#  Click to move camera
# ─────────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var world_pos := _minimap_to_world(event.position)
			if camera:
				camera.global_position = world_pos
			get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var world_pos := _minimap_to_world(event.position)
		if camera:
			camera.global_position = world_pos
		get_viewport().set_input_as_handled()


# ─────────────────────────────────────────
#  Coordinate conversions
# ─────────────────────────────────────────
func _grid_to_minimap(tile: Vector2i) -> Vector2:
	return Vector2(tile) / float(MAP_SIZE) * MINIMAP_SIZE

func _world_to_minimap(world_pos: Vector2) -> Vector2:
	# direct world → minimap without going through grid
	# world bounds: x from -32512 to 32768, y from 64 to 32704
	var world_origin := Vector2(-32512.0, 64.0)
	var world_size   := Vector2(65280.0, 32640.0)
	var normalized   := (world_pos - world_origin) / world_size
	return normalized * MINIMAP_SIZE

func _minimap_to_world(minimap_pos: Vector2) -> Vector2:
	# minimap pos → grid → world
	var tile := Vector2i(minimap_pos / MINIMAP_SIZE * float(MAP_SIZE))
	var tm   := get_tree().get_first_node_in_group("terrain_map") as TileMapLayer
	if not tm:
		return Vector2.ZERO
	return tm.to_global(tm.map_to_local(tile))
