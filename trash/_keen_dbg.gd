extends Node
func _ready() -> void:
	# Mimic omen_wire_smoke preamble lightly then keen edge block
	GameState._init_grids()
	OmenBattleApplier.reset_runtime_fields()
	GameState.active_omens = [{"id":"second_skin","anointed_card":"Test Unit"}]
	OmenBattleApplier._build_anoint_effects_map()
	GameState.active_omens = [{"id":"keen_edge","anointed_card":"Death Knight","owner":0}]
	OmenBattleApplier.rebuild_anoint_effects_map()
	GameState.new_game(GameState.GameMode.EXPLORATION)
	print("omens=", GameState.active_omens)
	print("map empty?", GameState.omen_anoint_effects.is_empty(), GameState.omen_anoint_effects.keys())
	var data = CardDatabase.get_character("Death Knight")
	print("dk data null?", data == null)
	GameState.place_character(0, 2, 2, "Death Knight")
	var dk = GameState.get_card(0, 2, 2)
	print("placed=", dk.card_type, dk.card_name, "atk", dk.get_effective_atk())
	var dk_atk0 = dk.get_effective_atk()
	OmenBattleApplier.reset_runtime_fields()
	OmenBattleApplier.apply_begin_game(null)
	dk = GameState.get_card(0, 2, 2)
	print("result perm=", dk.perm_atk_bonus, "eff=", dk.get_effective_atk(), "map=", GameState.omen_anoint_effects.keys())
	get_tree().quit(0)
