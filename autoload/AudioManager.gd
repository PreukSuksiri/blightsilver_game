extends Node
## Global audio volume manager.
## Creates "Music" and "SFX" buses on startup.
## All AudioStreamPlayers in the game must set bus = "Music" or bus = "SFX".
## Changing volume here instantly affects every player on that bus.

const SETTINGS_PATH := "user://audio_settings.json"

var music_volume: float = 0.8   # 0.0 – 1.0
var sfx_volume:   float = 1.0   # 0.0 – 1.0
var tts_enabled:  bool  = false

var _tts_voice: String = ""

# ── BGM filter state ──────────────────────────────────────────
var _hp_filter: AudioEffectHighPassFilter = null
var _lp_filter: AudioEffectLowPassFilter  = null
var _filter_tween: Tween = null

const _HP_NEUTRAL: float = 1.0       # effectively off (let all through)
const _HP_ACTIVE:  float = 500.0     # cuts bass — music sounds thin/focused
const _LP_NEUTRAL: float = 20500.0   # effectively off (let all through)
const _LP_ACTIVE:  float = 800.0     # cuts treble — music sounds muffled
const _FILTER_FADE: float = 0.5      # seconds for gradual transition

func _ready() -> void:
	_ensure_buses()
	_load_settings()
	_apply()
	_tts_voice = _pick_tts_voice()
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		# Only restore on natural finish — canceled is handled directly in tts_stop()
		# to avoid a race where a new speak() ducks music after the cancel-restore fires
		DisplayServer.tts_set_utterance_callback(
			DisplayServer.TTS_UTTERANCE_ENDED, func(_id: int) -> void: call_deferred("_restore_music"))

# ── Bus setup ─────────────────────────────────────────────────

func _ensure_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")
	_ensure_music_filters()

func _ensure_music_filters() -> void:
	var m: int = AudioServer.get_bus_index("Music")
	if m < 0:
		return
	# Remove any stale effects (e.g. from hot reload) then add fresh ones
	while AudioServer.get_bus_effect_count(m) > 0:
		AudioServer.remove_bus_effect(m, 0)
	_hp_filter = AudioEffectHighPassFilter.new()
	_hp_filter.cutoff_hz = _HP_NEUTRAL
	AudioServer.add_bus_effect(m, _hp_filter)
	_lp_filter = AudioEffectLowPassFilter.new()
	_lp_filter.cutoff_hz = _LP_NEUTRAL
	AudioServer.add_bus_effect(m, _lp_filter)

# ── Public BGM filter API ──────────────────────────────────────

## Apply a high-pass filter to the Music bus (cuts bass; music sounds thin/focused).
## gradual=true tweens the cutoff over _FILTER_FADE seconds; false = instant.
func apply_high_pass(gradual: bool = true) -> void:
	_transition_filter(_HP_ACTIVE, _LP_NEUTRAL, gradual)

## Apply a low-pass filter to the Music bus (cuts treble; music sounds muffled).
## gradual=true tweens the cutoff over _FILTER_FADE seconds; false = instant.
func apply_low_pass(gradual: bool = true) -> void:
	_transition_filter(_HP_NEUTRAL, _LP_ACTIVE, gradual)

## Remove any active BGM filter, restoring the Music bus to its original state.
## gradual=true tweens back over _FILTER_FADE seconds; false = instant.
func remove_bgm_filter(gradual: bool = true) -> void:
	_transition_filter(_HP_NEUTRAL, _LP_NEUTRAL, gradual)

func _transition_filter(target_hp: float, target_lp: float, gradual: bool) -> void:
	if _filter_tween and _filter_tween.is_valid():
		_filter_tween.kill()
	if not gradual or _hp_filter == null or _lp_filter == null:
		if _hp_filter:
			_hp_filter.cutoff_hz = target_hp
		if _lp_filter:
			_lp_filter.cutoff_hz = target_lp
		return
	_filter_tween = create_tween()
	_filter_tween.tween_method(
		func(v: float) -> void: _hp_filter.cutoff_hz = v,
		_hp_filter.cutoff_hz, target_hp, _FILTER_FADE
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_filter_tween.parallel().tween_method(
		func(v: float) -> void: _lp_filter.cutoff_hz = v,
		_lp_filter.cutoff_hz, target_lp, _FILTER_FADE
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _apply() -> void:
	var m := AudioServer.get_bus_index("Music")
	var s := AudioServer.get_bus_index("SFX")
	if m >= 0:
		AudioServer.set_bus_volume_db(m, linear_to_db(music_volume))
	if s >= 0:
		AudioServer.set_bus_volume_db(s, linear_to_db(sfx_volume))

# ── Public setters ────────────────────────────────────────────

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(music_volume))
	_save_settings()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	var idx := AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(sfx_volume))
	_save_settings()

func set_tts_enabled(v: bool) -> void:
	tts_enabled = v
	if not tts_enabled:
		tts_stop()
	_save_settings()

# ── Text-to-speech ────────────────────────────────────────────

func speak(text: String) -> void:
	if not tts_enabled:
		return
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	DisplayServer.tts_stop()
	_duck_music()
	DisplayServer.tts_speak(_expand_abbreviations(text), _tts_voice, 100, 1.0, 0.72, 0, true)

func _expand_abbreviations(text: String) -> String:
	var result := text \
		.replace("ATK", "Attack") \
		.replace("DEF", "Defense") \
		.replace("HP",  "Health") \
		.replace("◆",   "crystals") \
		.replace(" vs ", " against ") \
		.replace("x2", "double") \
		.replace("x3", "triple")
	var rx := RegEx.new()
	rx.compile(r"[+\-]\d+")
	var output := ""
	var pos := 0
	for m: RegExMatch in rx.search_all(result):
		output += result.substr(pos, m.get_start() - pos)
		var matched := m.get_string()
		var word := "increase" if matched[0] == "+" else "decrease"
		output += "%s %s" % [word, matched.substr(1)]
		pos = m.get_start() + m.get_string().length()
	output += result.substr(pos)
	return output

func tts_stop() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_stop()
	_restore_music()

func _duck_music() -> void:
	# 50% of current setting, rounded down to nearest whole percent
	var ducked := floorf(music_volume * 50.0) / 100.0
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(ducked))

func _restore_music() -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(music_volume))

func _pick_tts_voice() -> String:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return ""
	var all_voices: Array[Dictionary] = DisplayServer.tts_get_voices()
	# Prefer English voices; fall back to any language
	var voices: Array[Dictionary] = all_voices.filter(
		func(v: Dictionary) -> bool: return (v.get("language", "") as String).begins_with("en"))
	if voices.is_empty():
		voices = all_voices
	# Prefer common female voice names across platforms
	var female_hints := ["samantha", "karen", "victoria", "zira", "hazel",
						 "susan", "female", "woman", "moira", "tessa", "fiona"]
	for hint: String in female_hints:
		for voice: Dictionary in voices:
			if hint in (voice["name"] as String).to_lower():
				return voice["id"] as String
	if not voices.is_empty():
		return voices[0]["id"] as String
	return ""

# ── Persistence ───────────────────────────────────────────────

func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"music_volume": music_volume,
			"sfx_volume":   sfx_volume,
			"tts_enabled":  tts_enabled,
		}))
		file.close()

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	music_volume = clampf(float(parsed.get("music_volume", 0.8)),  0.0, 1.0)
	sfx_volume   = clampf(float(parsed.get("sfx_volume",   1.0)),  0.0, 1.0)
	tts_enabled  = bool(parsed.get("tts_enabled", false))
