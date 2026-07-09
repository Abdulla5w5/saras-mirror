class_name SlideWall
extends StaticBody2D
## Adapted from AlignPiece: a solid mirror-panel that tweens between its home
## position and an aligned offset when a lever calls set_aligned(). Used to slide
## a blocking panel out of a corridor, or slide one IN to bridge a hazard.

var wall_size := Vector2(80, 180)
var aligned_offset := Vector2(0, -200)
var tint := Color(0.6, 0.7, 1.0)

var _home := Vector2.ZERO
var _tween: Tween


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 1
	var col := CollisionShape2D.new()
	var s := RectangleShape2D.new(); s.size = wall_size
	col.shape = s
	add_child(col)
	_home = position


func set_aligned(on: bool) -> void:
	var target := _home + (aligned_offset if on else Vector2.ZERO)
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target, 0.6)


func _draw() -> void:
	var w := wall_size.x
	var h := wall_size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	for i in 8:
		var t := float(i) / 7.0
		draw_rect(Rect2(-w * 0.5, -h * 0.5 + h * t, w, h / 8.0 + 1), Color(0.12, 0.13, 0.2).lerp(tint * 0.7, t * 0.6))
	draw_rect(r, Color(0.02, 0.02, 0.05), false, 3.0)
