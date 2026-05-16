class_name CardRule
extends Resource

## CardRule — one trigger → effect → deactivation triplet.
## Attach an Array of CardRules to a CardInstance.active_rules.
## CardRuleEngine evaluates and executes them.

# ─────────────────────────────────────────────────────────────
# Enums
# ─────────────────────────────────────────────────────────────

enum Scope {
	SELF,   # Only this card can satisfy the trigger
	FIELD,  # Any matching card on the field can satisfy the trigger
}

enum TriggerType {
	# ── Crystal ──
	CRYSTAL_GAIN_OWNER,
	CRYSTAL_LOSE_OWNER,
	CRYSTAL_GAIN_OPPONENT,
	CRYSTAL_LOSE_OPPONENT,
	CRYSTAL_THRESHOLD_OWNER,    # params: {threshold: int, direction: "above"|"below"}
	CRYSTAL_THRESHOLD_OPPONENT,

	# ── Card state ──
	CARD_FACE_UP_SELF,           # this card is flipped face-up
	CARD_FACE_UP_ANY_OWNER,      # any of owner's cards flipped face-up
	CARD_FACE_UP_ANY_OPPONENT,   # any of opponent's cards flipped face-up
	CARD_PLACED_OWNER,           # any card placed in owner's grid
	CARD_PLACED_OPPONENT,
	CARD_DESTROYED_SELF,         # this card is destroyed
	CARD_DESTROYED_ANY_OWNER,
	CARD_DESTROYED_ANY_OPPONENT,
	CARD_FLAG_ADDED,             # params: {flag: String} — a matching flag was added
	CARD_FLAG_REMOVED,

	# ── Battle ──
	BATTLE_ATTACK_INITIATED_SELF,     # this card is the attacker
	BATTLE_ATTACK_INITIATED_ANY_OWNER,# any of owner's cards attacks
	BATTLE_DEFEND_SELF,               # this card is the defender
	BATTLE_DEFEND_ANY_OWNER,
	BATTLE_WIN_SELF,
	BATTLE_LOSE_SELF,
	BATTLE_TIE_SELF,
	BATTLE_WIN_ANY_OWNER,
	BATTLE_LOSE_ANY_OWNER,
	BATTLE_ATTACK_DEAD_END_DONE,      # owner attacked a dead_end cell
	BATTLE_ATTACK_EXPOSED_CARD,       # defender was already face-up before this attack began (Exposed = dust settled; Revealed = this attack flipped it)
	BATTLE_ATTACK_TRAP_TRIGGERED,
	BATTLE_PRE_RESOLVE,               # chain hook: fires before BattleResult is finalised

	# ── Turn ──
	TURN_START_OWNER,
	TURN_START_OPPONENT,
	TURN_END_OWNER,
	TURN_END_OPPONENT,
	TURN_END_OWNER_NTH,     # params: {n: int} — fires when owner ends their Nth turn
	TURN_END_OPPONENT_NTH,

	# ── Mode ──
	MODE_ATTACK_SELECTED_OWNER,
	MODE_TECH_SELECTED_OWNER,

	# ── Tech ──
	TECH_CARD_USED_OWNER,
	TECH_CARD_USED_OPPONENT,
	PLAYER_SELECT_TECH_TARGET,  # player is about to choose a tech target
	CARD_TARGETED_BY_TECH,      # this card was chosen as a tech target

	# ── Misc ──
	ATTACKS_USED_COUNT,  # params: {filter: AttackCountFilter, count: int (for EXACT)}
	PHASE_SETUP_END,
	ALWAYS,              # fires every turn start — use for persistent passive effects
}

enum EffectType {
	ATK_MOD,            # params: {amount: int, target: String}
	DEF_MOD,
	ATK_MOD_PERCENT,    # params: {percent: float, target: String}
	DEF_MOD_PERCENT,
	DESTROY_CARD,       # params: {target: String, pay_cost: bool}
	REVEAL_CARD,        # params: {target: String}
	GAIN_CRYSTALS,      # params: {player: String, amount: int}
	LOSE_CRYSTALS,
	SKIP_TURN,          # params: {player: String}
	CANNOT_ATTACK,      # params: {target: String, turns: int}
	NULLIFY_EFFECT,     # params: {target: String, turns: int}
	APPLY_FLAG,         # params: {target: String, flag: String}
	REMOVE_FLAG,        # params: {target: String, flag: String}
	FORCE_SHIELD,       # params: {target: String}
	HALVE_STATS,        # params: {target: String}
	DRAW_TECH,          # params: {player: String, count: int}
	DISCARD_TECH,       # params: {player: String, count: int}
	PLACE_TOKEN,        # params: {player: String, row: int, col: int, atk: int, def: int}
	ATK_DEBUFF,         # params: {target: String, amount: int}
	RECALCULATE_BATTLE, # chain: recalculate ATK vs DEF after other effects applied
	POST_MESSAGE,       # params: {text: String}
}

enum DeactivationType {
	NEVER,
	TURN_END_OWNER,
	TURN_END_OPPONENT,
	TURN_END_OWNER_NTH,    # params: {n: int}
	TURN_END_OPPONENT_NTH,
	ON_SELF_DESTROYED,
	ON_FLAG_PRESENT,       # params: {flag: String} — deactivate while this flag exists
	ON_FLAG_ABSENT,        # params: {flag: String} — deactivate when flag is gone
	ON_EFFECT_USED,        # single-use: deactivates immediately after firing once
}

## target strings understood by CardRuleEngine (used in effect_params["target"] etc.)
##   "self"           — the card that owns this rule
##   "attacker"       — the attacking card in battle context
##   "defender"       — the defending card in battle context
##   "owner_all"      — all of owner's cards on the grid
##   "opponent_all"   — all of opponent's cards on the grid
##   "owner_random"   — one random card from owner's grid
##   "opponent_random"— one random card from opponent's grid
##   "owner"          — the player who owns this card
##   "opponent"       — the opposing player

enum AttackCountFilter { ANY, FIRST_ONLY, SECOND_PLUS, EXACT }

# ─────────────────────────────────────────────────────────────
# Exports
# ─────────────────────────────────────────────────────────────

@export var trigger: TriggerType = TriggerType.ALWAYS
@export var trigger_params: Dictionary = {}

## SELF = only fires when THIS card is involved.
## FIELD = fires when any card matching node_filter is involved.
@export var scope: Scope = Scope.SELF

## Optional extra filter on which cards can match.
@export var node_filter: CardNodeFilter = null
## Optional extra filter based on battle ATK/DEF values.
@export var stat_filter: CardBattleStatFilter = null

@export var effect: EffectType = EffectType.POST_MESSAGE
@export var effect_params: Dictionary = {}

@export var deactivation: DeactivationType = DeactivationType.NEVER
@export var deactivation_params: Dictionary = {}

## Higher priority = evaluated and pushed onto chain earlier.
@export var priority: int = 0
