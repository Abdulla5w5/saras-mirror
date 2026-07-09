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

var bridged := false
var _t := 0.0
var _dmg_cd := 0.0
var _player: Node2D = null
var _hint: Label


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
		if _player.has_method("apply_slow"):
			_player.apply_slow(1.0 if on_ladder else SLOW_FACTOR)
		if not on_ladder and _dmg_cd <= 0.0:
			_dmg_cd = DAMAGE_INTERVAL
			_player.take_damage(1, _player.global_position + Vector2(0, 60))
			FX.burst(_player.global_position, Color(0.55, 0.44, 0.24), 8, 45.0)

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
		if _player.has_method("apply_slow"):
			_player.apply_slow(1.0)
		_player = null


func _draw() -> void:
	var w := patch_size.x
	var h := patch_size.y
	var swamp := theme == "swamp"
	var top_c := Color(0.14, 0.32, 0.20) if swamp else Color(0.34, 0.26, 0.13)
	var bot_c := Color(0.05, 0.16, 0.12) if swamp else Color(0.14, 0.10, 0.05)
	var ripple_c := Color(0.35, 0.65, 0.4, 0.4) if swamp else Color(0.5, 0.4, 0.22, 0.35)
	var bub_c := Color(0.5, 0.8, 0.5) if swamp else Color(0.6, 0.5, 0.3)
	var bands := 10
	for i in bands:
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(-w * 0.5, -h * 0.5 + h * t, w, h / bands + 1.0), top_c.lerp(bot_c, t))
	for i in 5:
		var yy := -h * 0.4 + h * 0.8 * (float(i) / 4.0)
		draw_line(Vector2(-w * 0.5, yy), Vector2(w * 0.5, yy + sin(_t * 0.7 + i)), ripple_c, 2.0)
	for i in 7:
		var bx := (hash01(i) - 0.5) * w
		var phase := fmod(_t * 0.5 + hash01(i * 3), 1.0)
		draw_circle(Vector2(bx, h * 0.5 - phase * h), 2.0 + hash01(i * 7) * 2.0, Color(bub_c.r, bub_c.g, bub_c.b, (1.0 - phase) * 0.4))
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(0.04, 0.10, 0.06, 0.7) if swamp else Color(0.08, 0.05, 0.02, 0.7), false, 3.0)

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
