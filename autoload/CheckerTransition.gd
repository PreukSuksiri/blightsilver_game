extends CanvasLayer
## Fog-edge transition used when entering exploration / card battles.
## Fade-out: call fade_out_to_battle(callback) — soft fog fills the screen,
##           then callback is invoked (do scene change there).
## Fade-in:  call fade_in() from GameBoard._ready() — fog clears over the new scene.

const DURATION      := 0.95   # seconds for cover / uncover
const FOG_TAIL      := 0.88   # long leading-edge mist (fraction of diagonal)
const SOUND_PATH    := "res://assets/audio/sound_spellcasting_3.mp3"
const FOG_NOISE     := "res://assets/textures/effect/fog/Noise 3.png"
const SHADER_PATH   := "res://assets/shaders/fog_wipe_transition.gdshader"
const DEFAULT_LAYER := 200
const COVER_LAYER   := 400     # above VN overlay (300) during battle handoff

var _cover: ColorRect = null
var _mat: ShaderMaterial = null
var _sfx: AudioStreamPlayer
var _anim_gen: int = 0   # incremented on each new animation; stale coroutines bail early
var _scroll_a: Vector2 = Vector2.ZERO
var _scroll_b: Vector2 = Vector2.ZERO
var _scrolling: bool = false

func _ready() -> void:
	layer        = DEFAULT_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx         = AudioStreamPlayer.new()
	_sfx.stream  = load(SOUND_PATH)
	_sfx.bus     = "SFX"
	add_child(_sfx)

func _process(delta: float) -> void:
	if not _scrolling or _mat == null:
		return
	_scroll_a += Vector2(0.11, 0.045) * delta
	_scroll_b += Vector2(0.07, -0.038) * delta
	_mat.set_shader_parameter("scroll_a", _scroll_a)
	_mat.set_shader_parameter("scroll_b", _scroll_b)

# ── Public API ──────────────────────────────────────────────────

## Cover the screen with fog, play the transition sound,
## then call on_black (which should change the scene).
func fade_out_to_battle(on_black: Callable) -> void:
	layer = COVER_LAYER
	_build_cover(false)
	_sfx.play()
	await _animate(true)
	if not on_black.is_valid():
		push_warning("CheckerTransition: fade_out callback is invalid — scene change skipped.")
		# Never leave the cover stuck (would freeze the game on a black screen).
		_clear_cover()
		layer = DEFAULT_LAYER
		return
	on_black.call()

## Scene change helper — safe to call from nodes that queue_free() immediately after.
func fade_out_to_scene(scene_path: String) -> void:
	if MainMenuReturnLoader.is_main_menu_path(scene_path):
		MainMenuReturnLoader.fade_out_to_main_menu()
		return
	fade_out_to_battle(get_tree().change_scene_to_file.bind(scene_path))

## True while fog from fade_out_to_battle is still covering the screen.
func is_screen_covered() -> bool:
	return _cover != null and is_instance_valid(_cover)

## Uncover the screen (call after fade_out_to_battle when the target is not GameBoard).
## If cover doesn't exist yet (no prior fade_out was run), builds it fully covered first.
func fade_in() -> void:
	if not is_screen_covered():
		layer = COVER_LAYER
		_build_cover(true)
	await _animate(false)
	_clear_cover()
	layer = DEFAULT_LAYER

# ── Internals ───────────────────────────────────────────────────

func _build_cover(start_covered: bool) -> void:
	_anim_gen += 1
	_clear_cover()
	var vp_size: Vector2 = get_viewport().get_visible_rect().size

	var shader: Shader = load(SHADER_PATH) as Shader
	var noise: Texture2D = load(FOG_NOISE) as Texture2D
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	if noise != null:
		_mat.set_shader_parameter("fog_noise", noise)
	_mat.set_shader_parameter("fog_tail", FOG_TAIL)
	_mat.set_shader_parameter("progress", 1.0 if start_covered else 0.0)
	_mat.set_shader_parameter("scroll_a", _scroll_a)
	_mat.set_shader_parameter("scroll_b", _scroll_b)

	_cover = ColorRect.new()
	_cover.color = Color(1, 1, 1, 1)  # tint comes from the shader
	_cover.position = Vector2.ZERO
	_cover.size = vp_size
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_cover.material = _mat
	add_child(_cover)
	_scrolling = true

func _set_progress(value: float) -> void:
	if _mat != null:
		_mat.set_shader_parameter("progress", value)

## Animate fog cover. cover=true → progress 0→1; cover=false → 1→0.
func _animate(cover: bool) -> void:
	var my_gen: int = _anim_gen
	if _mat == null:
		return
	var from_p: float = 0.0 if cover else 1.0
	var to_p: float = 1.0 if cover else 0.0
	_set_progress(from_p)
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_method(_set_progress, from_p, to_p, DURATION) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await tw.finished
	if _anim_gen != my_gen:
		return
	_set_progress(to_p)

func _clear_cover() -> void:
	_scrolling = false
	if _cover != null and is_instance_valid(_cover):
		_cover.queue_free()
	_cover = null
	_mat = null
