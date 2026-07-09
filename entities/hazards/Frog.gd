class_name Frog
extends Area2D
## A pompous frog guarding the way. Interact (E) to duel it at Connect Four; win
## and it hops aside, opening its gate. Comedy is the point. In group "interactable".

var target: Node = null        # the gate wall to open on victory
var _t := 0.0
var _in_range := false
var _done := false
var _game: Connect4
var _hint: Label
var _blink := 0.0


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 2
	var col := CollisionShape2D.new()
	var s := CircleShape2D.new(); s.radius = 50.0
	col.shape = s
	add_child(col)
	body_entered.connect(func(b): if b.is_in_group("player"): _in_range = true; _refresh())
	body_exited.connect(func(b): if b.is_in_group("player"): _in_range = false; _refresh())
	z_index = 5
	_hint = Label.new()
	_hint.text = "E: duel the frog"
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.position = Vector2(-44, -78)
	_hint.visible = false
	add_child(_hint)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	_blink = maxf(_blink - delta, 0.0)
	if randf() < 0.004: _blink = 0.16
	queue_redraw()

func _refresh() -> void:
	_hint.visible = _in_range and not _done


func interact() -> void:
	if _done or (_game and _game._active):
		return
	Talk.say_seq([
		["The Frog", "HALT. None cross my bridge without besting me at... CONNECT FOUR."],
		["Sara", "...that board has three rows."],
		["The Frog", "It is REGULATION. Ribbit."],
	], Color(0.6, 1.0, 0.55))
	if _game == null:
		_game = Connect4.new()
		add_child(_game)
		_game.won.connect(_on_win)
	_game.start()


func _on_win() -> void:
	_done = true
	_refresh()
	Talk.say_seq([
		["The Frog", "IMPOSSIBLE. I have ruled this bog for a thousand years!"],
		["Sara", "It took like four moves."],
		["The Frog", "...I shall go sulk under a log. Ribbit."],
	], Color(0.6, 1.0, 0.55))
	# open the gate
	if target:
		target.set_deferred("collision_layer", 0)
		var tw := target.create_tween()
		tw.tween_property(target, "modulate:a", 0.0, 0.5)
	Audio.portal()
	# frog hops off to the side
	var hop := create_tween()
	hop.set_trans(Tween.TRANS_SINE)
	hop.tween_property(self, "position", position + Vector2(120, -30), 0.4)
	hop.tween_property(self, "position", position + Vector2(240, 0), 0.4)


func _draw() -> void:
	# a goofy round frog, ¾ view
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# shadow
	draw_circle(Vector2(0, 4), 26.0, Color(0, 0, 0, 0.25))
	# body
	var body := Color(0.42, 0.78, 0.36)
	draw_circle(Vector2(0, -14), 24.0, body)
	# hind legs
	draw_circle(Vector2(-20, -2), 9.0, body)
	draw_circle(Vector2(20, -2), 9.0, body)
	# belly
	draw_circle(Vector2(0, -8), 12.0, Color(0.85, 0.92, 0.6))
	# eyes (bulging)
	for sx in [-11.0, 11.0]:
		draw_circle(Vector2(sx, -34), 9.0, body)
		draw_circle(Vector2(sx, -34), 6.0, Color(1, 1, 1))
		if _blink <= 0.0:
			draw_circle(Vector2(sx, -34), 3.0, Color.BLACK)
		else:
			draw_line(Vector2(sx - 4, -34), Vector2(sx + 4, -34), Color.BLACK, 2.0)
	# smug smile
	draw_arc(Vector2(0, -14), 12.0, 0.15, PI - 0.15, 12, Color(0.1, 0.2, 0.1), 2.0)
	# a tiny crown, because he thinks he's king
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -46), Vector2(-6, -54), Vector2(0, -48), Vector2(6, -54), Vector2(10, -46)]),
		Color(1.0, 0.85, 0.3))
