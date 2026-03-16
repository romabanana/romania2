extends Node

# ─────────────────────────────────────────
#  PlayerController — Autoload
#  Represents the human player.
#  faction_id is set before game starts.
#  Later: set from faction selection screen.
# ─────────────────────────────────────────

var faction_id : int = 1  # player controls faction 1 by default


func is_player_faction(id: int) -> bool:
	return id == faction_id
