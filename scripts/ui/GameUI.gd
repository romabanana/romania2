extends CanvasLayer

# ─────────────────────────────────────────
#  GameUI
#  Builds the main game UI layout in code.
#  Attach to a CanvasLayer node in main scene.
# ─────────────────────────────────────────

const TOP_BAR_HEIGHT    : int = 40
const BOTTOM_BAR_HEIGHT : int = 256+30
const MINIMAP_SIZE      : int = 256

var top_bar      : PanelContainer = null
var bottom_bar   : PanelContainer = null
var minimap      : Control        = null
var context_panel: PanelContainer = null 
var map_toggle : Button = null

func _ready() -> void:
	layer = 10
	_build_top_bar()
	_build_bottom_bar()


func _build_top_bar() -> void:
	top_bar = PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, TOP_BAR_HEIGHT)
	add_child(top_bar)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	top_bar.add_child(hbox)

	# faction label
	var faction_label := Label.new()
	faction_label.name = "FactionLabel"
	faction_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(faction_label)

	# clock label
	var clock_label := Label.new()
	clock_label.name = "ClockLabel"
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(clock_label)

	# pause button
	var pause_button := Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "⏸"
	pause_button.custom_minimum_size = Vector2(40, 0)
	hbox.add_child(pause_button)

	top_bar.set_script(load("res://scripts/ui/TopBar.gd"))


func _build_bottom_bar() -> void:
	bottom_bar = PanelContainer.new()
	bottom_bar.anchor_left   = 0.0
	bottom_bar.anchor_right  = 1.0
	bottom_bar.anchor_top    = 1.0
	bottom_bar.anchor_bottom = 1.0
	bottom_bar.offset_top    = -BOTTOM_BAR_HEIGHT
	bottom_bar.offset_bottom = 0.0
	
	#bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	#bottom_bar.custom_minimum_size = Vector2(0, BOTTOM_BAR_HEIGHT)
	add_child(bottom_bar)

	var hbox := HBoxContainer.new()
	bottom_bar.add_child(hbox)

	#minimap = Control.new()
	#minimap.name = "Minimap"
	#minimap.custom_minimum_size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	#minimap.set_script(load("res://scripts/ui/Minimap.gd"))
	#hbox.add_child(minimap)
	
	var minimap_container := VBoxContainer.new()
	minimap_container.add_theme_constant_override("separation", 2)
	hbox.add_child(minimap_container)
	
	minimap = Control.new()
	minimap.name = "Minimap"
	minimap.custom_minimum_size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	minimap.set_script(load("res://scripts/ui/Minimap.gd"))
	minimap_container.add_child(minimap)
	
	map_toggle = Button.new()
	map_toggle.text = "Political"
	map_toggle.toggle_mode = true
	map_toggle.pressed.connect(func(): minimap.toggle_political())
	minimap_container.add_child(map_toggle)

	
	# context panel
	context_panel = PanelContainer.new()
	context_panel.name = "ContextPanel"
	context_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	context_panel.set_script(load("res://scripts/ui/ContextPanel.gd"))
	hbox.add_child(context_panel)
	print("viewport size: ", get_viewport().get_visible_rect().size)
	print("bottom bar position: ", bottom_bar.position)

func toggle_visibility() -> void:
	top_bar.visible = !top_bar.visible
	bottom_bar.visible = !bottom_bar.visible
	minimap.visible = !minimap.visible
	context_panel.visible = !context_panel.visible 
