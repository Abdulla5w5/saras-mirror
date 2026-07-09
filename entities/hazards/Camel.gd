class_name Camel
extends Area2D
## A wise desert camel guarding the way. Interact (E) to hear its riddle; type
## "illusion" and it steps aside, opening the gate. In group "interactable".

var target: Node = null
var _t := 0.0
var _in_range := false
var _done := false
var _riddle: Riddle
var _hint: Label


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 2
	var col := CollisionShape2D.new()
	var s := CircleShape2D.new(); s.radius = 56.0
	col.shape = s
	add_child(col)
	body_entered.connect(func(b): if b.is_in_group("player"): _in_range = true; _refresh())
	body_exited.connect(func(b): if b.is_in_group("player"): _in_range = false; _refresh())
	z_index = 5
	_hint = Label.new(); _hint.text = "E: hear the riddle"
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.position = Vector2(-50, -96); _hint.visible = false
	add_child(_hint)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _refresh() -> void:
	_hint.visible = _in_range and not _done


func interact() -> void:
	if _done or (_riddle and _riddle.visible):
		return
	Talk.say_seq([
		["The Camel", "Ho, traveler. None cross my dune untested."],
		["The Camel", "Answer true, and the sand shall part."],
	], Color(1.0, 0.85, 0.5))
	if _riddle == null:
		_riddle = Riddle.new()
		add_child(_riddle)
		_riddle.solved.connect(_on_solved)
	_riddle.start()


func _on_solved() -> void:
	_done = true
	_refresh()
	Talk.say_seq([
		["The Camel", "\"Illusion.\" ...Wisdom, in one so young."],
		["The Camel", "Pass, dreamer. And trust not your eyes ahead."],
	], Color(1.0, 0.85, 0.5))
	if target:
		target.set_deferred("collision_layer", 0)
		var tw := target.create_tween()
		tw.tween_property(target, "modulate:a", 0.0, 0.5)
	Audio.portal()
	var walk := create_tween()
	walk.tween_property(self, "position", position + Vector2(160, 0), 0.8)


func _draw() -> void:
	var tan := Color(0.82, 0.66, 0.42)
	var dark := Color(0.62, 0.48, 0.28)
	draw_circle(Vector2(0, 6), 30.0, Color(0, 0, 0, 0.22))          # shadow
	# legs
	for lx in [-16, -6, 6, 16]:
		draw_line(Vector2(lx, -6), Vector2(lx, 14), dark, 4.0)
	# body + two humps
	draw_circle(Vector2(0, -18), 22.0, tan)
	draw_circle(Vector2(-9, -34), 10.0, tan)
	draw_circle(Vector2(9, -34), 10.0, tan)
	# neck + head
	draw_line(Vector2(18, -22), Vector2(30, -48), tan, 8.0)
	draw_circle(Vector2(32, -50), 8.0, tan)
	draw_line(Vector2(32, -50), Vector2(42, -46), tan, 4.0)         # snout
	draw_circle(Vector2(34, -54), 1.6, Color.BLACK)                 # eye (sleepy)
	# a little sash, because he is wise
	draw_line(Vector2(-14, -30), Vector2(14, -8), Color(0.5, 0.3, 0.6), 3.0)
