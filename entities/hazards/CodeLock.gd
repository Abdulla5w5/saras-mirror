class_name CodeLock
extends Area2D
## A 4-digit combination lock guarding a SlideWall gate. Interact (E) to grip the
## wheel; scroll it with ← / → (move_left/right). The lock HUMS — the panel
## vibrates harder the closer the wheel is to the correct number, and clicks the
## instant you land on it, advancing to the next digit. Four clicks opens the gate.
## Press J to let go.

var code: Array = [3, 7, 1, 9]
var target: Node = null          # SlideWall to open on success
var accent := Color(0.7, 0.85, 1.0)

var _active := false
var _solved := false
var _cur := 0
var _num := 0
var _t := 0.0
var _hint: Label
var _layer: CanvasLayer
var _panel: PanelContainer
var _digits: Array = []
var _wheel: Label
var _panel_home := Vector2.ZERO


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 2
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new(); s.radius = 46.0
	c.shape = s
	add_child(c)
	body_entered.connect(func(b): if b.is_in_group("player") and not _solved: _hint.visible = true)
	body_exited.connect(func(b): if b.is_in_group("player"): _hint.visible = false)
	z_index = 2
	_hint = Label.new()
	_hint.text = "E  the lock"
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.position = Vector2(-26, -60)
	_hint.visible = false
	add_child(_hint)
	_build_overlay()
	set_process(true)


func interact() -> void:
	if _solved or _active:
		return
	_active = true
	_num = 0
	_cur = 0
	var p := Game.get_player()
	if p:
		p.set_physics_process(false)
	_layer.visible = true
	_hint.visible = false
	_refresh()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if not _active:
		return
	if Input.is_action_just_pressed(&"move_left"):
		_num = (_num + 9) % 10; Audio.ui(); _refresh()
	elif Input.is_action_just_pressed(&"move_right"):
		_num = (_num + 1) % 10; Audio.ui(); _refresh()
	if Input.is_action_just_pressed(&"attack"):
		_close(); return

	# circular distance to the correct digit (0 = on it, 5 = farthest)
	var target_num: int = code[_cur]
	var raw: int = abs(_num - target_num)
	var d: int = min(raw, 10 - raw)
	# gradual vibration: panel jitters harder as d shrinks
	var closeness := 1.0 - float(d) / 5.0
	var mag := 11.0 * pow(closeness, 1.6)
	_panel.position = _panel_home + Vector2(randf_range(-mag, mag), randf_range(-mag, mag))
	if d == 0:
		_click()


func _click() -> void:
	Audio.shard()
	_cur += 1
	if _cur >= code.size():
		_finish()
	else:
		_num = (code[_cur - 1] + 3) % 10   # nudge off the solved number
		_refresh()


func _finish() -> void:
	_active = false
	_solved = true
	var p := Game.get_player()
	if p:
		p.set_physics_process(true)
	_layer.visible = false
	if target:                                   # gate shatters away and stops blocking
		target.set_deferred("collision_layer", 0)
		var tw := target.create_tween()
		tw.tween_property(target, "modulate:a", 0.0, 0.5)
	FX.burst(Vector2(target.global_position.x, target.global_position.y - 80) if target else global_position, accent, 20, 120.0)
	Audio.portal()
	FX.flash(accent * 0.7, 0.4)
	Talk.say("Sara", "Four clicks... the lock springs open. The way is clear.")


func _close() -> void:
	_active = false
	var p := Game.get_player()
	if p:
		p.set_physics_process(true)
	_layer.visible = false


func _refresh() -> void:
	for i in _digits.size():
		var lbl: Label = _digits[i]
		if i < _cur:
			lbl.text = str(code[i]); lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
		elif i == _cur:
			lbl.text = str(_num); lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		else:
			lbl.text = "–"; lbl.add_theme_color_override("font_color", Color(0.4, 0.44, 0.55))
	_wheel.text = "◄  %d  ►" % _num


func _build_overlay() -> void:
	_layer = CanvasLayer.new(); _layer.layer = 82; _layer.visible = false
	add_child(_layer)
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.12, 0.95)
	sb.border_color = accent; sb.set_border_width_all(3); sb.set_corner_radius_all(10); sb.set_content_margin_all(22)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_layer.add_child(_panel)
	var vb := VBoxContainer.new(); vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10); _panel.add_child(vb)
	var title := Label.new(); title.text = "MIRROR LOCK"
	title.add_theme_font_size_override("font_size", 20); title.add_theme_color_override("font_color", accent)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(title)
	var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18); vb.add_child(row)
	for i in 4:
		var d := Label.new(); d.text = "–"; d.add_theme_font_size_override("font_size", 40)
		row.add_child(d); _digits.append(d)
	_wheel = Label.new(); _wheel.add_theme_font_size_override("font_size", 26)
	_wheel.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_wheel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(_wheel)
	var hint := Label.new()
	hint.text = "◄ ►  scroll the wheel  ·  it hums as you near the number  ·  J  let go"
	hint.add_theme_font_size_override("font_size", 13); hint.add_theme_color_override("font_color", Color(0.6, 0.64, 0.75))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(hint)
	await get_tree().process_frame
	_panel.position -= _panel.size * 0.5
	_panel_home = _panel.position


func _draw() -> void:
	# a brass dial on the ground
	var pulse := 0.6 + 0.4 * sin(_t * 3.0)
	draw_circle(Vector2.ZERO, 22.0, Color(0.2, 0.17, 0.1))
	draw_circle(Vector2.ZERO, 22.0, (Color(0.5, 1.0, 0.6) if _solved else accent) * Color(1, 1, 1, 0.85), false, 3.0)
	draw_circle(Vector2.ZERO, 6.0, accent * Color(1, 1, 1, pulse))
	for i in 8:
		var a := TAU * i / 8.0 + _t * 0.3
		draw_line(Vector2(cos(a), sin(a)) * 12.0, Vector2(cos(a), sin(a)) * 20.0, Color(0.7, 0.6, 0.35), 1.5)
