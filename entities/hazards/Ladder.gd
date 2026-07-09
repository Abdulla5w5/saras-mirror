class_name Ladder
extends Area2D
## A ladder lying on the ground. Interact (E) to pick it up; carry it to a
## quicksand band and interact with the sand to lay it across and walk over.
## In group "interactable".

var accent := Color(0.8, 0.65, 0.4)
var _t := 0.0
var _hint: Label


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 2
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new(); s.radius = 46.0
	c.shape = s
	add_child(c)
	body_entered.connect(func(b): if b.is_in_group("player"): _hint.visible = true)
	body_exited.connect(func(b): if b.is_in_group("player"): _hint.visible = false)
	z_index = -2

	_hint = Label.new()
	_hint.text = "E  take ladder"
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.position = Vector2(-40, -44)
	_hint.visible = false
	add_child(_hint)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func interact() -> void:
	var p := Game.get_player()
	if p and p.has_method("give_ladder"):
		p.give_ladder()
		Audio.ui()
		Talk.say("Sara", "A ladder. I can lay this across the sinking sand — get close and press E on it.")
		queue_free()


func _draw() -> void:
	var glow := 0.5 + 0.3 * sin(_t * 2.0)
	draw_circle(Vector2(0, 0), 30.0, Color(accent.r, accent.g, accent.b, 0.08 * glow))
	# a ladder lying flat (¾ view), two rails + rungs
	var c := accent
	draw_line(Vector2(-46, -8), Vector2(46, -8), c, 4.0)
	draw_line(Vector2(-46, 8), Vector2(46, 8), c, 4.0)
	for i in 7:
		var x := -40.0 + i * 13.0
		draw_line(Vector2(x, -8), Vector2(x, 8), c.darkened(0.15), 3.0)
