extends Node

# ─────────────────────────────────────────
#  FactionManager — Autoload
#  Owns faction data and province ownership
#  logic. Graphics handled by PoliticalMap.
# ─────────────────────────────────────────

const FACTIONS_PATH : String = "res://data/factions.json"

# ── Signals ──────────────────────────────
signal province_owner_changed(province_id: int, faction_id: int)

# ── Faction data ─────────────────────────
# faction_id (int) → { "name", "color", "provinces" }
var factions : Dictionary = {}


# ─────────────────────────────────────────
#  Init
# ─────────────────────────────────────────
func load_factions() -> void:
	if not FileAccess.file_exists(FACTIONS_PATH):
		push_error("FactionManager: no factions.json at " + FACTIONS_PATH)
		return

	var file := FileAccess.open(FACTIONS_PATH, FileAccess.READ)
	var json := JSON.new()
	var err  := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("FactionManager: failed to parse factions.json")
		return

	var data : Dictionary = json.get_data()
	for key in data:
		var id    : int        = int(key)
		var entry : Dictionary = data[key]
		factions[id] = {
			"name":      entry["name"],
			"color":     Color(entry["color"]),
			"provinces": [],
			"units":     [],
		}

	# build initial province lists from ProvinceManager owner data
	for province_id in ProvinceManager.provinces:
		var province_owner = ProvinceManager.provinces[province_id]["owner"]
		if province_owner != null and factions.has(province_owner):
			factions[province_owner]["provinces"].append(province_id)

	print("FactionManager: loaded %d factions" % factions.size())


# ─────────────────────────────────────────
#  Province ownership
# ─────────────────────────────────────────
func capture_province(province_id: int, faction_id: int) -> void:
	if not ProvinceManager.provinces.has(province_id):
		push_error("FactionManager: province %d not found" % province_id)
		return

	# remove from previous owner
	var prev_owner = ProvinceManager.get_province_owner(province_id)
	if prev_owner != null and factions.has(prev_owner):
		factions[prev_owner]["provinces"].erase(province_id)

	# assign to new owner
	ProvinceManager.set_province_owner(province_id, faction_id)
	if faction_id >= 0 and factions.has(faction_id):
		if not province_id in factions[faction_id]["provinces"]:
			factions[faction_id]["provinces"].append(province_id)

	province_owner_changed.emit(province_id, faction_id)
	print("FactionManager: province %d captured by faction %d" % [province_id, faction_id])


func release_province(province_id: int) -> void:
	capture_province(province_id, -1)


# ─────────────────────────────────────────
#  Unit tracking
# ─────────────────────────────────────────
func register_unit(faction_id: int, unit) -> void:
	if factions.has(faction_id):
		factions[faction_id]["units"].append(unit)

func unregister_unit(faction_id: int, unit) -> void:
	if factions.has(faction_id):
		factions[faction_id]["units"].erase(unit)

func get_faction_units(faction_id: int) -> Array:
	return factions.get(faction_id, {}).get("units", [])


# ─────────────────────────────────────────
#  Accessors
# ─────────────────────────────────────────
func get_faction(id: int) -> Dictionary:
	return factions.get(id, {})

func get_faction_color(id: int) -> Color:
	return factions.get(id, {}).get("color", Color(0, 0, 0, 0))

func get_faction_name(id: int) -> String:
	return factions.get(id, {}).get("name", "Unknown")

func get_faction_provinces(id: int) -> Array:
	return factions.get(id, {}).get("provinces", [])

func get_province_owner(province_id: int) -> int:
	return ProvinceManager.get_province_owner(province_id) if ProvinceManager.get_province_owner(province_id) != null else -1

func get_all_factions() -> Array:
	return factions.values()
