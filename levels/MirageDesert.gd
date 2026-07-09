extends LevelBase
## LEVEL 3 — The Mirage (Mirage world). An endless dune under a frozen sky. The
## signature obstacle: a long bridge of crumbling mirage-tiles is the only span
## across the sinking sands — stop moving and it drops you. A quicksand belt and
## a hidden spike flank it, and a wall of mirage-cliffs (one a true gap) seals
## the far side.

func _ready() -> void:
	level_id = &"mirage_desert"
	bounds = Rect2(-680, -600, 1360, 1200)
	player_start = Vector2(0, 480)
	super._ready()


func build() -> void:
	spawn_ground(Vector2(1360, 1200))
	_scenery()
	_desert_props()

	spawn_boundary(Vector2(-680, 0), Vector2(40, 1200))
	spawn_boundary(Vector2(680, 0), Vector2(40, 1200))
	spawn_boundary(Vector2(0, -620), Vector2(1360, 40))

	spawn_sign(Vector2(-360, 400), [
		["Sara", "A sea of sinking sand. I'll need the ladder to bridge it."],
	], "!")

	# THE CROSSING (signature): a vast belt of sinking mirror-sand fills the
	# valley. There is no running across it — reveal the winding shard-path with
	# True Sight and step it, or the sands take you. Deep enough that brute force
	# is fatal.
	spawn_shard_crossing(Vector2(0, 190), 1300.0, 320.0, 8)

	# THE GATE: three mirage-cliffs, only the centre is a true gap.
	spawn_gate_line(-40, 0, 320, 3, 1, Color(0.95, 0.85, 0.55))


	spawn_enemy(Vector2(-160, -320), {
		sheet_dir = "res://assets/enemies/countess/",
		speaker = "The Mirage",
		aggro_lines = ["Drink. Rest. Stay. There is no forest, no hall, no home."],
		defeat_lines = ["...the sand remembers nothing..."],
		max_hp = 4, move_speed = 125.0, aggro_range = 300.0,
		tint = Color(1.0, 0.9, 0.6),
	})
	spawn_enemy(Vector2(180, -360), {
		sheet_dir = "res://assets/enemies/vampire_girl/",
		speaker = "The Heat-Shade",
		aggro_lines = ["Every step forward is a step back out here."],
		defeat_lines = ["...it was never real ground anyway..."],
		max_hp = 3, move_speed = 150.0, aggro_range = 260.0,
		tint = Color(1.0, 0.8, 0.5),
	})

	var shard := spawn_shard(Vector2(0, -440), Color(0.95, 0.85, 0.55))
	var portal := spawn_portal(Vector2(0, -520), Color(0.95, 0.85, 0.55))
	register_shard(shard, portal)


func _scenery() -> void:
	var s := Node2D.new()
	s.z_index = -8
	s.draw.connect(_draw_scenery.bind(s))
	add_child(s)

func _draw_scenery(c: CanvasItem) -> void:
	var L := bounds.position.x
	var W := bounds.size.x
	var top := bounds.position.y + 160.0
	# warm hazy horizon band
	c.draw_rect(Rect2(L, bounds.position.y, W, 240), Color(1.0, 0.87, 0.58, 0.30))
	# the sun — crisp disc with a soft glow + rays
	var sun := Vector2(L + W * 0.72, top - 70.0)
	c.draw_circle(sun, 96.0, Color(1.0, 0.92, 0.6, 0.18))
	c.draw_circle(sun, 46.0, Color(1.0, 0.96, 0.72))
	c.draw_circle(sun, 40.0, Color(1.0, 0.99, 0.85))
	# rolling dune silhouettes for depth
	for d in [[L + W * 0.15, top + 130, 320.0], [L + W * 0.6, top + 150, 380.0], [L + W * 0.9, top + 120, 300.0]]:
		c.draw_colored_polygon(_hill(Vector2(d[0], d[1]), d[2], 70.0), Color(0.92, 0.74, 0.42))
	# three finished pyramids at varied positions/sizes
	_pyramid(c, Vector2(L + W * 0.24, top + 60), 300.0)
	_pyramid(c, Vector2(L + W * 0.52, top + 10), 240.0)
	_pyramid(c, Vector2(L + W * 0.75, top + 44), 200.0)

func _hill(base: Vector2, w: float, h: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 10
	for i in steps + 1:
		var t := float(i) / steps
		pts.append(base + Vector2(-w * 0.5 + w * t, -sin(t * PI) * h))
	pts.append(base + Vector2(w * 0.5, 40)); pts.append(base + Vector2(-w * 0.5, 40))
	return pts

func _pyramid(c: CanvasItem, base: Vector2, w: float) -> void:
	var h := w * 0.8
	var apex := base + Vector2(0, -h)
	# ground shadow
	c.draw_colored_polygon(PackedVector2Array([
		base + Vector2(-w * 0.6, 0), base + Vector2(w * 0.7, 0), base + Vector2(w * 0.5, 16), base + Vector2(-w * 0.5, 16)]),
		Color(0.55, 0.4, 0.22, 0.35))
	# lit + shade faces
	c.draw_colored_polygon(PackedVector2Array([apex, base + Vector2(-w * 0.5, 0), base]), Color(1.0, 0.87, 0.55))
	c.draw_colored_polygon(PackedVector2Array([apex, base, base + Vector2(w * 0.5, 0)]), Color(0.78, 0.58, 0.30))
	# stepped courses (block lines)
	for i in range(1, 6):
		var t := float(i) / 6.0
		var y := base.y - h * t
		var hw := w * 0.5 * (1.0 - t)
		c.draw_line(Vector2(base.x - hw, y), Vector2(base.x + hw, y), Color(0.5, 0.36, 0.18, 0.5), 1.5)
	# bright capstone + edges
	c.draw_colored_polygon(PackedVector2Array([apex, apex + Vector2(-10, 16), apex + Vector2(10, 16)]), Color(1.0, 0.96, 0.75))
	c.draw_polyline(PackedVector2Array([base + Vector2(-w * 0.5, 0), apex, base + Vector2(w * 0.5, 0)]), Color(0.5, 0.34, 0.16), 2.0)
	c.draw_line(apex, base, Color(0.6, 0.44, 0.22, 0.6), 1.5)   # centre ridge


func _desert_props() -> void:
	# real Kenney desert palms + rocks at varied positions (off the centre path)
	var palm := SpriteSheet.load_tex("res://assets/desert/tree_S.png")
	var rock := SpriteSheet.load_tex("res://assets/desert/rocks_S.png")
	var layout := [
		[palm, -560.0, -430.0, 0.5], [palm, 540.0, -360.0, 0.55], [palm, -600.0, 300.0, 0.5],
		[palm, 600.0, 440.0, 0.48], [rock, -520.0, -80.0, 0.42], [rock, 560.0, 40.0, 0.46],
		[rock, -580.0, 500.0, 0.44], [rock, 470.0, 520.0, 0.4], [palm, 610.0, -520.0, 0.45],
	]
	for it in layout:
		var tex: Texture2D = it[0]
		if tex == null:
			continue
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		spr.scale = Vector2(it[3], it[3])
		spr.position = Vector2(it[1], it[2])
		spr.offset = Vector2(0, -tex.get_height() * 0.5)   # base-anchored
		spr.z_index = int(it[2])
		add_child(spr)
