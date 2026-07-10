class_name SlideWall
extends StaticBody2D
## Adapted from AlignPiece: a solid mirror-panel that tweens between its home
## position and an aligned offset when a lever calls set_aligned(). Used to slide
## a blocking panel out of a corridor, or slide one IN to bridge a hazard.

var wall_size := Vector2(80, 180)
var aligned_offset := Vector2(0, -200)
var tint := Color(0.6, 0.7, 1.0)

var texture: Texture2D = null   # optional real gate art (drawn instead of the slab)

var _home := Vector2.ZERO
var _tween: Tween


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = -1   # draw behind Sara so she reads as standing in front, not under
	if texture:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var col := CollisionShape2D.new()
	var s := RectangleShape2D.new(); s.size = wall_size
	col.shape = s
	col.position = Vector2(0, -wall_size.y * 0.5)   # base-anchored (matches Wall/IllusionWall)
	add_child(col)
	_home = position


func set_aligned(on: bool) -> void:
	var target := _home + (aligned_offset if on else Vector2.ZERO)
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target, 0.6)


# An arched-top plate: base flush at y=0, straight sides, then a smooth arched
# crown up to the peak — so the gate silhouette is a doorway, not a flat bar.
func _plate(hw: float, h: float, crown: float) -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2(-hw, 0), Vector2(-hw, -(h - crown))])
	for i in 9:
		var t := float(i) / 8.0
		pts.append(Vector2(lerp(-hw, hw, t), -(h - crown) - sin(t * PI) * crown))
	pts.append(Vector2(hw, -(h - crown)))
	pts.append(Vector2(hw, 0))
	return pts

func _draw() -> void:
	var w := wall_size.x
	var h := wall_size.y
	var hw := w * 0.5
	var crown: float = min(h * 0.22, hw * 0.55)
	var gold := Color(0.66, 0.52, 0.26)
	var gold_d := Color(0.40, 0.30, 0.14)
	# layered arched frame
	draw_colored_polygon(_plate(hw + 5.0, h + 5.0, crown + 4.0), Color(0.03, 0.02, 0.05))  # drop edge
	draw_colored_polygon(_plate(hw, h, crown), gold)                     # gold frame
	draw_colored_polygon(_plate(hw - 6.0, h - 6.0, crown * 0.9), gold_d)   # bevel
	draw_colored_polygon(_plate(hw - 14.0, h - 16.0, crown * 0.8),
		Color(0.08, 0.09, 0.16).lerp(tint * 0.5, 0.4))                   # reflective glass
	# gold mullions split the glass into leaded panels
	var panels: int = max(2, int(round(w / 70.0)))
	for i in range(1, panels):
		var mx := -hw + w * float(i) / panels
		draw_rect(Rect2(mx - 2.0, -(h - crown - 6.0), 4.0, h - crown - 18.0), gold)
	# static diagonal sheen across the glass
	draw_colored_polygon(PackedVector2Array([
		Vector2(-hw * 0.55, -h + crown), Vector2(-hw * 0.2, -h + crown),
		Vector2(-hw * 0.42, -6.0), Vector2(-hw * 0.72, -6.0)]),
		Color(0.45, 0.55, 0.75, 0.22))
	# corner studs + crowning gem
	for cx in [-hw + 9.0, hw - 9.0]:
		draw_circle(Vector2(cx, -10.0), 4.0, gold)
	draw_circle(Vector2(0, -(h - crown * 0.4)), 6.0, Color(0.9, 0.95, 1.0, 0.9))
	# central medallion
	var c := Vector2(0, -h * 0.46)
	draw_circle(c, 15.0, gold)
	draw_circle(c, 10.0, Color(0.9, 0.95, 1.0, 0.85))
	# crisp closed outline
	var outline := _plate(hw, h, crown)
	outline.append(outline[0])
	draw_polyline(outline, Color(0.03, 0.02, 0.05), 3.0)
