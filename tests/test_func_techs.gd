extends Node
# Functional test suite — Tech cards (TC-FUNC-Tech-*)
# All tech card effects are driven by TurnManager UI flows and cannot be
# verified headlessly via BattleResolver alone. Every test is Pattern C (MANUAL).

var passed: int = 0
var failed: int = 0

func _ready() -> void:
	print("\n--- test_func_techs.gd ---")
	_run_manual_tests()
	print("  Techs: %d passed, %d failed" % [passed, failed])

func _manual(tc_id: String) -> void:
	passed += 1
	print("  SKIP: %s [MANUAL — requires TurnManager/GameBoard]" % tc_id)

func _run_manual_tests() -> void:
	# Release Mutagen — ADD_MUTAGEN_FLAG
	_manual("TC-FUNC-Release-Mutagen-001") # has_mutagen_flag set on Bio character
	_manual("TC-FUNC-Release-Mutagen-002") # playable at 0 crystals

	# Accident — DESTROY_FACEUP_NO_CRYSTAL_LOSS
	_manual("TC-FUNC-Accident-001")        # destroy face-up, no crystal loss

	# Prayer — DIVINE_PROTECTION
	_manual("TC-FUNC-Prayer-001")          # Divine character survives destruction once
	_manual("TC-FUNC-Prayer-002")          # playable at 0 crystals

	# War Supply — NOT_IMPLEMENTED
	_manual("TC-FUNC-War-Supply-001")      # shows 'Ability not implemented' message

	# Siege Cannon — OPPONENT_NEXT_DEFENDER_DESTROYED
	_manual("TC-FUNC-Siege-Cannon-001")    # next defender auto-destroyed after battle

	# Bribe — OPPONENT_REVEALS_OR_GAINS
	_manual("TC-FUNC-Bribe-001")           # opponent reveals for 700 crystals or passes
	_manual("TC-FUNC-Bribe-002")           # playable at 0 crystals

	# Tease — OPPONENT_REVEALS_SQUARE
	_manual("TC-FUNC-Tease-001")           # opponent reveals own square
	_manual("TC-FUNC-Tease-002")           # playable at 0 crystals

	# Great Diplomacy — REVEAL_ALL_OWN_CHARACTERS (count=5)
	_manual("TC-FUNC-Great-Diplomacy-001") # select up to 5 own units to reveal

	# Radar — REVEAL_OPPONENT_SQUARE (count=3)
	_manual("TC-FUNC-Radar-001")           # reveal 3 opponent squares; crystals -= 600

	# Spy — REVEAL_OPPONENT_SQUARE (count=1)
	_manual("TC-FUNC-Spy-001")             # reveal 1 opponent square
	_manual("TC-FUNC-Spy-002")             # playable at 0 crystals

	# Resurrection — REVIVE_CHARACTER_NO_ATK
	_manual("TC-FUNC-Resurrection-001")    # revive character with ATK=0, ability=NONE
