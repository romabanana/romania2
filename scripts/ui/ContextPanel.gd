extends PanelContainer

# ─────────────────────────────────────────
#  ContextPanel
#  Swaps inner scene based on selection.
# ─────────────────────────────────────────

const UNIT_PANEL_SCENE     : PackedScene = preload("res://scenes/ui/UnitPanel.tscn")
const PROVINCE_PANEL_SCENE : PackedScene = preload("res://scenes/ui/ProvincePanel.tscn")
const EMPTY_PANEL_SCENE    : PackedScene = preload("res://scenes/ui/EmptyPanel.tscn")

var current_panel : Control = null


func _ready() -> void:
	SelectionManager.unit_selected.connect(_on_unit_selected)
	SelectionManager.province_selected.connect(_on_province_selected)
	SelectionManager.deselected.connect(_on_deselected)
	_swap(EMPTY_PANEL_SCENE, null)


func _on_unit_selected(unit) -> void:
	_swap(UNIT_PANEL_SCENE, unit)
	print("Unit")


func _on_province_selected(province_id: int) -> void:
	_swap(PROVINCE_PANEL_SCENE, province_id)
	print("Province")



func _on_deselected() -> void:
	_swap(EMPTY_PANEL_SCENE, null)


func _swap(scene: PackedScene, data) -> void:
	if current_panel:
		current_panel.queue_free()
		current_panel = null

	current_panel = scene.instantiate()
	add_child(current_panel)

	if current_panel.has_method("setup"):
		current_panel.setup(data)
