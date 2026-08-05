extends Node

## Global game manager for NAEON
## Holds faction, contribution, knowledge etc. later

enum Faction { CYBERNEX, GROT, NEUTRAL }

var player_faction: Faction = Faction.CYBERNEX
var contribution: float = 0.0
var knowledge_rank: int = 0

func _ready() -> void:
	print("[GameManager] NAEON initialized")
