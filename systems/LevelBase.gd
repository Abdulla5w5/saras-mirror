class_name LevelBase
extends Node2D
## Shared scaffolding every dream-world level extends: builds the procedural
## ground, spawns Sara, wires the HUD, camera bounds, ambient mood, and the
## shard/portal win flow. Concrete levels override `build()` to lay out their
## room using the helper spawners below, then call `finish_setup()`.

var level_id: StringName = &""
var bounds := Rect2(0, 0, 1600, 900)
var player_start := Vector2(200, 200)

var _mood: Dictionary
var _player: Player
var _hud: Node
var _portal: Portal


func _ready() -> void:
	Talk.clear()               # drop any lines still queued from the previous level
	_mood = World.mood(level_id)
	RenderingServer.set_default_clear_color(_mood.clear)
	Audio.set_mood(_mood.pad_root, _mood.pad_fifth)

	_build_ground()
	build()  # subclass fills the room
	_build_vignette()

	_player = Player.new()
	_player.global_position = player_start
	add_child(_player)
	_player.set_camera_limits(bounds)

	_hud = HUD.new()
	add_child(_hud)
	_hud.setup(_player, level_id)

	_show_intro_card()


func build() -> void:
	pass # overridden by each level


## Call once the shard for this level is placed, to auto-wire portal unlock.
func register_shard(shard: MirrorShard, portal: Portal) -> void:
	_portal = portal
	shard.collected.connect(func():
		Game.collect_shard(level_id)
		_portal.activate())


# --- Helper spawners ---------------------------------------------------------
func spawn_ground(size: Vector2) -> void:
	var poly := Polygon2D.new()
	var hw := size.x * 0.5
	var hh := size.y * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)])
	poly.uv = PackedVector2Array([
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	poly.material = World.make_ground_material(_mood, maxf(size.x, size.y) / 160.0)
	poly.z_index = -10
	add_child(poly)
	bounds = Rect2(-hw, -hh, size.x, size.y)

func _build_ground() -> void:
	pass # subclasses call spawn_ground() explicitly with their own size

## A cinematic edge-darkening vignette over the world (under the HUD).
func _build_vignette() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = World.make_vignette_material(_mood, 0.6)
	cl.add_child(rect)

func spawn_wall(pos: Vector2, size: Vector2, real: bool, tint := Color(0.55, 0.68, 1.0)) -> IllusionWall:
	var w := IllusionWall.new()
	w.wall_size = size
	w.real = real
	w.tint = tint
	w.global_position = pos
	add_child(w)
	return w

## Plain boundary/room-edge wall — not a puzzle piece, ignored by True Sight.
func spawn_boundary(pos: Vector2, size: Vector2) -> Wall:
	var w := Wall.new()
	w.wall_size = size
	w.global_position = pos
	add_child(w)
	return w

func spawn_quicksand(pos: Vector2, size := Vector2(420, 150), theme := "sand") -> Quicksand:
	var q := Quicksand.new()
	q.patch_size = size
	q.theme = theme
	q.global_position = pos
	add_child(q)
	return q

func _spawn_ladder(center: Vector2, width: float, band_h: float) -> void:
	var ladder := Ladder.new()
	ladder.global_position = center + Vector2(-width * 0.26, band_h * 0.5 + 108.0)
	add_child(ladder)

## A swamp band with slithering snakes, crossed with the ladder (desert-style
## quicksand reskinned green + patrolling Snakes on the flanks).
func spawn_swamp_crossing(center: Vector2, width: float, band_h := 200.0) -> void:
	spawn_quicksand(center, Vector2(width, band_h), "swamp")
	_spawn_ladder(center, width, band_h)
	# snakes patrol the flanks, staying off the ladder's central strip
	for s in [-1.0, 1.0]:
		var snake := Snake.new()
		snake.range_x = width * 0.16
		snake.global_position = center + Vector2(s * width * 0.30, 0)
		add_child(snake)

## Funnel walls + a locked SlideWall across a corridor, opened by a CodeLock.
func spawn_code_gate(line_y: float, gap_center: float, gap_w: float, code: Array,
		tint := Color(0.55, 0.68, 1.0)) -> void:
	var left := bounds.position.x
	var right := bounds.position.x + bounds.size.x
	var gl := gap_center - gap_w * 0.5
	var gr := gap_center + gap_w * 0.5
	if gl - left > 4.0:
		spawn_boundary(Vector2((left + gl) * 0.5, line_y), Vector2(gl - left, 220))
	if right - gr > 4.0:
		spawn_boundary(Vector2((gr + right) * 0.5, line_y), Vector2(right - gr, 220))
	var wall := spawn_slidewall(Vector2(gap_center, line_y), Vector2(gap_w, 220), Vector2(0, -244), tint)
	var lock := CodeLock.new()
	lock.code = code
	lock.target = wall
	lock.accent = tint
	lock.global_position = Vector2(gr + 66.0, line_y + 30.0)
	add_child(lock)

## A wide quicksand band spanning a corridor, plus a Ladder lying nearby on the
## south side. Pick up the ladder (E) and press E on the sand to lay it across
## and walk over. `center` = band centre, `width` ≈ corridor gap.
func spawn_shard_crossing(center: Vector2, width: float, band_h := 180.0, _unused := 6) -> void:
	spawn_quicksand(center, Vector2(width, band_h))
	var ladder := Ladder.new()
	ladder.global_position = center + Vector2(-width * 0.26, band_h * 0.5 + 108.0)
	add_child(ladder)

func spawn_trap(pos: Vector2, size := Vector2(96, 64)) -> TrapSpikes:
	var t := TrapSpikes.new()
	t.trap_size = size
	t.global_position = pos
	add_child(t)
	return t

func spawn_shard(pos: Vector2, accent := Color(0.7, 0.85, 1.0)) -> MirrorShard:
	var s := MirrorShard.new()
	s.accent = accent
	s.global_position = pos
	add_child(s)
	return s

func spawn_portal(pos: Vector2, accent := Color(0.7, 0.85, 1.0)) -> Portal:
	var p := Portal.new()
	p.accent = accent
	p.global_position = pos
	add_child(p)
	return p

func spawn_sign(pos: Vector2, lines: Array, label := "?") -> Sign:
	var s := Sign.new()
	s.lines = lines
	s.label_text = label
	s.global_position = pos
	add_child(s)
	return s

func spawn_enemy(pos: Vector2, cfg: Dictionary) -> Enemy:
	var e := Enemy.new()
	for k in cfg:
		e.set(k, cfg[k])
	e.global_position = pos
	add_child(e)
	return e

## Seal the level across `line_y` with plain funnel walls on both sides and a row
## of mirror panels filling a central gap — exactly one panel (fake_index) is a
## passable illusion. Since the funnels reach the outer boundary, the ONLY way
## north is to True-Sight the row and walk through the real gap. Makes the mirror
## panels load-bearing instead of decorative.
func spawn_gate_line(line_y: float, gap_center: float, gap_width: float,
		panels: int, fake_index: int, tint := Color(0.55, 0.68, 1.0), wall_h := 220.0) -> void:
	var left := bounds.position.x
	var right := bounds.position.x + bounds.size.x
	var gap_l := gap_center - gap_width * 0.5
	var gap_r := gap_center + gap_width * 0.5
	if gap_l - left > 4.0:
		spawn_boundary(Vector2((left + gap_l) * 0.5, line_y), Vector2(gap_l - left, wall_h))
	if right - gap_r > 4.0:
		spawn_boundary(Vector2((gap_r + right) * 0.5, line_y), Vector2(right - gap_r, wall_h))
	var pw := gap_width / float(panels)
	for i in panels:
		var cx := gap_l + pw * (i + 0.5)
		spawn_wall(Vector2(cx, line_y), Vector2(pw - 4.0, wall_h), i != fake_index, tint)

# --- Smart obstacles (adapted from Shards of Reflection) ---------------------
func spawn_crumble(pos: Vector2, size := Vector2(72, 72)) -> CrumbleFloor:
	var c := CrumbleFloor.new()
	c.tile_size = size
	c.global_position = pos
	add_child(c)
	return c

## Lay a row/bridge of crumble tiles between two points.
func spawn_crumble_bridge(from: Vector2, to: Vector2, count: int, size := Vector2(72, 72)) -> void:
	for i in count:
		var t := float(i) / float(maxi(count - 1, 1))
		spawn_crumble(from.lerp(to, t), size)

func spawn_phase_gate(pos: Vector2, size := Vector2(48, 200), solid := 1.8, open := 1.4, off := 0.0) -> PhaseGate:
	var g := PhaseGate.new()
	g.gate_size = size
	g.solid_time = solid
	g.open_time = open
	g.offset = off
	g.global_position = pos
	add_child(g)
	return g

func spawn_sweep(pos: Vector2, travel := Vector2(280, 0), time := 1.6, size := Vector2(30, 150)) -> SweepHazard:
	var s := SweepHazard.new()
	s.travel = travel
	s.time = time
	s.blade_size = size
	s.global_position = pos
	add_child(s)
	return s

func spawn_slidewall(pos: Vector2, size: Vector2, offset: Vector2, tint := Color(0.6, 0.7, 1.0)) -> SlideWall:
	var w := SlideWall.new()
	w.wall_size = size
	w.aligned_offset = offset
	w.tint = tint
	w.global_position = pos
	add_child(w)
	return w

func spawn_lever(pos: Vector2, targets: Array, one_shot := false) -> AlignLever:
	var l := AlignLever.new()
	l.targets = targets
	l.one_shot = one_shot
	l.global_position = pos
	add_child(l)
	return l

## Scatter a curated set of ground props (rocks/ruins/etc.) along the two side
## margins of the level so the middle play-space stays clear. Keeps decoration
## thematic and sparse rather than random clutter.
func scatter_props(dir: String, names: Array, count: int, rng_seed: int,
		x_min: float, x_max: float, y_range: float, s_min := 0.6, s_max := 1.0,
		tint := Color.WHITE) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for i in count:
		var tex := SpriteSheet.load_tex(dir + names[i % names.size()])
		if tex == null:
			continue
		var side := -1.0 if i % 2 == 0 else 1.0
		var s := Sprite2D.new()
		s.texture = tex
		s.modulate = tint
		var sc := rng.randf_range(s_min, s_max)
		s.scale = Vector2(sc, sc)
		s.position = Vector2(side * rng.randf_range(x_min, x_max), rng.randf_range(-y_range, y_range))
		s.z_index = int(s.position.y) - 30
		add_child(s)

func spawn_prop(pos: Vector2, texture: Texture2D, scale := Vector2.ONE, y_offset := 0.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	s.global_position = pos
	s.scale = scale
	s.offset = Vector2(0, y_offset)
	add_child(s)
	return s


func _show_intro_card() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 70
	add_child(layer)
	var lbl := Label.new()
	lbl.text = Game.level_title(level_id)
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", _mood.accent)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.modulate.a = 0.0
	layer.add_child(lbl)
	await get_tree().process_frame
	lbl.position -= lbl.size * 0.5
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.6)
	tw.tween_interval(1.4)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.tween_callback(layer.queue_free)
