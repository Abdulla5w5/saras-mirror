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
	z_index = 1
	if texture:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
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
	# ornate gold-framed mirror gate — clear borders, matches the mirror hall
	draw_rect(r.grow(4), Color(0.66, 0.52, 0.26))                 # outer gold frame
	draw_rect(r.grow(-4), Color(0.44, 0.34, 0.16))               # inner gold bevel
	var glass := r.grow(-14)
	draw_rect(glass, Color(0.10, 0.10, 0.18).lerp(tint * 0.4, 0.4))  # dark reflective panel
	# vertical light bars down the glass
	var bars := 4
	for i in bars:
		var bx := glass.position.x + glass.size.x * (float(i) + 0.5) / bars
		draw_rect(Rect2(bx - 3, glass.position.y + 6, 6, glass.size.y - 12), Color(tint.r, tint.g, tint.b, 0.35))
	# central medallion
	var c := r.get_center()
	draw_circle(c, 16.0, Color(0.66, 0.52, 0.26))
	draw_circle(c, 11.0, Color(0.9, 0.95, 1.0, 0.8))
	# crisp outline
	draw_rect(r.grow(4), Color(0.03, 0.02, 0.05), false, 3.0)
