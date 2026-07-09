class_name CrumbleFloor
extends Area2D
## Top-down adaptation of Shards-of-Reflection's crumbling mirage platform.
## Stepping on the tile cracks it; if Sara is still on it after a short grace it
## COLLAPSES — a burst of damage + knockback back the way she came — then reforms.
## Laid in rows across a corridor it becomes a bridge you must cross without
## stopping: impossible to simply stand clear of, unlike the old static traps.

var tile_size := Vector2(72, 72)
const GRACE := 0.4
const RESET := 1.4

enum { IDLE, WARN, COLLAPSED }
var _state := IDLE
var _t := 0.0
var _shimmer := 0.0
var _enter_from := Vector2.ZERO


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var c := CollisionShape2D.new()
	var s := RectangleShape2D.new(); s.size = tile_size
	c.shape = s
	add_child(c)
	body_entered.connect(_on_enter)
	z_index = -4
	set_process(true)


func _process(delta: float) -> void:
	_shimmer += delta
	match _state:
		WARN:
			_t -= delta
			if _t <= 0.0:
				# still standing here? collapse.
				var player_hit := false
				for b in get_overlapping_bodies():
					if (b.is_in_group("player") or b.is_in_group("enemy")) and b.has_method("take_damage"):
						b.take_damage(1, _enter_from)
						if b.is_in_group("player"):
							player_hit = true
				_state = COLLAPSED
				_t = RESET
				if player_hit:
					FX.add_trauma(0.3)
				FX.burst(global_position, Color(0.5, 0.45, 0.55), 12, 120.0)
		COLLAPSED:
			_t -= delta
			if _t <= 0.0:
				_state = IDLE
	queue_redraw()


func _on_enter(b: Node) -> void:
	if _state == IDLE and (b.is_in_group("player") or b.is_in_group("enemy")):
		_state = WARN
		_t = GRACE
		_enter_from = global_position + (global_position - (b as Node2D).global_position).normalized() * 40.0
		Audio.hit()


func _draw() -> void:
	var w := tile_size.x
	var h := tile_size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	match _state:
		IDLE:
			draw_rect(r, Color(0.20, 0.18, 0.24, 0.85))
			draw_rect(r, Color(0.35, 0.33, 0.42, 0.6), false, 2.0)
		WARN:
			var f := 0.5 + 0.5 * sin(_shimmer * 30.0)
			draw_rect(r, Color(0.35, 0.2, 0.2, 0.9))
			# cracks
			draw_line(Vector2(-w*0.4, -h*0.3), Vector2(w*0.2, h*0.4), Color(0.9, 0.4, 0.4, f), 2.0)
			draw_line(Vector2(w*0.3, -h*0.4), Vector2(-w*0.1, h*0.2), Color(0.9, 0.4, 0.4, f), 2.0)
			draw_rect(r, Color(1.0, 0.5, 0.4, f), false, 2.0)
		COLLAPSED:
			draw_rect(r, Color(0.02, 0.02, 0.04, 0.9))  # a void
			draw_rect(r.grow(-6), Color(0.05, 0.04, 0.08, 0.9))
