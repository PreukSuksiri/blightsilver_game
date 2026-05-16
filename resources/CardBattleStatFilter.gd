class_name CardBattleStatFilter
extends Resource

## Restrict a rule trigger to fire only when battle ATK/DEF meet these conditions.
## Any field left at -1 is ignored.

@export var attacker_min_atk: int = -1
@export var attacker_max_atk: int = -1
@export var defender_min_def: int = -1
@export var defender_max_def: int = -1
@export var atk_exceeds_def_by: int = -1   # fire only when ATK - DEF >= this value
@export var def_exceeds_atk_by: int = -1   # fire only when DEF - ATK >= this value
