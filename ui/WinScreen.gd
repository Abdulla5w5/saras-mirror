extends Control
## The ending: Sara lies asleep in her real bed; dawn rises and her mother walks
## in to wake her. She sits up — it was all a dream. The whole, uncracked mirror
## hangs on the wall. Dialogue plays, then Play Again / Menu.

var _t := 0.0
var _light := 0.0
var _sara: AnimatedSprite2D
var _mom: AnimatedSprite2D
var _fg: Control
var _wall_mirror: MuseumMirror
var _box: PanelContainer
var _speaker: Label
var _line: Label
var _buttons: VBoxContainer
var _bed := Vector2.ZERO

var _script := [
	["Mom", "Sara, sweetheart... it's past noon. Time to wake up."],
	["Sara", "...nngh... Mom? I had the strangest dream."],
	["Sara", "A cracked mirror. Four whole worlds inside it. I was hunting for pieces of myself."],
	["Mom", "Only a dream, love. Come — breakfast's waiting downstairs."],
	["", "The mirror on her wall doesn't have a single crack in it. It was only ever a dream... wasn't it?"],
]
var _idx := -1
var _line_t := 0.0


func _ready() -> void:
	Talk.clear()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	RenderingServer.set_default_clear_color(Color(0.05, 0.05, 0.08))
	var vp := get_viewport_rect().size
	_bed = Vector2(vp.x * 0.5, vp.y * 0.5 + 40)

	var room := Control.new()
	room.set_anchors_preset(Control.PRESET_FULL_RECT)
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.draw.connect(_draw_room.bind(room))
	add_child(room)
	var tmr := Timer.new(); tmr.wait_time = 0.05; tmr.autostart = true
	tmr.timeout.connect(func():
		room.queue_redraw()
		if _fg: _fg.queue_redraw())
	add_child(tmr)

	# whole mirror on the wall
	_wall_mirror = MuseumMirror.new()
	_wall_mirror.mirror_scale = 0.6; _wall_mirror.show_stand = false
	_wall_mirror.modulate = Color(0.5, 0.52, 0.6, 0.0)
	_wall_mirror.position = Vector2(vp.x * 0.78, vp.y * 0.38)
	add_child(_wall_mirror)

	var cy := vp.y * 0.5
	var by := cy + 74.0
	var cx := vp.x * 0.5
	var floor_y := vp.y * 0.82

	# Sara, in bed asleep (slumped, feet tucked deep so the blanket covers her legs)
	_sara = _make_sprite("res://assets/sara/", Vector2(2.0, 2.0), true)
	_sara.position = Vector2(cx - 30, by + 44)
	_sara.rotation = -0.32                 # leaning, asleep
	_sara.modulate = Color(0.8, 0.8, 0.85)
	add_child(_sara)

	# Mom walks in and stands on the FLOOR (feet-anchored)
	_mom = _make_sprite("res://assets/mom/", Vector2(2.1, 2.1), true)
	_mom.position = Vector2(vp.x + 120, floor_y)
	_mom.flip_h = true                     # facing left as she walks in
	add_child(_mom)

	# foreground blanket + bed front, drawn ON TOP so Sara sits *in* the bed
	_fg = Control.new()
	_fg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fg.draw.connect(_draw_fg.bind(_fg))
	add_child(_fg)

	_build_box(vp)
	_shard_intro(vp)


func _begin_room() -> void:
	var tw := create_tween()
	tw.tween_method(func(v):
		_light = v
		_wall_mirror.modulate.a = v * 0.9, 0.0, 1.0, 2.0)
	tw.tween_callback(_mom_enter)


func _shard_intro(vp: Vector2) -> void:
	# Dark overlay: the four shards fly in and reassemble the mirror, then fade.
	var lay := CanvasLayer.new(); lay.layer = 90; add_child(lay)
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.02, 0.05)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT); dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lay.add_child(dim)
	var c := Vector2(vp.x * 0.5, vp.y * 0.46)
	var mir := MuseumMirror.new(); mir.mirror_scale = 1.1; mir.glowing = false
	mir.position = c; lay.add_child(mir)
	var caption := Label.new(); caption.text = "Four shards. One mirror. One way home."
	caption.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); caption.offset_top = -80
	caption.offset_left = -300; caption.offset_right = 300
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 20)
	lay.add_child(caption)
	var tw := create_tween()
	for i in 4:
		var sh := Polygon2D.new()
		sh.polygon = PackedVector2Array([Vector2(0, -30), Vector2(22, 6), Vector2(4, 34), Vector2(-20, 10)])
		sh.color = Color(0.8, 0.9, 1.0)
		var ang := TAU * i / 4.0 + 0.4
		sh.position = c + Vector2(cos(ang), sin(ang)) * 420.0
		sh.rotation = ang
		lay.add_child(sh)
		tw.parallel().tween_property(sh, "position", c, 1.6).set_delay(i * 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(sh, "modulate:a", 0.0, 0.4).set_delay(1.4 + i * 0.25)
	tw.chain().tween_callback(func():
		mir.glowing = true; Audio.shard(); FX.flash(Color.WHITE, 0.5))
	tw.tween_interval(0.7)
	tw.tween_property(dim, "modulate:a", 0.0, 1.0)
	tw.parallel().tween_property(mir, "modulate:a", 0.0, 1.0)
	tw.parallel().tween_property(caption, "modulate:a", 0.0, 0.6)
	tw.tween_callback(lay.queue_free)
	tw.tween_callback(_begin_room)


func _make_sprite(dir: String, scale: Vector2, feet := false) -> AnimatedSprite2D:
	var sf := SpriteFrames.new()
	SpriteSheet.add_strip(sf, "idle", SpriteSheet.load_tex(dir + "Idle.png"), 128, -1, 6.0)
	SpriteSheet.add_strip(sf, "walk", SpriteSheet.load_tex(dir + "Walk.png"), 128, -1, 12.0)
	if not sf.has_animation("idle"):
		sf.add_animation("idle")
	var s := AnimatedSprite2D.new()
	s.sprite_frames = sf
	s.scale = scale
	if feet:
		s.offset = Vector2(0, -52)    # anchor by the feet
	s.play("idle")
	return s


func _mom_enter() -> void:
	_mom.play("walk")
	var tw := create_tween()
	tw.tween_property(_mom, "position:x", get_viewport_rect().size.x * 0.72, 1.8)
	tw.tween_callback(func():
		_mom.play("idle")
		Audio.win())
	tw.tween_interval(0.4)
	tw.tween_callback(_advance)


func _sit_up() -> void:
	# straighten up and brighten — she wakes, still sitting in the bed
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sara, "rotation", 0.0, 0.5)
	tw.parallel().tween_property(_sara, "modulate", Color.WHITE, 0.5)


func _build_box(vp: Vector2) -> void:
	_box = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.1, 0.92)
	sb.border_color = Color(0.55, 0.6, 0.9, 0.8)
	sb.set_border_width_all(2); sb.set_corner_radius_all(8); sb.set_content_margin_all(16)
	_box.add_theme_stylebox_override("panel", sb)
	_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_left = 120; _box.offset_right = -120; _box.offset_top = -170; _box.offset_bottom = -40
	_box.modulate.a = 0.0
	add_child(_box)
	var vbx := VBoxContainer.new(); _box.add_child(vbx)
	_speaker = Label.new(); _speaker.add_theme_font_size_override("font_size", 18)
	vbx.add_child(_speaker)
	_line = Label.new(); _line.add_theme_font_size_override("font_size", 21)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _line.custom_minimum_size = Vector2(0, 54)
	vbx.add_child(_line)

	_buttons = VBoxContainer.new(); _buttons.add_theme_constant_override("separation", 12)
	_buttons.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_buttons.offset_top = -150; _buttons.offset_left = -110; _buttons.offset_right = 110
	_buttons.modulate.a = 0.0
	add_child(_buttons)
	var again := Button.new(); again.text = "Dream Again"; again.custom_minimum_size = Vector2(200, 44)
	again.pressed.connect(func(): Audio.ui(); Game.start_new_game())
	_buttons.add_child(again)
	var menu := Button.new(); menu.text = "Main Menu"; menu.custom_minimum_size = Vector2(200, 44)
	menu.pressed.connect(func(): Audio.ui(); Game.quit_to_menu())
	_buttons.add_child(menu)


func _advance() -> void:
	_idx += 1
	if _idx >= _script.size():
		_box.modulate.a = 0.0
		create_tween().tween_property(_buttons, "modulate:a", 1.0, 0.8)
		return
	var l: Array = _script[_idx]
	_speaker.text = l[0]
	_speaker.add_theme_color_override("font_color", Color(1.0, 0.82, 0.55) if l[0] == "Mom" else Color(0.7, 0.8, 1.0))
	_line.text = l[1]
	if l[0] != "":
		Audio.enemy_speak()
	if _idx == 1:
		_sit_up()
	if _box.modulate.a < 1.0:
		create_tween().tween_property(_box, "modulate:a", 1.0, 0.4)
	_line_t = 5.0


func _process(delta: float) -> void:
	_t += delta
	if _idx >= 0 and _idx < _script.size():
		_line_t -= delta
		if _line_t <= 0.0 or Input.is_action_just_pressed(&"interact"):
			_advance()


func _draw_room(c: Control) -> void:
	var size := c.size
	var cx := size.x * 0.5
	var cy := size.y * 0.5
	var wall := Color(0.12, 0.10, 0.18).lerp(Color(0.62, 0.5, 0.5), _light * 0.55)
	c.draw_rect(Rect2(0, 0, size.x, size.y * 0.62), wall)
	c.draw_rect(Rect2(0, size.y * 0.62, size.x, size.y * 0.38), Color(0.16, 0.12, 0.10).lerp(Color(0.4, 0.3, 0.22), _light * 0.5))

	var wr := Rect2(cx - 300, cy - 200, 150, 130)
	var st := Color(0.10, 0.10, 0.20).lerp(Color(1.0, 0.72, 0.45), _light)
	var sbm := Color(0.12, 0.12, 0.22).lerp(Color(1.0, 0.9, 0.7), _light)
	for i in 8:
		var t := float(i) / 8.0
		c.draw_rect(Rect2(wr.position.x, wr.position.y + wr.size.y * t, wr.size.x, wr.size.y / 8.0 + 1), st.lerp(sbm, t))
	c.draw_rect(wr, Color(0.03, 0.02, 0.02, 0.9), false, 5.0)
	c.draw_line(Vector2(wr.get_center().x, wr.position.y), Vector2(wr.get_center().x, wr.position.y + wr.size.y), Color(0.03, 0.02, 0.02), 3.0)
	c.draw_circle(wr.get_center(), 240.0, Color(1.0, 0.82, 0.55, 0.12 * _light))

	# bed
	var by := cy + 74
	c.draw_rect(Rect2(cx - 170, by, 340, 92), Color(0.34, 0.2, 0.18).lerp(Color(0.56, 0.34, 0.30), _light * 0.5))
	c.draw_rect(Rect2(cx - 160, by - 28, 320, 44), Color(0.5, 0.4, 0.7).lerp(Color(0.8, 0.7, 0.95), _light * 0.5))
	c.draw_rect(Rect2(cx - 160, by - 52, 78, 34), Color(0.9, 0.9, 0.95))
	c.draw_rect(Rect2(0, 0, size.x, size.y), Color(0, 0, 0, 0.34 * (1.0 - _light)))


func _draw_fg(c: Control) -> void:
	# blanket pulled over Sara's legs + the bed's front rail, drawn in front of her
	var cy := c.size.y * 0.5
	var by := cy + 74.0
	var cx := c.size.x * 0.5
	var blanket := Color(0.5, 0.4, 0.7).lerp(Color(0.82, 0.72, 0.96), _light * 0.5)
	var frame := Color(0.34, 0.2, 0.18).lerp(Color(0.56, 0.34, 0.30), _light * 0.5)
	c.draw_rect(Rect2(cx - 150, by - 30, 300, 76), blanket)
	c.draw_line(Vector2(cx - 150, by - 8), Vector2(cx + 150, by - 8), Color(0, 0, 0, 0.12), 3.0)
	c.draw_rect(Rect2(cx - 160, by + 46, 320, 28), frame)
