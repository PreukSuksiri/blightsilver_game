extends Node
## Smoke test for battle flag badge wiring.
##   godot --headless --path . res://tools/flag_badge_smoke.tscn

var _failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok   ", what)
	else:
		_failures.append(what)
		print("  FAIL ", what)


func _ready() -> void:
	print("flag_badge_smoke…")
	var icons: Array[String] = [
		"ui_icon_flag_mutagen.png",
		"ui_icon_flag_venom.png",
		"ui_icon_flag_berserk.png",
		"ui_icon_flag_princess.png",
		"ui_icon_flag_europa.png",
	]
	for name: String in icons:
		var tex: Texture2D = HudSkin.hud_tex(name)
		_check(tex != null, "HudSkin loads %s" % name)

	var defs: Dictionary = {
		"mutagen": true, "venom": true, "berserk": true, "princess": true, "europa": true,
	}
	for raw: String in ["Europa", "europa", "EUROPA", " princess "]:
		var key: String = raw.strip_edges().to_lower()
		_check(key in defs, "normalize %s → %s" % [raw, key])

	for pair: Array in [
		["Europa", "Europa Flag"],
		["princess", "Princess Flag"],
		["mutagen", "Mutagen Flag"],
		["venom", "Venom Flag"],
		["berserk", "Berserk Flag"],
	]:
		var got: String = BattleLogFormat._overlay_flag_label(str(pair[0]))
		_check(got == str(pair[1]), "label %s → %s" % [pair[0], got])

	for flag: String in ["venom", "mutagen", "berserk", "princess", "Europa"]:
		_check(GameState.is_unit_effect_flag(flag), "UNIT_EFFECT_FLAGS has %s" % flag)

	# Instantiate a Card and refresh badges for multi-flag + Europa case.
	var card_scene: PackedScene = load("res://scenes/card.tscn") as PackedScene
	_check(card_scene != null, "card.tscn loads")
	if card_scene != null:
		var node: Card = card_scene.instantiate() as Card
		add_child(node)
		await get_tree().process_frame
		var inst := GameState.CardInstance.new()
		inst.card_type = "character"
		inst.card_name = "Smoke Flag Unit"
		inst.face_up = true
		inst.flags = ["mutagen", "venom", "Europa", "princess"]
		node.card_data = inst
		node._is_enemy_view = false
		node._refresh_flag_badges()
		await get_tree().process_frame
		var bar: HBoxContainer = node.get("_flag_bar") as HBoxContainer
		_check(bar != null and bar.visible, "flag bar visible with 4 flags")
		_check(bar != null and bar.get_child_count() == 4, "flag bar child count == 4")
		if bar != null:
			var keys: Array[String] = []
			for child: Node in bar.get_children():
				keys.append(str(child.get_meta("flag_name", "")))
				_check(child is Control and child.get_child_count() > 0, "badge host has TextureRect")
				var icon: Node = child.get_child(0)
				_check(icon is TextureRect and (icon as TextureRect).texture != null, "badge texture set")
			_check("europa" in keys, "Europa normalized to europa meta")
			_check("princess" in keys, "princess badge present")
		# Pop animation path should resolve for capital Europa.
		node.play_flag_badge_pop("Europa")
		await get_tree().create_timer(0.05).timeout
		# Enemy view hides bar.
		node._is_enemy_view = true
		node._refresh_flag_badges()
		_check(bar != null and not bar.visible, "enemy view hides flag bar")
		node.queue_free()

	print("")
	if _failures.is_empty():
		print("SMOKE OK")
		get_tree().quit(0)
	else:
		print("SMOKE FAILED: ", _failures)
		get_tree().quit(1)


func _exit_tree() -> void:
	pass
