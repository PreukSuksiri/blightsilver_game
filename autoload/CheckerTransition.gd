extends CanvasLayer
## Checkerboard transition used when entering a card battle.
## Fade-out: call fade_out_to_battle(callback) — screen fills with checker tiles,
##           then callback is invoked (do scene change there).
## Fade-in:  call fade_in() from GameBoard._ready() — tiles uncover the new scene.

const COLS        := 10
const ROWS        := 7
const DIAG_DELAY  := 0.040   # seconds between each diagonal wave step
const SOUND_PATH  := "res://assets/audio/sound_spellcasting_3.mp3"

var _tiles: Array[ColorRect] = []
var _sfx:   AudioStreamPlayer
var _anim_gen: int = 0   # incremented on each new animation; stale coroutines bail early

func _ready() -> void:
	layer        = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx         = AudioStreamPlayer.new()
	_sfx.stream  = load(SOUND_PATH)
	_sfx.bus     = "SFX"
	add_child(_sfx)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()

# ── Public API ──────────────────────────────────────────────────

## Cover the screen with checker tiles, play the transition sound,
## then call on_black (which should change the scene).
func fade_out_to_battle(on_black: Callable) -> void:
	_build_tiles(false)
	_sfx.play()
	await _animate(true)
	on_black.call()

## True while checker tiles from fade_out_to_battle are still covering the screen.
func is_screen_covered() -> bool:
	return not _tiles.is_empty()

## Uncover the screen (call after fade_out_to_battle when the target is not GameBoard).
## If tiles don't exist yet (no prior fade_out was run), builds them visible first.
func fade_in() -> void:
	if _tiles.is_empty():
		_build_tiles(true)
	await _animate(false)
	_clear_tiles()

# ── Internals ───────────────────────────────────────────────────

func _build_tiles(start_visible: bool) -> void:
	_anim_gen += 1
	_clear_tiles()
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var tw: float = vp_size.x / float(COLS)
	var th: float = vp_size.y / float(ROWS)
	for r: int in range(ROWS):
		for c: int in range(COLS):
			var rect := ColorRect.new()
			rect.color    = Color(0.0, 0.0, 0.0, 1.0)
			rect.position = Vector2(c * tw, r * th)
			rect.size     = Vector2(tw + 1.0, th + 1.0)
			rect.visible  = start_visible
			add_child(rect)
			_tiles.append(rect)

## Animate tiles in diagonal waves (top-left to bottom-right).
## cover=true  -> tiles become visible (fade-out).
## cover=false -> tiles become invisible (fade-in).
func _animate(cover: bool) -> void:
	var my_gen: int = _anim_gen
	var max_diag: int = (ROWS - 1) + (COLS - 1)
	for d: int in range(max_diag + 1):
		if _anim_gen != my_gen:
			return
		for r: int in range(ROWS):
			var c: int = d - r
			if c >= 0 and c < COLS:
				var idx: int = r * COLS + c
				if idx < _tiles.size():
					_tiles[idx].visible = cover
		await get_tree().create_timer(DIAG_DELAY).timeout

func _clear_tiles() -> void:
	for t: ColorRect in _tiles:
		t.queue_free()
	_tiles.clear()
