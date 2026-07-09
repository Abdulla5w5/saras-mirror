extends Node
## Voice-over text box. Enemies, signs and Sara's own thoughts push short lines
## here; each line has a speaker + text so it can be dubbed later. A single
## bottom-of-screen box shows one line at a time with a typewriter effect and
## auto-advances; the player can also press E / click to skip ahead.
##
## Usage:  Talk.say("The Warden", "You cannot leave what was never real.")
##         Talk.say_seq([["Sara","..."], ["The Warden","..."]])

signal line_shown(speaker: String, text: String)
signal queue_finished()

const CPS := 34.0          # typewriter characters per second
const HOLD := 5.0          # base seconds to hold a fully-typed line (scaled by length)
const MIN_SHOW := 0.9      # min time before a line can be skipped

var _layer: CanvasLayer
var _panel: PanelContainer
var _speaker: Label
var _body: Label
var _queue: Array = []      # each: {speaker, text, color}
var _typing := false
var _shown := 0.0
var _full := ""
var _char_t := 0.0
var _done_hold := 0.0
var _line_color := Color(0.9, 0.92, 1.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 80
	add_child(_layer)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	margin.offset_top = -180
	margin.add_theme_constant_override("margin_left", 90)
	margin.add_theme_constant_override("margin_right", 90)
	margin.add_theme_constant_override("margin_bottom", 28)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(margin)

	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.09, 0.9)
	sb.border_color = Color(0.5, 0.6, 0.9, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 8
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	_panel.add_child(vb)

	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 18)
	_speaker.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	vb.add_child(_speaker)

	_body = Label.new()
	_body.add_theme_font_size_override("font_size", 22)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(0, 52)
	vb.add_child(_body)

	_layer.visible = false


func _process(delta: float) -> void:
	if _queue.is_empty() and not _typing:
		if _layer.visible:
			_layer.visible = false
		return
	_shown += delta
	if _typing:
		_char_t += delta * CPS
		var n := int(_char_t)
		if n >= _full.length():
			_body.text = _full
			_typing = false
			_done_hold = 0.0
		else:
			_body.text = _full.substr(0, n)
		if Input.is_action_just_pressed(&"interact") or Input.is_action_just_pressed(&"attack"):
			if _shown > MIN_SHOW:
				_char_t = _full.length()      # snap to full
	else:
		_done_hold += delta
		var skip := (Input.is_action_just_pressed(&"interact") or Input.is_action_just_pressed(&"attack")) and _shown > MIN_SHOW
		# hold longer for longer lines so there's always time to read
		if _done_hold >= HOLD + _full.length() * 0.05 or skip:
			_advance()


func say(speaker: String, text: String, color := Color(0.9, 0.92, 1.0)) -> void:
	_queue.append({speaker = speaker, text = text, color = color})
	if not _typing and _body.text.is_empty():
		_advance()

func say_seq(lines: Array, color := Color(0.9, 0.92, 1.0)) -> void:
	for l in lines:
		if l is Array and l.size() >= 2:
			_queue.append({speaker = String(l[0]), text = String(l[1]), color = color})
	if not _typing and _body.text.is_empty():
		_advance()

func is_busy() -> bool:
	return _typing or not _queue.is_empty()

func clear() -> void:
	_queue.clear()
	_typing = false
	_body.text = ""
	_layer.visible = false


func _advance() -> void:
	if _queue.is_empty():
		_typing = false
		_body.text = ""
		_layer.visible = false
		queue_finished.emit()
		return
	var l: Dictionary = _queue.pop_front()
	_speaker.text = l.speaker
	_line_color = l.color
	_body.add_theme_color_override("font_color", _line_color)
	_full = l.text
	_body.text = ""
	_typing = true
	_char_t = 0.0
	_shown = 0.0
	_layer.visible = true
	Audio.enemy_speak()
	line_shown.emit(l.speaker, l.text)
