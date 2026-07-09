class_name Wall
extends StaticBody2D
## A plain solid boundary — the edge of the room. Deliberately NOT mirror-styled
## and NOT in the "illusion" group: True Sight ignores it, because it isn't a
## puzzle piece, just the wall. Keeps the mirror-panel look reserved for
## IllusionWall, so players learn "shiny panel = maybe fake, flat stone = just wall".

var wall_size := Vector2(64, 96)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 1
	var col := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = wall_size
	col.shape = s
	col.position = Vector2(0, -wall_size.y * 0.5)
	add_child(col)


func _draw() -> void:
	var w := wall_size.x
	var h := wall_size.y
	var top := -h
	draw_rect(Rect2(-w * 0.5, top, w, h), Color(0.09, 0.08, 0.11))
	# rough stone seams, cheap static hatching
	var rows := maxi(int(h / 40.0), 1)
	for i in rows:
		var y := top + 40.0 * i
		draw_line(Vector2(-w * 0.5, y), Vector2(w * 0.5, y), Color(0.03, 0.03, 0.04), 2.0)
	draw_rect(Rect2(-w * 0.5, top, w, h), Color(0.02, 0.02, 0.03), false, 3.0)
