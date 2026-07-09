extends Control
## ~9s opening: Sara's bedroom at night, the cracked mirror shimmering. She walks
## to touch her reflection — and the glass pulls her in. Skippable with E/Space.

var _t := 0.0
var _light := 0.0
var _sara: AnimatedSprite2D
var _mirror: MuseumMirror
var _line: Label
var _done := false
var _mirror_glow := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	RenderingServer.set_default_clear_color(Color(0.03, 0.03, 0.06))
	var vp := get_viewport_rect().size
	var floor_y := vp.y * 0.78

	var room := Control.new()
	room.set_anchors_preset(Control.PRESET_FULL_RECT)
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.draw.connect(_draw_room.bind(room, vp))
	add_child(room)
	var tmr := Timer.new(); tmr.wait_time = 0.05; tmr.autostart = true
	tmr.timeout.connect(func(): room.queue_redraw())
	add_child(tmr)

	_mirror = MuseumMirror.new()
	_mirror.mirror_scale = 0.72; _mirror.show_stand = false; _mirror.glowing = true
	_mirror.position = Vector2(vp.x * 0.74, vp.y * 0.40)
	add_child(_mirror)

	_sara = _make_sprite("res://assets/sara/", Vector2(2.1, 2.1))
	_sara.position = Vector2(vp.x * 0.16, floor_y)
	add_child(_sara)

	_line = Label.new()
	_line.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_line.offset_top = -120; _line.offset_left = 60; _line.offset_right = -60
	_line.add_theme_font_size_override("font_size", 22)
	_line.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_line.add_theme_constant_override("outline_size", 6)
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_line)

	var skip := Label.new()
	skip.text = "E / Space to skip"
	skip.add_theme_font_size_override("font_size", 13)
	skip.add_theme_color_override("font_color", Color(0.5, 0.52, 0.62))
	skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.offset_left = -180; skip.offset_top = -34; skip.offset_right = -16
	add_child(skip)

	# timeline
	var tw := create_tween()
	tw.tween_method(func(v): _light = v, 0.0, 1.0, 1.2)
	tw.parallel().tween_callback(func(): _say("Sara couldn't sleep. The mirror wouldn't stop shimmering."))
	tw.tween_callback(func(): _sara.play("walk"); _sara.flip_h = false)
	tw.tween_property(_sara, "position:x", vp.x * 0.58, 3.0)
	tw.parallel().tween_callback(func(): _say("She reached out to touch her reflection—")).set_delay(1.2)
	tw.tween_callback(func(): _sara.play("idle"); _say("—and the glass reached back."))
	tw.tween_interval(0.6)
	# pull-in
	tw.tween_callback(func(): Audio.reveal(); FX.flash(Color(0.6, 0.85, 1.0), 0.4))
	tw.parallel().tween_property(_mirror, "scale", Vector2(0.95, 0.95), 0.3)
	tw.tween_property(_sara, "position", _mirror.position + Vector2(0, 40), 1.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_sara, "scale", Vector2(0.05, 0.05), 1.1)
	tw.parallel().tween_property(_sara, "rotation", TAU, 1.1)
	tw.parallel().tween_property(_sara, "modulate:a", 0.0, 1.1)
	tw.tween_callback(func(): FX.flash(Color.WHITE, 0.5))
	tw.tween_interval(0.5)
	tw.tween_callback(_finish)


func _make_sprite(dir: String, scale: Vector2) -> AnimatedSprite2D:
	var sf := SpriteFrames.new()
	SpriteSheet.add_strip(sf, "idle", SpriteSheet.load_tex(dir + "Idle.png"), 128, -1, 6.0)
	SpriteSheet.add_strip(sf, "walk", SpriteSheet.load_tex(dir + "Walk.png"), 128, -1, 12.0)
	if not sf.has_animation("idle"): sf.add_animation("idle")
	var s := AnimatedSprite2D.new()
	s.sprite_frames = sf; s.scale = scale; s.offset = Vector2(0, -52); s.play("idle")
	return s


func _say(t: String) -> void:
	_line.text = t
	_line.modulate.a = 0.0
	create_tween().tween_property(_line, "modulate:a", 1.0, 0.5)


func _process(delta: float) -> void:
	_t += delta
	if not _done and (Input.is_action_just_pressed(&"interact") or Input.is_action_just_pressed(&"attack") or Input.is_key_pressed(KEY_SPACE)):
		_finish()


func _finish() -> void:
	if _done: return
	_done = true
	Game.start_new_game()


func _draw_room(c: Control, vp: Vector2) -> void:
	var cx := vp.x * 0.5
	var cy := vp.y * 0.5
	c.draw_rect(Rect2(0, 0, vp.x, vp.y * 0.62), Color(0.10, 0.09, 0.16).lerp(Color(0.18, 0.15, 0.26), _light))
	c.draw_rect(Rect2(0, vp.y * 0.62, vp.x, vp.y * 0.38), Color(0.10, 0.08, 0.10).lerp(Color(0.17, 0.13, 0.14), _light))
	# window (moonlight)
	var wr := Rect2(cx - 300, cy - 190, 130, 120)
	c.draw_rect(wr, Color(0.14, 0.16, 0.30).lerp(Color(0.3, 0.34, 0.5), _light))
	c.draw_rect(wr, Color(0.03, 0.02, 0.02, 0.9), false, 5.0)
	c.draw_circle(wr.get_center(), 26.0, Color(0.85, 0.9, 1.0, 0.5))
	# bed
	var by := cy + 78
	c.draw_rect(Rect2(cx - 250, by, 210, 80), Color(0.30, 0.18, 0.16))
	c.draw_rect(Rect2(cx - 244, by - 22, 198, 30), Color(0.4, 0.34, 0.55))
	# eerie glow around the mirror
	c.draw_circle(Vector2(vp.x * 0.74, vp.y * 0.40), 150.0, Color(0.5, 0.8, 1.0, 0.06 + 0.05 * sin(_t * 2.0)))
