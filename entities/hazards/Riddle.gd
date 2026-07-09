class_name Riddle
extends CanvasLayer
## A typed-answer riddle box (like the code lock, but you type the word). The
## camel's riddle; answer "illusion" to pass. Emits `solved`.

signal solved

var answer := "illusion"
var _edit: LineEdit
var _msg: Label


func _ready() -> void:
	layer = 82
	visible = false
	_build()


func start() -> void:
	var p := Game.get_player()
	if p: p.set_physics_process(false)
	visible = true
	_edit.text = ""
	_msg.text = ""
	_edit.grab_focus()


func _check(t: String) -> void:
	if t.strip_edges().to_lower() == answer:
		visible = false
		var p := Game.get_player()
		if p: p.set_physics_process(true)
		Audio.shard()
		solved.emit()
	else:
		_msg.text = "The camel snorts. \"Look closer, dreamer...\""
		_edit.text = ""
		_edit.grab_focus()


func _build() -> void:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.05, 0.96)
	sb.border_color = Color(0.95, 0.82, 0.45); sb.set_border_width_all(3)
	sb.set_corner_radius_all(10); sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_top -= 150; panel.offset_bottom -= 150   # above the dialogue box
	add_child(panel)
	var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation", 12); panel.add_child(vb)
	var title := Label.new(); title.text = "THE CAMEL'S RIDDLE"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	vb.add_child(title)
	var body := Label.new()
	body.text = "\"What has no form, yet can deceive the eye,\nmaking you see what isn't there,\nand can change with a blink or a sigh?\""
	body.add_theme_font_size_override("font_size", 16)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(body)
	_edit = LineEdit.new()
	_edit.placeholder_text = "type your answer, then Enter"
	_edit.custom_minimum_size = Vector2(320, 0)
	_edit.text_submitted.connect(_check)
	vb.add_child(_edit)
	_msg = Label.new(); _msg.add_theme_font_size_override("font_size", 14)
	_msg.add_theme_color_override("font_color", Color(1.0, 0.6, 0.5))
	vb.add_child(_msg)
