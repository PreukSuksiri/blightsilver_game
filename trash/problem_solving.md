# Blightsilver — Problem Solving Journal

---

## Title Screen: Drifting Cards

### Problem: Cards "thrown" at start
Cards spawned mid-screen and flew into position, looking like they were just launched.
**Fix:** Run 30 s of physics via `_tick(0.2)` in `_ready()` before the first frame draws. Cards appear already mid-drift.

### Problem: Jellyfish float instead of leaf drift
Simple sine-wave position produced bouncy, symmetric motion.
**Fix:** Model *velocity* (not position) with 3 incommensurate sine frequencies summed. Add angular-velocity model with exponential drag for rotation. Add gust modulation on top.

### Problem: Cards drifting off screen vertically
No vertical boundary caused cards to float away.
**Fix:** Per-card `target_y` with a soft spring pull keeps each card loosely tethered to a vertical band.

### Problem: Larger (closer) cards not always on top
Draw order was array insertion order, not depth order.
**Fix:** Sort `_cards` by `card_scale` in `_draw()` before iterating — smaller scale (farther) drawn first.

### Problem: Cards disappear mid-screen (Z-axis boundary)
When a card's Z-scale hit `Z_MIN` while still on screen, it popped invisible.
**Fix:** Teleport the card off-screen to the left whenever a Z boundary is hit, so the re-entry is never visible.

### Problem: GDScript type inference error on flip_cos
`var w := CARD_W * s * abs(flip_cos)` failed because `flip_cos` came from a cast expression.
**Fix:** Declare explicitly `var flip_cos: float = cos(...)` and use `absf()`.

---

## Title Screen: Logo & Glow

### Problem: Title text-image too small
Default TextureRect size was too small.
**Fix:** Set `offset_left = -1080`, `offset_right = 1080` (2160 px wide), anchor center. Final vertical position: **185 px from screen top** (`offset_top = -70`, `offset_bottom = 440`).

### Problem: Glow shader discards parent modulate
Shader wrote `COLOR = vec4(...)` directly, throwing away the inherited `modulate.a` from parent nodes.
**Fix:** Read `float inherited_alpha = COLOR.a` *before* overwriting `COLOR`, then multiply it into the final alpha output.

---

## Splash Screen: Studio Logo

### Problem: Thin logo — shadow makes it look blurry
A blurred/expanded duplicate of the logo texture (LogoShadow) caused the thin logo strokes to bleed into each other, making the logo unreadable.
**Solution chosen:** Keep the shadow as a separate `TextureRect` *behind* the logo, apply a dedicated shader that converts all pixels to solid white using only the alpha channel (silhouette approach), and control blur via shader sample rings rather than scaling the node.

### Problem: Shadow shows original texture colours, not white
Setting `modulate = Color(1,1,1,1)` is default — it shows the original texture as-is.
**Fix:** Apply `silhouette.gdshader` which reads only the texture's alpha and outputs a flat `glow_color` (white) for every pixel that has any opacity.

### Problem: Logo doesn't fade out — disappears mid-fade
`logo_outline.gdshader` on the Logo node set `COLOR = texel` for inside pixels, discarding the inherited `modulate.a`. The logo stayed fully opaque until the tween nearly finished, then snapped to invisible.
**Fix:** Change to `COLOR = vec4(texel.rgb, texel.a * COLOR.a)` — multiply the inherited fade alpha in so the logo fades smoothly.

### Problem: Outer lantern glow invisible / too dim
The `center * 40.0` term was added to `total_weight` along with the ring weights, massively diluting the normalised glow for pixels outside the logo (where `center = 0`).
**Fix:** Remove center from the glow calculation entirely. Compute `glow_alpha = clamp((ring_glow / ring_total_weight) * glow_boost, 0.0, 1.0)`, then use `max(glow_alpha, center)` to keep the silhouette solid independently.

---

## Audio

### Problem: BGM plays from start on every scene load
`AudioStreamMP3.loop` defaults to false; music stops after one play.
**Fix:** Cast the stream and set `(bgm.stream as AudioStreamMP3).loop = true` before calling `bgm.play()`.

---

## General Godot

### Problem: Grey background visible before scene loads
Default clear colour was grey, flashing for a frame before the scene background rendered.
**Fix:** Set `rendering/environment/defaults/default_clear_color = Color(0,0,0,1)` in `project.godot`.
