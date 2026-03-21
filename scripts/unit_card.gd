extends PanelContainer
class_name UnitCard
# ─────────────────────────────────────────
#  Unit Card UI — Displays unit information
#  Automatically adapts to unit properties
# ─────────────────────────────────────────

@onready var unit_icon = $MarginContainer/VBoxContainer/HeaderRow/UnitIcon
@onready var unit_name_label = $MarginContainer/VBoxContainer/HeaderRow/UnitInfo/NameLabel
@onready var rank_label = $MarginContainer/VBoxContainer/HeaderRow/UnitInfo/RankLabel
@onready var faction_icon = $MarginContainer/VBoxContainer/HeaderRow/FactionIcon
@onready var vet_icon = $MarginContainer/VBoxContainer/HeaderRow/VetIcon
@onready var type_icon = $MarginContainer/VBoxContainer/HeaderRow/TypeIcon
@onready var status_label = $MarginContainer/VBoxContainer/StatusRow/StatusLabel
@onready var status_icon = $MarginContainer/VBoxContainer/StatusRow/StatusIcon

# Progress bars
@onready var hp_bar = $MarginContainer/VBoxContainer/BarsContainer/HPContainer/HPBar
@onready var hp_label = $MarginContainer/VBoxContainer/BarsContainer/HPContainer/HPLabel
@onready var org_bar = $MarginContainer/VBoxContainer/BarsContainer/OrgContainer/OrgBar
@onready var org_label = $MarginContainer/VBoxContainer/BarsContainer/OrgContainer/OrgLabel
@onready var supply_bar = $MarginContainer/VBoxContainer/BarsContainer/SupplyContainer/SupplyBar
@onready var supply_label = $MarginContainer/VBoxContainer/BarsContainer/SupplyContainer/SupplyLabel

var unit_data: UnitData = null

# Status icon colors and textures
var status_colors = {
	UnitData.UnitStatus.IDLE: Color.WHITE,
	UnitData.UnitStatus.MOVING: Color.YELLOW,
	UnitData.UnitStatus.ATTACKING: Color.RED,
	UnitData.UnitStatus.DEFENDING: Color.BLUE,
	UnitData.UnitStatus.RETREATING: Color(1, 0.5, 0, 1),
	UnitData.UnitStatus.ENTRENCHED: Color.GREEN
}
	
var status_names = {
	UnitData.UnitStatus.IDLE: "Idle",
	UnitData.UnitStatus.MOVING: "Moving",
	UnitData.UnitStatus.ATTACKING: "Attacking",
	UnitData.UnitStatus.DEFENDING: "Defending",
	UnitData.UnitStatus.RETREATING: "Retreating",
	UnitData.UnitStatus.ENTRENCHED: "Entrenched"
}

func _ready() -> void:
	if not unit_data:
		# Create test data
		unit_data = UnitData.new()

func set_unit(data: UnitData) -> void:
	unit_data = data
	update_display()

func update_display() -> void:
	if not unit_data:
		return
		
	# Update header info
	unit_name_label.text = unit_data.unit_name
	rank_label.text = _get_rank_display(unit_data.rank)
	
	# Update icons
	if unit_data.unit_icon_path:
		unit_icon.texture = load(unit_data.unit_icon_path)
	if unit_data.faction_icon_path:
		faction_icon.texture = load(unit_data.faction_icon_path)
	if unit_data.type_icon_path:
		type_icon.texture = load(unit_data.type_icon_path)
	
	# Update vet icon based on level
	_update_vet_icon()
	
	# Update status
	status_label.text = status_names.get(unit_data.current_status, "Unknown")
	status_icon.modulate = status_colors.get(unit_data.current_status, Color.WHITE)
	
	# Update bars
	_update_progress_bar(hp_bar, hp_label, unit_data.current_hp, unit_data.max_hp, "HP")
	_update_progress_bar(org_bar, org_label, unit_data.current_organization, unit_data.max_organization, "Org")
	_update_progress_bar(supply_bar, supply_label, unit_data.current_supply, unit_data.max_supply, "Supply")
	
func _get_rank_display(rank: UnitData.Rank) -> String:
	match rank:
		UnitData.Rank.SQUAD:
			return "Squad"
		UnitData.Rank.PLATOON:
			return "Platoon"
		UnitData.Rank.COMPANY:
			return "Company"
		UnitData.Rank.BATTALION:
			return "Battalion"
		UnitData.Rank.REGIMENT:
			return "Regiment"
		UnitData.Rank.BRIGADE:
			return "Brigade"
		UnitData.Rank.DIVISION:
			return "Division"
		UnitData.Rank.CORPS:
			return "Corps"
		UnitData.Rank.ARMY:
			return "Army"
		_:
			return "Unknown"
			
func _update_vet_icon() -> void:
	# You can add visual changes based on vet level
	# For example, change color or add stars
	match unit_data.vet_level:
		UnitData.VetLevel.GREEN:
			vet_icon.modulate = Color.GRAY
		UnitData.VetLevel.REGULAR:
			vet_icon.modulate = Color.WHITE
		UnitData.VetLevel.VETERAN:
			vet_icon.modulate = Color.GOLD
		UnitData.VetLevel.ELITE:
			vet_icon.modulate = Color.RED
	
	vet_icon.self_modulate = Color.WHITE  # Reset self modulate

func _update_progress_bar(bar: ProgressBar, label: Label, current: int, max_val: int, bar_name: String) -> void:
	bar.max_value = max_val
	bar.value = current
	label.text = "%s: %d/%d" % [bar_name, current, max_val]
	
	# Color bar based on percentage
	var percentage = float(current) / float(max_val) if max_val > 0 else 0.0
	if percentage > 0.66:
		bar.self_modulate = Color.GREEN
	elif percentage > 0.33:
		bar.self_modulate = Color.YELLOW
	else:
		bar.self_modulate = Color.RED

func update_hp(new_hp: int) -> void:
	if unit_data:
		unit_data.current_hp = new_hp
		_update_progress_bar(hp_bar, hp_label, unit_data.current_hp, unit_data.max_hp, "HP")

func update_organization(new_org: int) -> void:
	if unit_data:
		unit_data.current_organization = new_org
		_update_progress_bar(org_bar, org_label, unit_data.current_organization, unit_data.max_organization, "Org")

func update_supply(new_supply: int) -> void:
	if unit_data:
		unit_data.current_supply = new_supply
		_update_progress_bar(supply_bar, supply_label, unit_data.current_supply, unit_data.max_supply, "Supply")

func update_status(new_status: UnitData.UnitStatus) -> void:
	if unit_data:
		unit_data.current_status = new_status
		status_label.text = status_names.get(new_status, "Unknown")
		status_icon.modulate = status_colors.get(new_status, Color.WHITE)
