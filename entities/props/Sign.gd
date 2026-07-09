class_name Sign
extends Area2D
## A readable placard / whisper in the dream. Interact (E) to push its lines to
## the Talk box. Used for tutorials and lore. In group "interactable".

var lines: Array = []                        # [[speaker, text], ...]
var label_text := "?"
var accent := Color(0.7, 0.8, 1.0)
var _t := 0.0
var _hint: Label


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 2
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new(); s.radius = 40.0
	c.shape = s
	add_child(c)
	body_entered.connect(func(b): if b.is_in_group("player"): _hint.visible = true)
	body_exited.connect(func(b): if b.is_in_group("player"): _hint.visible = false)
	z_index = 1

	_hint = Label.new()
	_hint.text = "E"
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.position = Vector2(-5, -56)
	_hint.visible = false
	add_child(_hint)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func interact() -> void:
	if not lines.is_empty():
		Talk.say_seq(lines)


func _draw() -> void:
	var bob := sin(_t * 2.0) * 3.0
	# a small floating mirror-glyph
	draw_circle(Vector2(0, bob), 18.0, Color(accent.r, accent.g, accent.b, 0.15))
	draw_rect(Rect2(-12, -14 + bob, 24, 28), Color(0.1, 0.11, 0.18, 0.9))
	draw_rect(Rect2(-12, -14 + bob, 24, 28), accent, false, 2.0)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-6, 4 + bob), label_text, HORIZONTAL_ALIGNMENT_CENTER, 12, 16, accent)
