class_name Connect4
extends CanvasLayer
## A pop-up Connect-Four duel against the frog, in its own box (like the code
## lock). Board is 4 columns x 3 rows, connect 3 to win (the frog insists it's
## "Connect Four" anyway). Easy AI so Sara wins often. ← → pick a column, E drops.

signal won

const COLS := 4
const ROWS := 3
const NEED := 3
const CELL := 58.0

var grid: Array = []          # grid[c][r]: 0 empty, 1 Sara, 2 frog
var _sel := 0
var _turn := 1
var _over := false
var _result := 0              # 1 Sara won, 2 frog won
var _frog_wait := 0.0
var _active := false
var _lock := 0.0              # brief input lock so the opening E press doesn't drop
var _t := 0.0

var _board: Control
var _status: Label


func _ready() -> void:
	layer = 82
	visible = false
	_build()


func start() -> void:
	grid = []
	for c in COLS:
		grid.append([0, 0, 0])
	_sel = 0; _turn = 1; _over = false; _result = 0; _active = true; _lock = 0.25
	var p := Game.get_player()
	if p: p.set_physics_process(false)
	visible = true
	_update_status()


func _process(delta: float) -> void:
	_t += delta
	_board.queue_redraw()
	if not _active:
		return
	if _lock > 0.0:
		_lock -= delta
		return
	if _over:
		if Input.is_action_just_pressed(&"interact") or Input.is_action_just_pressed(&"attack"):
			if _result == 1:
				_finish_win()
			else:
				start()          # lost -> play again
		return
	if _turn == 1:
		if Input.is_action_just_pressed(&"move_left"):
			_sel = (_sel + COLS - 1) % COLS; Audio.ui()
		elif Input.is_action_just_pressed(&"move_right"):
			_sel = (_sel + 1) % COLS; Audio.ui()
		elif Input.is_action_just_pressed(&"interact") or Input.is_action_just_pressed(&"attack"):
			if _drop(_sel, 1):
				_turn = 2; _frog_wait = 0.7
	elif _turn == 2:
		_frog_wait -= delta
		if _frog_wait <= 0.0:
			_frog_move()
			if not _over:
				_turn = 1
	_update_status()


func _drop(col: int, who: int) -> bool:
	for r in ROWS:
		if grid[col][r] == 0:
			grid[col][r] = who
			if who == 1: Audio.shard()
			else: Audio.enemy_speak()
			if _check_win(col, r, who):
				_over = true; _result = who
			elif _board_full():
				_over = true; _result = 0
			return true
	return false                 # column full


func _frog_move() -> void:
	var valid: Array = []
	for c in COLS:
		if grid[c][ROWS - 1] == 0: valid.append(c)
	if valid.is_empty(): return
	# easy AI: sometimes win, sometimes block, mostly random
	var pick := _winning_col(2)
	if pick == -1 and randf() < 0.5: pick = _winning_col(1)
	if pick == -1: pick = valid[randi() % valid.size()]
	_drop(pick, 2)


func _winning_col(who: int) -> int:
	for c in COLS:
		for r in ROWS:
			if grid[c][r] == 0:
				grid[c][r] = who
				var win := _check_win(c, r, who)
				grid[c][r] = 0
				if win: return c
				break
	return -1


func _check_win(c: int, r: int, who: int) -> bool:
	for d in [[1, 0], [0, 1], [1, 1], [1, -1]]:
		var n := 1
		for s in [1, -1]:
			var cc: int = c + int(d[0]) * s
			var rr: int = r + int(d[1]) * s
			while cc >= 0 and cc < COLS and rr >= 0 and rr < ROWS and grid[cc][rr] == who:
				n += 1; cc += d[0] * s; rr += d[1] * s
		if n >= NEED: return true
	return false

func _board_full() -> bool:
	for c in COLS:
		if grid[c][ROWS - 1] == 0: return false
	return true


func _finish_win() -> void:
	_active = false
	visible = false
	var p := Game.get_player()
	if p: p.set_physics_process(true)
	won.emit()


func _update_status() -> void:
	if _over:
		_status.text = ("You beat the frog!  (E)" if _result == 1
			else ("A draw?!  (E to rematch)" if _result == 0 else "The frog won...  (E to rematch)"))
	else:
		_status.text = "Your turn — ◄ ► pick a column, E to drop" if _turn == 1 else "The frog is thinking. Ribbit."


func _build() -> void:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.08, 0.96)
	sb.border_color = Color(0.55, 0.9, 0.5); sb.set_border_width_all(3)
	sb.set_corner_radius_all(10); sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_top -= 150; panel.offset_bottom -= 150   # lift above the dialogue box
	add_child(panel)
	var vb := VBoxContainer.new(); vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12); panel.add_child(vb)
	var title := Label.new(); title.text = "CONNECT FOUR  (allegedly)"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.6, 1.0, 0.55))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(title)
	_board = Control.new()
	_board.custom_minimum_size = Vector2(COLS * CELL, (ROWS + 1) * CELL)
	_board.draw.connect(_draw_board.bind(_board))
	vb.add_child(_board)
	_status = Label.new(); _status.add_theme_font_size_override("font_size", 15)
	_status.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(_status)


func _draw_board(c: Control) -> void:
	var ox := 0.0
	var oy := CELL                 # top row reserved for the drop indicator
	# selection arrow
	if _active and not _over and _turn == 1:
		var ax := ox + _sel * CELL + CELL * 0.5
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(ax - 10, 12), Vector2(ax + 10, 12), Vector2(ax, 30)]), Color(0.9, 0.95, 1.0))
	# board frame
	c.draw_rect(Rect2(ox - 6, oy - 6, COLS * CELL + 12, ROWS * CELL + 12), Color(0.18, 0.30, 0.22))
	for col in COLS:
		for row in ROWS:
			var cx := ox + col * CELL + CELL * 0.5
			var cy := oy + (ROWS - 1 - row) * CELL + CELL * 0.5   # row 0 at bottom
			var v: int = grid[col][row] if grid.size() > col else 0
			var col_c := Color(0.05, 0.08, 0.06)
			if v == 1: col_c = Color(0.6, 0.8, 1.0)
			elif v == 2: col_c = Color(0.5, 0.9, 0.45)
			c.draw_circle(Vector2(cx, cy), CELL * 0.4, col_c)
			c.draw_arc(Vector2(cx, cy), CELL * 0.4, 0, TAU, 20, Color(0, 0, 0, 0.3), 2.0)
