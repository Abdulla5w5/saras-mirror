class_name IllusionWall
extends StaticBody2D
## A mirror-slab wall. Some are REAL (solid stone-glass) and some are ILLUSIONS
## that look identical until Sara's True Sight exposes them — a revealed illusion
## flickers, fades, and becomes permanently passable, opening the way forward.
## This is the core theme puzzle piece: you must read real from fake.
##
## Set `wall_size` and `real` before adding to the tree.

var wall_size := Vector2(64, 96)
var real := true
var tint := Color(0.55, 0.68, 1.0)

var _revealed_fake := false
var _shimmer := 0.0
var _flicker := 0.0
var _real_glow := 0.0
var _col: CollisionShape2D


func _ready() -> void:
	add_to_group("illusion")
	collision_layer = 1
	collision_mask = 0
	z_index = 1
	_col = CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = wall_size
	_col.shape = s
	_col.position = Vector2(0, -wall_size.y * 0.5)
	add_child(_col)
	set_process(true)


func _process(delta: float) -> void:
	_shimmer += delta
	if _flicker > 0.0:
		_flicker -= delta
	if _real_glow > 0.0:
		_real_glow -= delta
	queue_redraw()


func reveal(duration: float) -> void:
	if real:
		# Real walls answer True Sight unmistakably: a bright gold outline that
		# holds for the whole pulse, a confirming chime, and a sparkle burst —
		# as loud a "yes, solid" as the fake wall's "no, fake" collapse is.
		_real_glow = duration
		Audio.wall_confirm()
		FX.burst(global_position + Vector2(0, -wall_size.y * 0.5), Color(1.0, 0.9, 0.5), 10, 90.0)
		return
	if _revealed_fake:
		return
	_revealed_fake = true
	_flicker = 0.7
	# collapse the illusion
	_col.set_deferred("disabled", true)
	collision_layer = 0
	FX.illusion_break(global_position + Vector2(0, -wall_size.y * 0.5), tint)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.16, 0.6)


func _arch(hw: float, hh: float) -> PackedVector2Array:
	# an arched-top slab: base flush at y=0, arched crown at y=-hh
	return PackedVector2Array([
		Vector2(-hw, 0), Vector2(-hw, -hh * 0.84), Vector2(-hw * 0.68, -hh * 0.96),
		Vector2(0, -hh), Vector2(hw * 0.68, -hh * 0.96), Vector2(hw, -hh * 0.84),
		Vector2(hw, 0)])

func _draw() -> void:
	var hw := wall_size.x * 0.5
	var h := wall_size.y
	# ornate gold double frame
	draw_colored_polygon(_arch(hw, h), Color(0.72, 0.58, 0.28))
	draw_colored_polygon(_arch(hw - 5.0, h - 6.0), Color(0.55, 0.43, 0.2))
	# dark reflective glass, tinted by the panel's accent
	var glass := _arch(hw - 12.0, h - 14.0)
	draw_colored_polygon(glass, Color(0.09, 0.10, 0.16).lerp(tint * 0.5, 0.3))
	# drifting sheen streak on the glass
	var sx := sin(_shimmer * 0.8) * (hw * 0.4)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-hw * 0.5 + sx, -h * 0.9), Vector2(-hw * 0.22 + sx, -h * 0.9),
		Vector2(-hw * 0.4 + sx, -h * 0.05), Vector2(-hw * 0.6 + sx, -h * 0.3)]),
		Color(0.35, 0.42, 0.58, 0.35))
	# crest gem
	var gem := 0.6 + 0.3 * sin(_shimmer * 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -h + 2), Vector2(6, -h + 10), Vector2(0, -h + 18), Vector2(-6, -h + 10)]),
		Color(0.8, 0.88, 1.0, gem))

	# fake collapsing: cracks spider across the glass, then it fades (alpha tween)
	if _flicker > 0.0:
		for i in 5:
			var a := TAU * i / 5.0 + _shimmer
			draw_line(Vector2(0, -h * 0.5), Vector2(cos(a) * hw, -h * 0.5 + sin(a) * h * 0.5),
				Color(1, 1, 1, _flicker * 0.9), 1.5)
	# confirmed-real: a thick pulsing gold outline for the whole True Sight window
	if _real_glow > 0.0:
		var pulse := 0.6 + 0.4 * sin(_shimmer * 10.0)
		draw_polyline(_arch(hw + 4.0, h + 4.0), Color(1.0, 0.85, 0.4, pulse), 5.0)
