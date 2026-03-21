extends Resource
class_name UnitData

# ─────────────────────────────────────────
#  Unit Data System — Defines all unit properties
#  Used by Unit and UnitCard for display
# ─────────────────────────────────────────

# Unit Rank/Scale (规模)
enum Rank {
	SQUAD,      # 班
	PLATOON,    # 排
	COMPANY,    # 连
	BATTALION,  # 营
	REGIMENT,   # 团
	BRIGADE,    # 旅
	DIVISION,   # 师
	CORPS,      # 军
	ARMY        # 集团军
}

# Unit Type (类型)
enum UnitType {
	INFANTRY,        # 步兵
	MECHANIZED,      # 机械化
	ARMORED,         # 装甲
	ARTILLERY,       # 炮兵
	AIR_DEFENSE,     # 防空
	SUPPORT,         # 支援
	RECONNAISSANCE   # 侦察
}

# Unit Status/State (状态)
enum UnitStatus {
	IDLE,        # 驻扎
	MOVING,      # 移动
	ATTACKING,   # 攻击
	DEFENDING,   # 防御
	RETREATING,  # 撤退
	ENTRENCHED   # 防守
}

# Experience/Vet Level (经验等级)
enum VetLevel {
	GREEN,      # 新兵
	REGULAR,    # 常规
	VETERAN,    # 老兵
	ELITE       # 精英
}

# Unit Properties
@export var unit_id: String = ""
@export var unit_name: String = "Unknown Unit"
@export var rank: Rank = Rank.COMPANY
@export var unit_type: UnitType = UnitType.INFANTRY
@export var faction: String = "Unknown"  # Faction identifier
@export var current_status: UnitStatus = UnitStatus.IDLE
@export var vet_level: VetLevel = VetLevel.REGULAR

# Unit Stats (0-100 scale for bars)
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var max_organization: int = 100
@export var current_organization: int = 100
@export var max_supply: int = 100
@export var current_supply: int = 100

# Icon/Texture paths
@export var unit_icon_path: String = ""
@export var faction_icon_path: String = ""
@export var type_icon_path: String = ""

func get_hp_percentage() -> float:
	return float(current_hp) / float(max_hp) if max_hp > 0 else 0.0

func get_organization_percentage() -> float:
	return float(current_organization) / float(max_organization) if max_organization > 0 else 0.0

func get_supply_percentage() -> float:
	return float(current_supply) / float(max_supply) if max_supply > 0 else 0.0

func get_rank_name() -> String:
	return Rank.keys()[rank]

func get_type_name() -> String:
	return UnitType.keys()[unit_type]

func get_status_name() -> String:
	return UnitStatus.keys()[current_status]

func get_vet_name() -> String:
	return VetLevel.keys()[vet_level]
