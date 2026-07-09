class_name Snake
extends Area2D
## A serpent slithering back and forth across a swamp band. Contact bites Sara
## (or an enemy). Patrols the flanks so the ladder's central strip stays clear.

var range_x := 120.0
var speed := 1.1
var tint := Color(0.45, 0.85, 0.35)

var _home := Vector2.ZERO
var _t := 0.0
var _cd := 0.0
var _dir := 1.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new(); s.radius = 16.0
	c.shape = s
	add_child(c)
	_home = position
	z_index = 4
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	_cd = maxf(_cd - delta, 0.0)
	var prev := position.x
	position.x = _home.x + sin(_t * speed) * range_x
	_dir = signf(position.x - prev) if position.x != prev else _dir
	if _cd <= 0.0:
		for b in get_overlapping_bodies():
			if (b.is_in_group("player") or b.is_in_group("enemy")) and b.has_method("take_damage"):
				b.take_damage(1, global_position)
				_cd = 0.8
				if b.is_in_group("player"):
					FX.add_trauma(0.2)
	queue_redraw()


func _draw() -> void:
	# a wiggling serpent body of segments, head leading the travel direction
	var seg := 8
	var pts := PackedVector2Array()
	for i in seg:
		var x := -_dir * i * 9.0
		var y := sin(_t * 6.0 + i * 0.9) * 7.0
		pts.append(Vector2(x, y))
	for i in range(seg - 1):
		var a := 1.0 - float(i) / seg
		draw_line(pts[i], pts[i + 1], Color(tint.r, tint.g, tint.b, 0.6 + 0.4 * a), 8.0 - i * 0.6)
	# head + eyes
	draw_circle(pts[0], 7.0, tint.lightened(0.1))
	draw_circle(pts[0] + Vector2(-_dir * 2, -2), 1.6, Color.BLACK)
