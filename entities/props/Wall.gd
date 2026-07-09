class_name Wall
extends StaticBody2D
## A plain solid boundary — the edge of the room. Deliberately NOT mirror-styled
## and NOT in the "illusion" group: True Sight ignores it, because it isn't a
## puzzle piece, just the wall. Keeps the mirror-panel look reserved for
## IllusionWall, so players learn "shiny panel = maybe fake, flat stone = just wall".

var wall_size := Vector2(64, 96)
var tint := Color(0.72, 0.7, 0.78)   # set per level to match the mood
static var _tex: Texture2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 1
	if _tex == null:
		_tex = SpriteSheet.load_tex("res://assets/props/wall.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var col := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = wall_size
	col.shape = s
	col.position = Vector2(0, -wall_size.y * 0.5)
	add_child(col)


func _draw() -> void:
	var w := wall_size.x
	var h := wall_size.y
	var r := Rect2(-w * 0.5, -h, w, h)
	if _tex:
		draw_texture_rect(_tex, r, true, tint)   # real tiled brick, tinted to the mood
	else:
		draw_rect(r, Color(0.12, 0.11, 0.14))
	draw_rect(r, Color(0.02, 0.02, 0.03), false, 3.0)              # crisp dark edge
