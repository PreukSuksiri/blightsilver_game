extends Node
## Central BGM manager — one Music-bus player, context defaults, crossfade support.
## Context defaults are loaded from data/bgm_contexts.json (editable via manage_bgm).

signal track_changed(context: String, path: String)

const CONTEXT_MAIN_MENU := "main_menu"
const CONTEXT_PLACEMENT := "placement"
const CONTEXT_BATTLE := "battle"
const CONTEXT_BOSS := "boss"
const CONTEXT_VICTORY := "victory"
const CONTEXT_DEFEAT := "defeat"
const CONTEXT_CREDITS := "credits"
const CONTEXT_DAILY_DUNGEON := "daily_dungeon"
const CONTEXT_VN := "vn_story"
const CONTEXT_CAMPAIGN_MAP := "campaign_map"
const CONTEXT_RESULT := "result"

const CONFIG_PATH := "res://data/bgm_contexts.json"
const DEFAULT_FADE := 0.8

const BUILTIN_DEFAULT_PATHS := {
	CONTEXT_MAIN_MENU: "res://assets/audio/bgm_storytelling_4.mp3",
	CONTEXT_PLACEMENT: "res://assets/audio/bgm_placement_1.mp3",
	CONTEXT_BATTLE: "res://assets/audio/bgm_battle_2.mp3",
	CONTEXT_BOSS: "res://assets/audio/bgm_boss_1.mp3",
	CONTEXT_VICTORY: "res://assets/audio/bgm_win.mp3",
	CONTEXT_DEFEAT: "res://assets/audio/bgm_horror_1.mp3",
	CONTEXT_CREDITS: "res://assets/audio/bgm_ost_blind_cross.mp3",
	CONTEXT_DAILY_DUNGEON: "res://assets/audio/bgm_mystery_1.mp3",
	CONTEXT_VN: "",
	CONTEXT_CAMPAIGN_MAP: "res://assets/audio/bgm_mystery_2.mp3",
	CONTEXT_RESULT: "res://assets/audio/bgm_ost_even_if_everything_flips.mp3",
}

var _default_paths: Dictionary = {}
var _player: AudioStreamPlayer = null
var _fade_tween: Tween = null
var _current_path: String = ""
var _current_context: String = ""
var _target_volume_db: float = 0.0
var _loop_restart_sec: float = -1.0


func _ready() -> void:
	_load_default_paths()
	_player = AudioStreamPlayer.new()
	_player.name = "BGMPlayer"
	_player.bus = &"Music"
	add_child(_player)
	_player.finished.connect(_on_player_finished)


func _load_default_paths() -> void:
	_default_paths = BUILTIN_DEFAULT_PATHS.duplicate(true)
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_warning("BGMManager: invalid JSON in %s" % CONFIG_PATH)
		return
	for ctx: String in _default_paths.keys():
		if parsed.has(ctx):
			_default_paths[ctx] = str(parsed[ctx])


func get_all_contexts() -> Array:
	var keys: Array = _default_paths.keys()
	keys.sort()
	return keys


func get_default_path(context: String) -> String:
	return str(_default_paths.get(context, ""))


func set_default_path(context: String, path: String) -> bool:
	if not _default_paths.has(context):
		return false
	_default_paths[context] = path.strip_edges()
	return true


func save_default_paths() -> String:
	var out: Dictionary = {}
	for ctx: String in get_all_contexts():
		out[ctx] = get_default_path(ctx)
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		return "Failed to write %s" % CONFIG_PATH
	file.store_string(JSON.stringify(out, "\t"))
	file.close()
	return ""


func reset_default_paths() -> void:
	_default_paths = BUILTIN_DEFAULT_PATHS.duplicate(true)
	save_default_paths()


func get_current_path() -> String:
	return _current_path


func get_current_context() -> String:
	return _current_context


func is_playing() -> bool:
	return _player != null and _player.playing


func play_context(
		context: String,
		fade_in: float = DEFAULT_FADE,
		fade_out: float = DEFAULT_FADE,
		volume_pct: float = 100.0,
		loop_from_sec: float = -1.0) -> void:
	var path: String = get_default_path(context)
	if path.is_empty() and context != CONTEXT_VN:
		push_warning("BGMManager: no default track for context '%s'" % context)
		return
	if path.is_empty():
		return
	play_path(path, fade_in, fade_out, volume_pct, context, loop_from_sec)


func play_path(
		path: String,
		fade_in: float = DEFAULT_FADE,
		fade_out: float = DEFAULT_FADE,
		volume_pct: float = 100.0,
		context: String = "",
		loop_from_sec: float = -1.0) -> void:
	path = path.strip_edges()
	if path.is_empty():
		stop(fade_out)
		return

	_target_volume_db = _volume_pct_to_db(volume_pct)
	_loop_restart_sec = loop_from_sec
	_current_context = context

	if path == _current_path and _player.playing:
		_player.volume_db = _target_volume_db
		return

	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("BGMManager: failed to load '%s'" % path)
		return

	_configure_loop(stream, loop_from_sec < 0.0)
	_kill_fade()

	if _player.playing and fade_out > 0.0:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", -80.0, fade_out)
		_fade_tween.tween_callback(func() -> void:
			_begin_stream(stream, path, fade_in, loop_from_sec))
	else:
		_player.stop()
		_begin_stream(stream, path, fade_in, loop_from_sec)


func stop(fade_out: float = DEFAULT_FADE) -> void:
	_kill_fade()
	_loop_restart_sec = -1.0
	_current_context = ""
	if not _player.playing:
		_hard_stop()
		return
	if fade_out <= 0.0:
		_hard_stop()
		return
	_fade_tween = create_tween()
	_fade_tween.tween_property(_player, "volume_db", -80.0, fade_out)
	_fade_tween.tween_callback(_hard_stop)


func fade_out_and_stop(duration: float) -> void:
	stop(duration)
	if duration <= 0.0:
		return
	if _fade_tween != null and _fade_tween.is_valid():
		await _fade_tween.finished


func _begin_stream(stream: AudioStream, path: String, fade_in: float, start_sec: float) -> void:
	_player.stream = stream
	_current_path = path
	track_changed.emit(_current_context, path)
	var start_at: float = maxf(0.0, start_sec)
	if fade_in > 0.0:
		_player.volume_db = -80.0
		_player.play(start_at)
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", _target_volume_db, fade_in)
	else:
		_player.volume_db = _target_volume_db
		_player.play(start_at)


func _hard_stop() -> void:
	if _player == null:
		return
	_player.stop()
	_player.stream = null
	_current_path = ""
	_loop_restart_sec = -1.0


func _kill_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func _on_player_finished() -> void:
	if _loop_restart_sec >= 0.0:
		_player.play(_loop_restart_sec)
	elif _player.stream != null and not _stream_loops(_player.stream):
		_player.play()


func _configure_loop(stream: AudioStream, should_loop: bool) -> void:
	if not should_loop:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true


func _stream_loops(stream: AudioStream) -> bool:
	if stream is AudioStreamMP3:
		return (stream as AudioStreamMP3).loop
	if stream is AudioStreamOggVorbis:
		return (stream as AudioStreamOggVorbis).loop
	return false


func _volume_pct_to_db(volume_pct: float) -> float:
	if volume_pct <= 0.0:
		return -80.0
	return linear_to_db(clampf(volume_pct, 0.0, 100.0) / 100.0)
