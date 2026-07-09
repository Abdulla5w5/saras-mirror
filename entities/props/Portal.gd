class_name Portal
extends Area2D
## A mirror doorway between dream-worlds. Dormant until the level's shard is
## claimed; then it wakes and, on interact (E) or touch, advances the game.
## In group "interactable" so Sara's probe can reach it.

var accent := Color(0.7, 0.85, 1.0)
var active := false
var _t := 0.0
var _label: Label


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 2
	var c := CollisionShape2D.new()
	var s := CapsuleShape2D.new(); s.radius = 28.0; s.height = 96.0
	c.shape = s
	c.position = Vector2(0, -40)
	add_child(c)
	body_entered.connect(_on_body)
	z_index = 1

	_label = Label.new()
	_label.text = "E"
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.position = Vector2(-6, -110)
	_label.visible = false
	add_child(_label)
	set_process(true)


func activate() -> void:
	active = true
	Audio.portal()
	_label.visible = true

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func interact() -> void:
	if active:
		_go()

func _on_body(b: Node) -> void:
	if active and b.is_in_group("player"):
		_go()

func _go() -> void:
	if not active:
		return
	active = false
	Audio.portal()
	FX.flash(accent, 0.6)
	get_tree().create_timer(0.4).timeout.connect(Game.advance_level)


func _draw() -> void:
	var h := 132.0
	var hw := 34.0
	# arched mirror-doorway outline (base flush at y=0)
	var arch := PackedVector2Array([
		Vector2(-hw, 0), Vector2(-hw, -h * 0.62), Vector2(-hw * 0.72, -h * 0.85),
		Vector2(0, -h), Vector2(hw * 0.72, -h * 0.85), Vector2(hw, -h * 0.62), Vector2(hw, 0)])
	# gold double frame
	draw_colored_polygon(arch, Color(0.66, 0.53, 0.26) if active else Color(0.3, 0.28, 0.24))
	var inner := PackedVector2Array()
	for p in arch:
		inner.append(p * 0.86 + Vector2(0, -h * 0.07))
	if active:
		# swirling reflective vortex behind the frame
		for i in 7:
			var r := float(i) / 7.0
			var yy := -h * 0.46
			var rad := hw * (1.0 - r) + 5.0
			var a := (0.55 - r * 0.45) * (0.6 + 0.4 * sin(_t * 3.0 + i))
			draw_circle(Vector2(sin(_t + i) * 3.0, yy), rad, Color(accent.r, accent.g, accent.b, a))
		# base pool of light
		draw_circle(Vector2(0, -6), hw * 0.9, Color(accent.r, accent.g, accent.b, 0.15 + 0.1 * sin(_t * 2.0)))
	else:
		draw_colored_polygon(inner, Color(0.06, 0.06, 0.1, 0.85))
	# frame outline + keystone gem
	var outline := arch; outline.append(arch[0])
	draw_polyline(outline, (accent if active else Color(0.4, 0.4, 0.5)), 3.0)
	var gem := 0.6 + 0.4 * sin(_t * 2.5)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -h - 6), Vector2(7, -h + 4), Vector2(0, -h + 12), Vector2(-7, -h + 4)]),
		Color(0.82, 0.9, 1.0, gem if active else 0.4))
