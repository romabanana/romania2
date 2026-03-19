@tool
extends Node

@export_group("Paths")
@export_file("*.png") var input_image_path: String = "res://maps/data_provinces.png"
@export var output_json_path: String = "res://data/test_provinces.json"

@export_group("Action")
@export var start_generation: bool = false : set = _run_generation

func _run_generation(_val):
	if not Engine.is_editor_hint(): return
	generate_province_json()

func generate_province_json():
	if input_image_path == "" or not FileAccess.file_exists(input_image_path):
		printerr("Error: image not found")
		return

	var image = Image.load_from_file(input_image_path)
	if not image:
		printerr("Error: can not load image")
		return

	var width = image.get_width()
	var height = image.get_height()
	
	var unique_colors = {}
	
	print("Scanning pixels (", width, "x", height, ")...")
	
	for y in height:
		for x in width:
			var pixel = image.get_pixel(x, y)
			
			if pixel.a > 0.05:
				var hex = "%02x%02x%02x" % [
					int(pixel.r * 255),
					int(pixel.g * 255),
					int(pixel.b * 255)
				]
				
				if not unique_colors.has(hex):
					unique_colors[hex] = true

	print("scan complete, ", unique_colors.size(), " unique colors found")

	# ---  JSON  ---
	var json_data = {}
	var id_counter = 0
	var existing_data = _load_existing_json()
	
	var sorted_hex = unique_colors.keys()
	sorted_hex.sort()
	
	for hex in sorted_hex:
		if existing_data.has(hex):
			var d = existing_data[hex]
			json_data[hex] = {
				"id": int(d.get("id", id_counter)),
				"owner": int(d.get("owner", 0)),
				"name": str(d.get("name", "Province_" + str(id_counter)))
			}
		else:
			json_data[hex] = {
				"id": int(id_counter),
				"owner": 0,
				"name": "Province_" + str(id_counter)
			}
		id_counter += 1

	# --- save files ---
	var file = FileAccess.open(output_json_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(json_data, "\t") # 使用制表符美化输出
		file.store_string(json_string)
		file.close()
		print("json file saved in: ", output_json_path)
	else:
		printerr("Error: cannot save json")

func _load_existing_json() -> Dictionary:
	if FileAccess.file_exists(output_json_path):
		var file = FileAccess.open(output_json_path, FileAccess.READ)
		var test_json = JSON.new()
		var error = test_json.parse(file.get_as_text())
		if error == OK:
			return test_json.get_data()
	return {}
