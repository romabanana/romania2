extends CanvasLayer

# ─────────────────────────────────────────
#  DebugPanel
#  Toggle with F1
#  Easy to extend — just add to watches[]
#  or tweaks[] arrays
# ─────────────────────────────────────────


# ── UI refs ───────────────────────────────
var panel        : PanelContainer
var watch_container  : VBoxContainer
var tweak_container  : VBoxContainer
var watch_labels : Dictionary = {}  # label_name → Label node

# ── Watches — add entries here to display live values ──────────────────────────
# { "label": String, "get": Callable }
var watches : Array = []

# ── Tweaks — add entries here for runtime sliders ──────────────────────────────
# { "label": String, "min": float, "max": float, "get": Callable, "set": Callable }
var tweaks : Array = []


func _ready() -> void:
	layer = 100
	_build_ui()
	_register_watches()
	panel.visible = false
	# wait for Main to finish setup before registering tweaks
	await get_tree().process_frame
	await get_tree().process_frame
	_register_tweaks()
# ─────────────────────────────────────────
#  Register watches and tweaks here
#  Add new lines as your game grows
# ─────────────────────────────────────────
func _register_watches() -> void:
	_watch("FPS", func():
		return "%d" % Engine.get_frames_per_second())

	_watch("RAM", func():
		return "%.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))

	_watch("Draw calls", func():
		return "%d" % Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

	_watch("Mouse tile", func():
		var tm := get_tree().get_first_node_in_group("terrain_map") as TileMapLayer
		if not tm:
			return "no tilemap"
		return str(tm.local_to_map(tm.get_local_mouse_position())))

	_watch("Tile terrain", func():
		var tm := get_tree().get_first_node_in_group("terrain_map") as TileMapLayer
		if not tm:
			return "-"
		var cell := tm.local_to_map(tm.get_local_mouse_position())
		var t := TerrainManager.get_terrain(cell)
		return TerrainManager.TERRAIN_DATA[t]["name"])

	_watch("Tile province", func():
		var tm := get_tree().get_first_node_in_group("terrain_map") as TileMapLayer
		if not tm:
			return "-"
		var cell := tm.local_to_map(tm.get_local_mouse_position())
		var id   := ProvinceManager.get_province_id(cell)
		return ProvinceManager.get_province_name(id))

	_watch("Selected unit", func():
		var d : Node2D = SelectionManager.selected_unit
		return str(d.current_tile) if d else "none")

	_watch("Unit province", func():
		var d : Node2D = SelectionManager.selected_unit
		if not d:
			return "none"
		var id := ProvinceManager.get_province_id(d.current_tile)
		return ProvinceManager.get_province_name(id))

	_watch("Unit status", func():
		var d : Node2D = SelectionManager.selected_unit
		if not d:
			return "none"
		return "moving" if d.is_moving else "idle")

func _register_tweaks() -> void:
	# ── Visual toggles ─────────────────────
	_toggle("Water",
		func(): return VisualManager.is_visible("water"),
		func(v): VisualManager.set_visible("water", v))

	_toggle("Province overlay",
		func(): return VisualManager.is_visible("province"),
		func(v): VisualManager.set_visible("province", v))

	_toggle("Political map",
		func(): return VisualManager.is_visible("political"),
		func(v): VisualManager.set_visible("political", v))

	_toggle("Borders",
			func(): return VisualManager.is_visible("border"),
			func(v): VisualManager.set_visible("border", v))

	# ── Unit tweaks ────────────────────────

	_tweak("Unit move speed", 0.05, 2.0,
		func():
			var d : Node2D = SelectionManager.selected_unit
			return d.move_speed if d else 0.2,
		func(v: float):
			for unit in UnitManager.get_all_units():
				unit.move_speed = v)

	# ── Shader tweaks ────────────────────────

	_tweak("CRT aberration", 0.0, 0.01,
		func(): return VisualManager.get_shader_param("aberration"),
		func(v): VisualManager.set_shader_param("aberration", v),
		0.001)

	_tweak("CRT scanlines", 0.0, 0.5,
		func(): return VisualManager.get_shader_param("scanlines"),
		func(v): VisualManager.set_shader_param("scanlines", v),
		0.01)

# ─────────────────────────────────────────
#  Toggle visibility
# ─────────────────────────────────────────
func toggle_visibility() -> void:
	panel.visible = !panel.visible


# ─────────────────────────────────────────
#  Update watches every frame
# ─────────────────────────────────────────
func _process(_delta: float) -> void:
	if not panel.visible:
		return
	for entry in watches:
		var label : Label = watch_labels.get(entry["label"])
		if label:
			label.text = "%s: %s" % [entry["label"], entry["get"].call()]


# ─────────────────────────────────────────
#  Build UI programmatically
# ─────────────────────────────────────────
func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "DebugPanel"

	# style
	var style := StyleBoxFlat.new()
	style.bg_color          = Color(0.05, 0.05, 0.05, 0.85)
	style.border_color      = Color(0.2, 0.8, 0.2, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left   = 12
	style.content_margin_right  = 12
	style.content_margin_top    = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	# anchor to top left
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(10, 10)
	panel.custom_minimum_size = Vector2(280, 0)
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				get_viewport().set_input_as_handled()
	)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(260, 500)
	panel.add_child(scroll)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(root_vbox)

	# title
	var title := Label.new()
	title.text = "[ DEBUG ]"
	title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	root_vbox.add_child(title)

	root_vbox.add_child(_separator())

	# watches section
	var watch_title := Label.new()
	watch_title.text = "WATCHES"
	watch_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	root_vbox.add_child(watch_title)

	watch_container = VBoxContainer.new()
	watch_container.add_theme_constant_override("separation", 2)
	root_vbox.add_child(watch_container)

	root_vbox.add_child(_separator())

	# tweaks section
	var tweak_title := Label.new()
	tweak_title.text = "TWEAKS"
	tweak_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	root_vbox.add_child(tweak_title)

	tweak_container = VBoxContainer.new()
	tweak_container.add_theme_constant_override("separation", 6)
	root_vbox.add_child(tweak_container)

	add_child(panel)


# ─────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────
func _watch(label: String, getter: Callable) -> void:
	watches.append({"label": label, "get": getter})

	var lbl := Label.new()
	lbl.text = "%s: —" % label
	lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	lbl.add_theme_font_size_override("font_size", 11)
	watch_container.add_child(lbl)
	watch_labels[label] = lbl


func _tweak(label: String, min_val: float, max_val: float, getter: Callable, setter: Callable, custom_step: float = 0.1) -> void:
	tweaks.append({"label": label, "min": min_val, "max": max_val, "get": getter, "set": setter})

	var vbox := VBoxContainer.new()
	tweak_container.add_child(vbox)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(lbl)

	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)

	var slider := HSlider.new()
	slider.min_value   = min_val
	slider.max_value   = max_val
	slider.step = custom_step 
	slider.scrollable = false
	slider.value       = getter.call()
	slider.custom_minimum_size = Vector2(180, 0)
	hbox.add_child(slider)

	var value_label := Label.new()
	value_label.text = "%.3f" % getter.call()
	value_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	value_label.add_theme_font_size_override("font_size", 11)
	value_label.custom_minimum_size = Vector2(40, 0)
	hbox.add_child(value_label)

	slider.value_changed.connect(func(v: float):
		setter.call(v)
		value_label.text = "%.3f" % v)
	


func _separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.2, 0.2, 0.2))
	return sep

func _toggle(label: String, getter: Callable, setter: Callable) -> void:
	var hbox := HBoxContainer.new()
	tweak_container.add_child(hbox)

	var check := CheckButton.new()
	check.text      = label
	check.button_pressed = getter.call()
	check.add_theme_font_size_override("font_size", 11)
	check.toggled.connect(func(v: bool): setter.call(v))
	hbox.add_child(check)
