extends Node
## SFXManager — central one-shot UI sound effect player.
## Call SFXManager.play(SFXManager.SFX_*) anywhere in the game.

const SFX_MENU        := preload("res://assets/audio/sfx/scifi_ui_1.mp3")   # Rule 1: main menu buttons
const SFX_BTN         := preload("res://assets/audio/sfx/scifi_ui_2.mp3")   # Rule 2: generic game buttons
const SFX_CANCEL      := preload("res://assets/audio/sfx/scifi_ui_12.mp3")  # Rule 3: cancel / dismiss
const SFX_TARGET      := preload("res://assets/audio/sfx/scifi_ui_13.mp3")  # Rule 4: select target
const SFX_POPUP       := preload("res://assets/audio/sfx/scifi_ui_30.mp3")  # Rule 5: warning / choice popup
const SFX_UNION_FLASH := preload("res://assets/audio/sfx/scifi_ui_38.mp3")  # Rule 6: union zone flash
const SFX_CARD_INFO   := preload("res://assets/audio/sfx/scifi_ui_18.mp3")  # Rule 7: card info (gallery/setup)
const SFX_CARD_DETAIL := preload("res://assets/audio/sfx/scifi_ui_15.mp3")  # Rule 11: battle info context menu
const SFX_CRYSTAL_GAIN := preload("res://assets/audio/sfx/scifi_ui_24.mp3") # Rule 13: gain crystals
const SFX_PLACE       := preload("res://assets/audio/sfx/scifi_ui_9.mp3")   # Rule 14: setup card placed into grid
const SFX_REMOVE      := preload("res://assets/audio/sfx/scifi_ui_8.mp3")   # Rule 15: setup card removed from grid
const SFX_EXPLORATION := preload("res://assets/audio/sfx/scifi_ui_8.mp3")   # Exploration UI interactions
const SFX_EXPLORATION_ITEM   := preload("res://assets/audio/sfx/mystery_2.mp3")  # Exploration item obtained
const SFX_EXPLORATION_REWARD := preload("res://assets/audio/sfx/item_1.mp3")     # Exploration credits / booster pack
const SFX_BLUFF_PLACE  := preload("res://assets/audio/sfx/pop3.mp3")         # assign bluff to cell
const SFX_BLUFF_REMOVE := preload("res://assets/audio/sfx/pop2.mp3")         # remove bluff from cell
const SFX_UNION_LAND  := preload("res://assets/audio/sfx/clash1.mp3")       # Rule 9: union fire spark & dust
const SFX_DESTROY     := preload("res://assets/audio/sfx/explosion3.mp3")   # Rule 10: card node destroyed (character)
const SFX_DISSOLVE    := preload("res://assets/audio/sfx/acid1.mp3")         # dead_end / trap dissolved
const SFX_UNION_SHOCKWAVE := preload("res://assets/audio/sfx/scifi_ui_31.mp3") # Rule 22: union shockwave
const SFX_TURN_BANNER := preload("res://assets/audio/sfx/scifi_ui_39.mp3")   # Rule 18: Player x's Turn banner
const SFX_COIN_FLIP   := preload("res://assets/audio/sfx/coin_clink_2.mp3")  # Rule 19: coin flip starts
const SFX_COIN_HEAD   := preload("res://assets/audio/sfx/coin_flip_head.mp3") # Rule 20: landed heads
const SFX_COIN_TAIL   := preload("res://assets/audio/sfx/coin_flip_tail.mp3") # Rule 21: landed tails
const SFX_CREDIT_CLINK := preload("res://assets/audio/sfx/coin_clink_4b.mp3") # Mailbox / credit earn
const SFX_BATTLE_CALC := preload("res://assets/audio/sfx/chime_4.mp3")         # Rule 23: battle calculation overlay opens
const SFX_MODIFIER_REVEAL := preload("res://assets/audio/sfx/scifi_ui_34.mp3") # wheel spin result reveal

func play(stream: AudioStream) -> void:
	if stream == null:
		return
	var asp := AudioStreamPlayer.new()
	asp.stream = stream
	asp.bus = "SFX"
	add_child(asp)
	asp.play()
	asp.finished.connect(asp.queue_free)
