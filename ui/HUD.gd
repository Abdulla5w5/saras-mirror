class_name HUD
extends CanvasLayer
## In-run HUD: heart pips for HP, a True-Sight cooldown ring, the level title,
## and a pause overlay (Escape) with resume/menu. Everything code-drawn.

var _player: Player
var _hearts: Array = []
var _sight_ring: Control
var _pause_layer: CanvasLayer
var _paused := false
var _shard_label: Label
var _objective: Label
var _level_id: StringName


func setup(player: Player, level_id: StringName) -> void:
	_player = player
	_level_id = level_id
	layer = 60
	_build()
	player.health_changed.connect(_on_hp)
	_on_hp(player.hp, Player.MAX_HP)
	Game.shard_collected.connect(_on_shard)
	_refresh_shards(Game.shard_count())
	_set_objective("Find the mirror shard" if not Game.has_shard(level_id) else "Step into the mirror doorway")


func _build() -> void:
	var top := MarginContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.add_theme_constant_override("margin_left", 24)
	top.add_theme_constant_override("margin_top", 20)
	add_child(top)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	top.add_child(hb)
	for i in Player.MAX_HP:
		var h := TextureRect.new()
		h.custom_minimum_size = Vector2(26, 26)
		h.texture = _heart_tex(true)
		hb.add_child(h)
		_hearts.append(h)

	# Shard counter, top-right.
	var tr := MarginContainer.new()
	tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr.add_theme_constant_override("margin_right", 24)
	tr.add_theme_constant_override("margin_top", 18)
	tr.offset_left = -220
	tr.offset_right = -24
	add_child(tr)
	_shard_label = Label.new()
	_shard_label.add_theme_font_size_override("font_size", 24)
	_shard_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	_shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr.add_child(_shard_label)

	# Objective line, top-center.
	_objective = Label.new()
	_objective.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_objective.offset_top = 22
	_objective.add_theme_font_size_override("font_size", 17)
	_objective.add_theme_color_override("font_color", Color(0.7, 0.74, 0.85))
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_objective)

	# True Sight cooldown ring, bottom-right.
	_sight_ring = Control.new()
	_sight_ring.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_sight_ring.position = Vector2(-90, -90)
	_sight_ring.custom_minimum_size = Vector2(64, 64)
	_sight_ring.draw.connect(_draw_ring.bind(_sight_ring))
	add_child(_sight_ring)
	var t := Timer.new()
	t.wait_time = 0.05
	t.autostart = true
	t.timeout.connect(func(): _sight_ring.queue_redraw())
	add_child(t)

	set_process_unhandled_input(true)


func _draw_ring(ring: Control) -> void:
	var r := 26.0
	var c := Vector2(32, 32)
	ring.draw_circle(c, r + 4, Color(0, 0, 0, 0.35))
	var ratio := Illusion.cooldown_ratio()
	var col := Color(0.7, 0.85, 1.0) if Illusion.can_activate() else Color(0.3, 0.35, 0.5)
	ring.draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * ratio, 32, col, 5.0, true)
	if Illusion.is_active():
		ring.draw_circle(c, r - 6, Color(0.7, 0.85, 1.0, 0.5))
	var f := ThemeDB.fallback_font
	ring.draw_string(f, c + Vector2(-6, 5), "Q", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)


func _heart_tex(full: bool) -> ImageTexture:
	var img := Image.create(26, 26, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var col := Color(0.85, 0.2, 0.3) if full else Color(0.25, 0.2, 0.25)
	for y in 26:
		for x in 26:
			var u := (x - 13) / 13.0
			var v := (y - 11) / 13.0
			var d := _heart_sdf(u, v)
			if d < 0.0:
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _heart_sdf(x: float, y: float) -> float:
	# quick heart implicit curve
	x *= 1.1
	y = -y * 1.1 + 0.35
	var a := x * x + y * y - 0.5
	return a * a * a - x * x * y * y * y


func _on_hp(current: int, max_hp: int) -> void:
	for i in _hearts.size():
		if i < _hearts.size():
			(_hearts[i] as TextureRect).texture = _heart_tex(i < current)


func _refresh_shards(total: int) -> void:
	# filled diamonds for collected shards, hollow for the rest
	var s := ""
	for i in Game.ORDER.size():
		s += "◆ " if i < total else "◇ "
	_shard_label.text = "Shards  " + s.strip_edges()

func _set_objective(text: String) -> void:
	if _objective:
		_objective.text = text

func _on_shard(id: StringName, total: int) -> void:
	_refresh_shards(total)
	if id == _level_id:
		var last := total >= Game.ORDER.size()
		_set_objective("Step through the mirror to wake" if last else "Step into the mirror doorway")
		Talk.say("Sara", "A shard reclaimed. The mirror doorway is open." if not last
			else "The last shard. I can feel my own room again — one step and I'm awake.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		_toggle_pause()


func _toggle_pause() -> void:
	_paused = not _paused
	get_tree().paused = _paused
	if _paused:
		_show_pause()
	elif _pause_layer:
		_pause_layer.queue_free()
		_pause_layer = null


func _show_pause() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 95
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(dim)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.add_theme_constant_override("separation", 14)
	_pause_layer.add_child(vb)

	var title := Label.new()
	title.text = "Paused"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var resume := Button.new()
	resume.text = "Resume"
	resume.custom_minimum_size = Vector2(200, 44)
	resume.pressed.connect(_toggle_pause)
	vb.add_child(resume)

	var menu := Button.new()
	menu.text = "Quit to Mirror Menu"
	menu.custom_minimum_size = Vector2(200, 44)
	menu.pressed.connect(func():
		get_tree().paused = false
		Game.quit_to_menu())
	vb.add_child(menu)

	await get_tree().process_frame
	vb.position -= vb.size * 0.5
