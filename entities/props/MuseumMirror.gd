class_name MuseumMirror
extends Node2D
## An ornate standing museum mirror, adapted (vector-drawn, no image assets) from
## Shards of Reflection. Used as the title-screen centerpiece and the whole
## mirror on Sara's bedroom wall in the ending. `filled` (0..4) lights that many
## shard-pieces; whole = a seamless glowing surface.

@export var mirror_scale := 1.0
@export var show_stand := true
@export var glowing := false

var _t := 0.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _poly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(Vector2(p[0], p[1]) * mirror_scale)
	return out


func _draw() -> void:
	# soft spotlight cone from above
	draw_colored_polygon(_poly([[-34,-270],[34,-270],[170,210],[-170,210]]), Color(1, 0.97, 0.85, 0.05))

	if show_stand:
		draw_colored_polygon(_poly([[-90,214],[90,214],[90,238],[-90,238]]), Color(0.22, 0.17, 0.1))      # plinth
		draw_colored_polygon(_poly([[-42,150],[42,150],[72,216],[-72,216]]), Color(0.4, 0.3, 0.16))        # pedestal

	# gold frame (outer + mid), then dark glass
	draw_colored_polygon(_poly([[-96,160],[-96,-120],[-74,-162],[-42,-188],[0,-196],[42,-188],[74,-162],[96,-120],[96,160]]), Color(0.72, 0.58, 0.28))
	draw_colored_polygon(_poly([[-84,150],[-84,-114],[-64,-152],[-36,-176],[0,-183],[36,-176],[64,-152],[84,-114],[84,150]]), Color(0.55, 0.43, 0.2))
	var glass := _poly([[-72,140],[-72,-108],[-55,-143],[-31,-165],[0,-171],[31,-165],[55,-143],[72,-108],[72,140]])
	draw_colored_polygon(glass, Color(0.1, 0.12, 0.18))

	# whole-glass glow
	if glowing:
		var g := 0.4 + 0.25 * sin(_t * 1.6)
		draw_colored_polygon(glass, Color(0.8, 0.92, 1.0, g))

	# drifting sheen streak
	var sx := sin(_t * 0.7) * 30.0 * mirror_scale
	draw_colored_polygon([
		Vector2(-58, -150) * mirror_scale + Vector2(sx, 0),
		Vector2(-30, -150) * mirror_scale + Vector2(sx, 0),
		Vector2(-50, 132) * mirror_scale + Vector2(sx, 0),
		Vector2(-68, 96) * mirror_scale + Vector2(sx, 0)], Color(0.22, 0.28, 0.4, 0.4))

	# crest + gem, side flourishes
	draw_colored_polygon(_poly([[0,-226],[16,-200],[0,-180],[-16,-200]]), Color(0.72, 0.58, 0.28))
	var gem := 0.7 + 0.3 * sin(_t * 2.0)
	draw_colored_polygon(_poly([[0,-210],[7,-200],[0,-190],[-7,-200]]), Color(0.75, 0.85, 1.0, gem))
	draw_colored_polygon(_poly([[-96,4],[-84,20],[-96,36],[-108,20]]), Color(0.72, 0.58, 0.28))
	draw_colored_polygon(_poly([[96,4],[108,20],[96,36],[84,20]]), Color(0.72, 0.58, 0.28))
