class_name CardNodeFilter
extends Resource

enum OwnerFilter { ANY, SELF_PLAYER, OPPONENT_PLAYER }
enum TypeFilter  { ANY, CHARACTER, TRAP, DEAD_END }
enum FaceFilter  { ANY, FACE_UP, FACE_DOWN }
enum RarityFilter { ANY, COMMON, UNCOMMON, RARE, LEGENDARY }

@export var owner:  OwnerFilter  = OwnerFilter.ANY
@export var type:   TypeFilter   = TypeFilter.ANY
@export var face:   FaceFilter   = FaceFilter.ANY
@export var rarity: RarityFilter = RarityFilter.ANY
@export var has_flag:   String = ""   # empty = ignore
@export var lacks_flag: String = ""
@export var affinity: int = -1        # -1 = any; maps to CharacterData.Affinity
@export var min_atk: int = -1
@export var max_atk: int = -1
@export var min_def: int = -1
@export var max_def: int = -1
