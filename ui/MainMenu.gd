extends Control
## Title screen — an ornate museum mirror centerpiece (adapted from Shards of
## Reflection) with New Game / Continue / Quit over it.

func _ready() -> void:
	Talk.clear()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	RenderingServer.set_default_clear_color(Color(0.04, 0.04, 0.07))

	var vp := get_viewport_rect().size

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var mirror := MuseumMirror.new()
	mirror.mirror_scale = 1.05
	mirror.glowing = true
	mirror.modulate = Color(0.62, 0.66, 0.76, 0.9)
	mirror.position = Vector2(vp.x * 0.5, vp.y * 0.52)
	add_child(mirror)

	var title := Label.new()
	title.text = "SARA'S MIRROR"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.9, 0.94, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 74
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "a mirror, and the four worlds inside it"
	subtitle.add_theme_font_size_override("font_size", 19)
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.7, 0.82))
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.offset_top = 146
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12)
	vb.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	vb.offset_top = -180
	vb.offset_left = -120
	vb.offset_right = 120
	add_child(vb)

	if SaveManager.has_progress():
		vb.add_child(_button("Continue", func(): Audio.ui(); Game.continue_game()))
	vb.add_child(_button("New Game", func(): Audio.ui(); get_tree().change_scene_to_file("res://ui/IntroCutscene.tscn")))
	vb.add_child(_button("Quit", func(): Audio.ui(); get_tree().quit()))

	var hint := Label.new()
	hint.text = "WASD move  ·  J strike  ·  Q True Sight  ·  Shift dash  ·  E interact  ·  M mute"
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.42, 0.46, 0.56))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_bottom = -18
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 44)
	b.pressed.connect(cb)
	return b
