class_name PhaseGate
extends StaticBody2D
## Top-down adaptation of the phase platform: a barrier across a corridor that
## blinks SOLID <-> OPEN on a timer, with a warning flash just before it closes.
## Because it spans the whole neck of a passage, you can't route around it — you
## have to read the rhythm and dash through the gap. Give neighbouring gates
## different `offset` values to build a wave.

var gate_size := Vector2(48, 200)
var solid_time := 1.8
var open_time := 1.4
var offset := 0.0
var tint := Color(0.6, 0.75, 1.0)

var _t := 0.0
var _solid := true
var _col: CollisionShape2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 1
	_col = CollisionShape2D.new()
	var s := RectangleShape2D.new(); s.size = gate_size
	_col.shape = s
	add_child(_col)
	_t = offset
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	var now := fmod(_t, solid_time + open_time) < solid_time
	if now != _solid:
		_solid = now
		_col.set_deferred("disabled", not _solid)
		if _solid:
			Audio.wall_confirm()
	queue_redraw()


func _closing_soon() -> bool:
	var c := fmod(_t, solid_time + open_time)
	return not _solid and c > (solid_time + open_time - 0.5)


func _draw() -> void:
	var w := gate_size.x
	var h := gate_size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	if _solid:
		# energy wall of vertical mirror bars
		for i in int(h / 16.0):
			var y := -h * 0.5 + i * 16.0
			var a := 0.7 + 0.3 * sin(_t * 6.0 + i)
			draw_rect(Rect2(-w * 0.5, y, w, 14), Color(tint.r, tint.g, tint.b, a * 0.8))
		draw_rect(r, Color(1, 1, 1, 0.5), false, 2.0)
	else:
		var warn := _closing_soon()
		var a := (0.5 + 0.5 * sin(_t * 24.0)) if warn else 0.14
		var col := Color(1.0, 0.6, 0.5) if warn else tint
		draw_rect(r, Color(col.r, col.g, col.b, a * 0.5), false, 2.0)
