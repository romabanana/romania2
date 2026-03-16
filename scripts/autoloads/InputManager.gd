extends Node

# ─────────────────────────────────────────
#  InputManager — Autoload
#  All keyboard input in one place.
#  Add new bindings in _input()
# ─────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	match event.keycode:
		# ── Gameplay ──────────────────────
		KEY_ESCAPE:
			SelectionManager.deselect_all()
		KEY_SPACE: GameClock.toggle_pause()
		
		KEY_ALT:
			if SelectionManager.selected_unit:
				SelectionManager.selected_unit.cancel_movement()

		# ── Debug ─────────────────────────
		KEY_F1:
			var panel := get_tree().get_first_node_in_group("debug_panel")
			if panel:
				panel.toggle_visibility()
