class_name SweepHazard
extends Node2D
## Top-down adaptation of the moving platform, turned into a roaming hazard: a
## "mirror-blade" of light patrols back and forth across a corridor, so the only
## way past is to time the gap and move — you cannot simply stand clear of it.
## Damages Sara on contact with a short cooldown.

var travel := Vector2(280, 0)   # offset to far point
var time := 1.6                 # seconds per leg
var blade_size := Vector2(30, 150)
var tint := Color(0.7, 0.85, 1.0)

var _hazard: Area2D
var _t := 0.0
var _cd := 0.0
var _home := Vector2.ZERO
var _visual: Node2D


func _ready() -> void:
	_home = position
	_hazard = Area2D.new()
	_hazard.collision_layer = 0
	_hazard.collision_mask = 2
	var c := CollisionShape2D.new()
	var s := RectangleShape2D.new(); s.size = blade_size
	c.shape = s
	_hazard.add_child(c)
	add_child(_hazard)

	var tw := create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_hazard, "position", travel, time)
	tw.tween_property(_hazard, "position", Vector2.ZERO, time)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	_cd = maxf(_cd - delta, 0.0)
	if _cd <= 0.0:
		var hit := false
		for b in _hazard.get_overlapping_bodies():
			if (b.is_in_group("player") or b.is_in_group("enemy")) and b.has_method("take_damage"):
				b.take_damage(1, _hazard.global_position)
				hit = true
				if b.is_in_group("player"):
					FX.add_trauma(0.2)
		if hit:
			_cd = 0.7
	queue_redraw()


func _draw() -> void:
	var w := blade_size.x
	var h := blade_size.y
	var p := _hazard.position
	var glow := 0.5 + 0.3 * sin(_t * 8.0)
	draw_rect(Rect2(p.x - w * 0.5, p.y - h * 0.5, w, h), Color(tint.r, tint.g, tint.b, 0.35 * glow))
	draw_rect(Rect2(p.x - 3, p.y - h * 0.5, 6, h), Color(1, 1, 1, 0.8 * glow))
	# faint track showing where it patrols
	draw_line(_home_delta(0), _home_delta(1), Color(tint.r, tint.g, tint.b, 0.08), 2.0)

func _home_delta(k: float) -> Vector2:
	return Vector2(travel.x * k, travel.y * k) + Vector2(0, 0)
