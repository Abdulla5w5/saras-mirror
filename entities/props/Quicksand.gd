class_name Quicksand
extends Area2D
## A wide band of sinking mirror-sand across a corridor. Wading in slows Sara and
## drags her down (ticking damage). To cross, find a Ladder on the map, carry it
## here, and press E on the sand to lay it across — then walk over safely.
## In group "interactable" so Sara's probe can trigger the placement.

var patch_size := Vector2(420, 150)
var theme := "sand"          # "sand" or "swamp"
const SLOW_FACTOR := 0.4
const DAMAGE_INTERVAL := 0.85
const LADDER_HALF := 40.0    # only this central strip is safe once bridged
const SINK_TIME := 4.0       # seconds of wading before she goes under -> restart

var bridged := false
var _t := 0.0
var _sink := 0.0
var _dmg_cd := 0.0
var _player: Node2D = null
var _hint: Label
var _tex: Texture2D = null


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 4          # so the player's interact probe can reach it
	collision_mask = 2           # detect player/enemy bodies
	var c := CollisionShape2D.new()
	var s := RectangleShape2D.new(); s.size = patch_size
	c.shape = s
	add_child(c)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	z_index = -6
	_tex = SpriteSheet.load_tex("res://assets/ground/swamp.png" if theme == "swamp" else "res://assets/ground/sand.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.position = Vector2(-70, -patch_size.y * 0.5 - 26)
	_hint.visible = false
	add_child(_hint)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	_dmg_cd -= delta

	# guidance hint while Sara is standing in unbridged sand
	if _hint:
		var p := Game.get_player()
		var carrying: bool = p != null and p.get("has_ladder")
		_hint.visible = not bridged and _player != null
		_hint.text = "E  place ladder" if carrying else "the sand pulls me down..."
		_hint.modulate = Color(0.8, 0.9, 1.0) if carrying else Color(0.9, 0.6, 0.6)

	if is_instance_valid(_player):
		# Safe ONLY when standing on the laid ladder's central strip.
		var on_ladder := bridged and absf(_player.global_position.x - global_position.x) <= LADDER_HALF
		if on_ladder:
			_sink = 0.0
		else:
			_sink += delta            # sinking; hit SINK_TIME and she goes under
			if _player.has_method("apply_slow"):
				_player.apply_slow(SLOW_FACTOR)
			if int(_sink * 2.0) != int((_sink - delta) * 2.0):
				FX.burst(_player.global_position, Color(0.55, 0.44, 0.24), 6, 40.0)
		if _player.has_method("set_sink"):
			_player.set_sink(minf(_sink / SINK_TIME, 1.0))
		if on_ladder and _player.has_method("apply_slow"):
			_player.apply_slow(1.0)

	# enemies still just sink-die (they can't read the ladder)
	if _dmg_cd <= 0.0:
		for b in get_overlapping_bodies():
			if b.is_in_group("enemy") and b.has_method("take_damage"):
				b.take_damage(1, b.global_position)
				_dmg_cd = DAMAGE_INTERVAL
	queue_redraw()


# Called by the player's interact probe (E).
func interact() -> void:
	if bridged:
		return
	var p := Game.get_player()
	if p and p.get("has_ladder") and p.has_method("use_ladder"):
		if p.use_ladder():
			bridged = true
			Audio.portal()
			FX.burst(global_position, Color(0.8, 0.7, 0.4), 16, 90.0)
			Talk.say("Sara", "The ladder holds. I can walk across now.")
			if _player and _player.has_method("apply_slow"):
				_player.apply_slow(1.0)


func _on_enter(b: Node) -> void:
	if b.is_in_group("player"):
		_player = b

func _on_exit(b: Node) -> void:
	if b == _player:
		_sink = 0.0
		if _player.has_method("apply_slow"):
			_player.apply_slow(1.0)
		if _player.has_method("set_sink"):
			_player.set_sink(0.0)
		_player = null


func _draw() -> void:
	var w := patch_size.x
	var h := patch_size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	var swamp := theme == "swamp"
	var tint := Color(0.5, 0.72, 0.5) if swamp else Color(0.95, 0.78, 0.46)
	var deep := Color(0.04, 0.12, 0.07) if swamp else Color(0.46, 0.28, 0.10)  # warm, not black
	var deep_a := 0.5 if swamp else 0.34
	var ripple_c := Color(0.35, 0.7, 0.42, 0.45) if swamp else Color(0.75, 0.58, 0.30, 0.5)
	var bub_c := Color(0.5, 0.85, 0.5) if swamp else Color(0.85, 0.70, 0.42)
	# real tiled ground texture as the base
	if _tex:
		draw_texture_rect(_tex, r, true, tint)
	else:
		draw_rect(r, tint)
	# "sinking" darkening, heaviest through the middle where it's deepest
	for i in 7:
		var t := absf(float(i) / 6.0 - 0.5) * 2.0     # 1 at edges, 0 at centre
		var yy := -h * 0.5 + h * (float(i) / 6.0)
		draw_rect(Rect2(-w * 0.5, yy, w, h / 6.0 + 1), Color(deep.r, deep.g, deep.b, deep_a * (1.0 - t)))
	# ripples + rising bubbles for life
	for i in 5:
		var ry := -h * 0.4 + h * 0.8 * (float(i) / 4.0)
		draw_line(Vector2(-w * 0.5, ry), Vector2(w * 0.5, ry + sin(_t * 0.7 + i) * 3.0), ripple_c, 2.0)
	for i in 8:
		var bx := (hash01(i) - 0.5) * w
		var phase := fmod(_t * 0.5 + hash01(i * 3), 1.0)
		draw_circle(Vector2(bx, h * 0.5 - phase * h), 2.0 + hash01(i * 7) * 2.5, Color(bub_c.r, bub_c.g, bub_c.b, (1.0 - phase) * 0.5))
	draw_rect(r, Color(0.03, 0.09, 0.05, 0.8) if swamp else Color(0.10, 0.06, 0.02, 0.8), false, 4.0)

	# deployed ladder bridging the band (vertical, across the crossing)
	if bridged:
		var lc := Color(0.82, 0.66, 0.4)
		draw_line(Vector2(-24, -h * 0.5 - 6), Vector2(-24, h * 0.5 + 6), lc, 5.0)
		draw_line(Vector2(24, -h * 0.5 - 6), Vector2(24, h * 0.5 + 6), lc, 5.0)
		var rungs := int((h + 12.0) / 22.0)
		for i in rungs:
			var ry := -h * 0.5 - 6 + i * 22.0
			draw_line(Vector2(-24, ry), Vector2(24, ry), lc.darkened(0.1), 4.0)


func hash01(i: int) -> float:
	return fract(sin(float(i) * 12.9898) * 43758.5453)

func fract(x: float) -> float:
	return x - floor(x)
