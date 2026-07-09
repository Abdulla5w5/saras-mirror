class_name MirrorShard
extends Area2D
## The goal of every dream-world: a glowing shard of Sara's mirror. Touch it to
## reclaim it. Emits `collected`; the level handles what happens next (open the
## exit portal / advance).

signal collected()

var accent := Color(0.7, 0.85, 1.0)
var locked := false                     # if true, can't be collected until unlocked
var _t := 0.0
var _taken := false

## Lets a lever/switch gate the shard: set_aligned(true) unlocks it.
func set_aligned(on: bool) -> void:
	locked = not on


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2                      # player body
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new(); s.radius = 26.0
	c.shape = s
	add_child(c)
	body_entered.connect(_on_body)
	z_index = 3
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_body(b: Node) -> void:
	if _taken or locked or not b.is_in_group("player"):
		return
	_taken = true
	Audio.shard()
	FX.illusion_break(global_position, accent)
	FX.flash(accent * 0.7, 0.4)
	FX.burst(global_position, accent, 30, 200.0)
	collected.emit()
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(2.2, 2.2), 0.3)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)


func _draw() -> void:
	if _taken:
		return
	var bob := sin(_t * 2.0) * 5.0
	var glow := 0.5 + 0.3 * sin(_t * 3.0)
	# halo
	draw_circle(Vector2(0, bob), 30.0, Color(accent.r, accent.g, accent.b, 0.12 * glow))
	draw_circle(Vector2(0, bob), 20.0, Color(accent.r, accent.g, accent.b, 0.18 * glow))
	# shard: an irregular sliver of mirror
	var a := _t * 0.6
	var pts := PackedVector2Array([
		Vector2(0, -18), Vector2(8, 2), Vector2(2, 16), Vector2(-6, 4)])
	var rot := Transform2D(a, Vector2(0, bob))
	var tp := PackedVector2Array()
	for p in pts:
		tp.append(rot * p)
	draw_colored_polygon(tp, Color(0.9, 0.95, 1.0, 0.95))
	# highlight edge
	draw_line(rot * pts[0], rot * pts[1], Color(1, 1, 1, 0.9), 2.0)
