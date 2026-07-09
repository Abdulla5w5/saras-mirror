class_name AlignLever
extends Area2D
## Adapted from Shards-of-Reflection's AlignLever: an interactable (E) that
## toggles a set of targets implementing set_aligned(bool) — SlideWalls,
## PhaseGates (disabled), etc. Drives the "align the mirrors to open the way"
## puzzle. Wire `targets` (nodes) before adding to the tree.

var targets: Array = []          # nodes with set_aligned(bool)
var accent := Color(0.7, 0.85, 1.0)
var one_shot := false

var _aligned := false
var _locked := false
var _in_range := false
var _t := 0.0
var _hint: Label


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 2
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new(); s.radius = 44.0
	c.shape = s
	add_child(c)
	body_entered.connect(func(b): if b.is_in_group("player"): _in_range = true; _refresh_hint())
	body_exited.connect(func(b): if b.is_in_group("player"): _in_range = false; _refresh_hint())
	z_index = 2

	_hint = Label.new()
	_hint.text = "E"
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.position = Vector2(-6, -60)
	_hint.visible = false
	add_child(_hint)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _refresh_hint() -> void:
	_hint.visible = _in_range and not _locked

# Called by the player's interact probe.
func interact() -> void:
	if _locked:
		return
	_aligned = not _aligned
	for tnode in targets:
		if is_instance_valid(tnode) and tnode.has_method("set_aligned"):
			tnode.set_aligned(_aligned)
	Audio.wall_confirm()
	FX.burst(global_position, accent, 12, 100.0)
	FX.add_trauma(0.12)
	if _aligned and one_shot:
		_locked = true
		_refresh_hint()


func _draw() -> void:
	# a small mirror-lever plinth with a handle that swings when aligned
	draw_circle(Vector2(0, 0), 16.0, Color(0.1, 0.11, 0.18))
	draw_circle(Vector2(0, 0), 16.0, accent * Color(1, 1, 1, 0.8) if _aligned else Color(0.3, 0.34, 0.45))
	var ang := (-0.7 if _aligned else 0.7)
	draw_line(Vector2.ZERO, Vector2(sin(ang), -cos(ang)) * 22.0, Color(0.85, 0.88, 1.0), 4.0)
	draw_circle(Vector2(sin(ang), -cos(ang)) * 22.0, 5.0, accent)
