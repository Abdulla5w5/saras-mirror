class_name TrapSpikes
extends Area2D
## An illusory floor trap: invisible until True Sight exposes the spikes beneath.
## Stepping on it always hurts — True Sight just lets Sara SEE the danger so she
## can route around it. Reveal, remember, cross. In group "illusion".

var trap_size := Vector2(96, 64)
var _alpha := 0.0
var _reveal_left := 0.0
var _cool := 0.0


func _ready() -> void:
	add_to_group("illusion")
	collision_layer = 0
	collision_mask = 2                      # detect the player body
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = trap_size
	c.shape = r
	add_child(c)
	body_entered.connect(_on_body)
	z_index = 0


func _process(delta: float) -> void:
	_cool = maxf(_cool - delta, 0.0)
	if _reveal_left > 0.0:
		_reveal_left -= delta
		_alpha = minf(_alpha + delta * 4.0, 1.0)
	else:
		_alpha = maxf(_alpha - delta * 2.0, 0.0)
	queue_redraw()


func reveal(duration: float) -> void:
	_reveal_left = duration


func _on_body(b: Node) -> void:
	if _cool > 0.0:
		return
	if (b.is_in_group("player") or b.is_in_group("enemy")) and b.has_method("take_damage"):
		_cool = 0.5
		b.take_damage(1, global_position)
		if b.is_in_group("player"):
			FX.add_trauma(0.25)
		_reveal_left = maxf(_reveal_left, 0.5)


func _draw() -> void:
	if _alpha <= 0.01:
		return
	var w := trap_size.x
	var h := trap_size.y
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(0.4, 0.05, 0.08, 0.35 * _alpha))
	var n := int(w / 16.0)
	for i in n:
		var x := -w * 0.5 + 8 + i * 16.0
		var pts := PackedVector2Array([
			Vector2(x - 7, h * 0.5 - 2),
			Vector2(x, -h * 0.4),
			Vector2(x + 7, h * 0.5 - 2)])
		draw_colored_polygon(pts, Color(0.8, 0.82, 0.9, _alpha))
		draw_line(Vector2(x, -h * 0.4), Vector2(x, h * 0.5 - 2), Color(0.5, 0.5, 0.6, _alpha), 1.0)
