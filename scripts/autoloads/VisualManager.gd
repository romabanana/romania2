extends Node

# ─────────────────────────────────────────
#  VisualManager — Autoload
#  Owns references to all visual overlay
#  nodes and exposes toggle methods.
#  Register nodes from Main._ready()
# ─────────────────────────────────────────

# layer_name → CanvasItem node
var _layers : Dictionary = {}
var _shader_params : Dictionary = {}  # "layer_name" → {node, param, default}


# ─────────────────────────────────────────
#  Registration
# ─────────────────────────────────────────
func register(layer_name: String, node: CanvasItem) -> void:
	_layers[layer_name] = node
	print("VisualManager: registered '%s'" % layer_name)


# ─────────────────────────────────────────
#  Toggle
# ─────────────────────────────────────────
func toggle(layer_name: String) -> void:
	if not _layers.has(layer_name):
		push_error("VisualManager: '%s' not registered" % layer_name)
		return
	_layers[layer_name].visible = !_layers[layer_name].visible


func set_visible(layer_name: String, value: bool) -> void:
	if not _layers.has(layer_name):
		push_error("VisualManager: '%s' not registered" % layer_name)
		return
	_layers[layer_name].visible = value


func is_visible(layer_name: String) -> bool:
	if not _layers.has(layer_name):
		return false
	return _layers[layer_name].visible


func get_layer(layer_name: String) -> CanvasItem:
	return _layers.get(layer_name, null)


# hide all overlays at once
func hide_all() -> void:
	for layer_name in _layers:
		_layers[layer_name].visible = false


# show all overlays at once
func show_all() -> void:
	for layer_name in _layers:
		_layers[layer_name].visible = true

# Shader

func register_shader(layer_name: String, node: CanvasItem, param: String, default_value) -> void:
	_shader_params[layer_name] = {"node": node, "param": param, "default": default_value}

func set_shader_param(layer_name: String, value) -> void:
	if not _shader_params.has(layer_name):
		return
	var entry : Dictionary = _shader_params[layer_name]
	entry["node"].material.set_shader_parameter(entry["param"], value)

func toggle_shader_param(layer_name: String) -> void:
	if not _shader_params.has(layer_name):
		return
	var entry : Dictionary = _shader_params[layer_name]
	var current = entry["node"].material.get_shader_parameter(entry["param"])
	set_shader_param(layer_name, 0.0 if current > 0.0 else entry["default"])

func get_shader_param(layer_name: String):
	if not _shader_params.has(layer_name):
		return null
	var entry : Dictionary = _shader_params[layer_name]
	return entry["node"].material.get_shader_parameter(entry["param"])
