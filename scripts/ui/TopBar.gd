extends PanelContainer

# ─────────────────────────────────────────
#  TopBar
#  Shows faction name, clock, pause button
# ─────────────────────────────────────────

@onready var faction_label : Label  = $HBoxContainer/FactionLabel
@onready var clock_label   : Label  = $HBoxContainer/ClockLabel
@onready var pause_button  : Button = $HBoxContainer/PauseButton


func _ready() -> void:
	pause_button.pressed.connect(_on_pause_pressed)
	GameClock.paused.connect(_on_clock_paused)

	# set faction name and color
	var faction := FactionManager.get_faction(PlayerController.faction_id)
	if not faction.is_empty():
		faction_label.text = faction["name"]
		faction_label.add_theme_color_override("font_color", faction["color"])


func _process(_delta: float) -> void:
	clock_label.text = GameClock.get_time_string()


func _on_pause_pressed() -> void:
	GameClock.toggle_pause()


func _on_clock_paused(state: bool) -> void:
	pause_button.text = "▶" if state else "⏸"
