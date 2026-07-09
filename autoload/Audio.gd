extends Node
## Procedural audio — no asset files required. A single AudioStreamGenerator is
## fed a small pool of synth "voices" (sine/square/tri/noise with an exponential
## decay envelope), so every meaningful action gets a sound. Named helpers
## (shard, reveal, hit, step, ui...) keep call sites readable. Music is a slow,
## evolving two-note pad that can be muted with M.
##
## Drop-in CC0 OGGs can later replace these via play_sfx()/registry if desired.

const MIX_RATE := 44100.0

var _player: AudioStreamPlayer
var _pb: AudioStreamGeneratorPlayback
var _voices: Array = []            # each: {freq, phase, t, dur, type, vol, sweep}
var _muted := false
var _music_on := true
var _music_t := 0.0
var _music_step := 0.0

# Ambient pad roots per dream-world (Hz). Set by levels via set_mood().
var _pad_root := 110.0
var _pad_fifth := 164.81


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.12
	_player = AudioStreamPlayer.new()
	_player.stream = gen
	_player.bus = "Master"
	_player.autoplay = false
	add_child(_player)
	_player.play()
	_pb = _player.get_stream_playback()


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_M) and not _mute_latch:
		toggle_mute()
	if not Input.is_key_pressed(KEY_M):
		_mute_latch = false

	_music_t += delta
	# Schedule a soft pad note roughly every 2.4s while music is on.
	if _music_on and not _muted:
		_music_step -= delta
		if _music_step <= 0.0:
			_music_step = 2.4
			_pad(_pad_root, 2.2, 0.06)
			_pad(_pad_fifth, 2.2, 0.045)

	if _pb == null:
		return
	var frames := _pb.get_frames_available()
	if frames <= 0:
		return
	var gain := 0.0 if _muted else 1.0
	for _i in frames:
		var s := 0.0
		for v in _voices:
			if v.t < 0.0:                       # scheduled but not started yet
				v.t += 1.0 / MIX_RATE
				continue
			var env: float = pow(0.5, v.t / maxf(v.dur, 0.001)) # exp decay
			var f: float = v.freq + v.sweep * v.t
			var ph: float = v.phase
			var w := 0.0
			match int(v.type):
				0: w = sin(ph)                                   # sine
				1: w = 1.0 if sin(ph) >= 0.0 else -1.0           # square
				2: w = asin(sin(ph)) * 0.6366                    # triangle
				3: w = randf() * 2.0 - 1.0                       # noise
			s += w * env * v.vol
			v.phase = ph + TAU * f / MIX_RATE
			v.t += 1.0 / MIX_RATE
		s = clampf(s * gain, -1.0, 1.0)
		_pb.push_frame(Vector2(s, s))
	# Reap finished voices.
	var alive: Array = []
	for v in _voices:
		if v.t < v.dur:
			alive.append(v)
	_voices = alive

var _mute_latch := false


# --- Voice spawning ---------------------------------------------------------
func _tone(freq: float, dur: float, vol: float, type: int = 0, sweep: float = 0.0) -> void:
	if _voices.size() > 24:
		return
	_voices.append({freq = freq, phase = 0.0, t = 0.0, dur = dur, type = type, vol = vol, sweep = sweep})

func _pad(freq: float, dur: float, vol: float) -> void:
	_tone(freq, dur, vol, 0)
	_tone(freq * 2.0, dur, vol * 0.3, 0)


# --- Named SFX --------------------------------------------------------------
func ui() -> void:            _tone(660, 0.08, 0.25, 1)
func ui_back() -> void:       _tone(330, 0.09, 0.22, 1)
func step() -> void:          _tone(90 + randf() * 30.0, 0.05, 0.12, 3)
func dash() -> void:          _tone(220, 0.18, 0.2, 2, 600.0)
func hit() -> void:           _tone(140, 0.15, 0.28, 3, -200.0)
func hurt() -> void:          _tone(200, 0.25, 0.3, 1, -300.0)
func wall_confirm() -> void:
	_tone(660, 0.12, 0.16, 0)
	_tone(990, 0.12, 0.1, 0, 0.0)
func reveal() -> void:
	_tone(880, 0.5, 0.18, 0, -200.0)
	_tone(1320, 0.4, 0.12, 0, 300.0)
func illusion_break() -> void:
	_tone(520, 0.4, 0.22, 3, -400.0)
	_tone(1040, 0.3, 0.14, 0, 600.0)
func shard() -> void:
	_tone(784, 0.15, 0.24, 0)
	_tone(1047, 0.18, 0.22, 0)
	_tone(1568, 0.35, 0.2, 0)
func portal() -> void:
	_tone(392, 0.6, 0.2, 2, 400.0)
func enemy_speak() -> void:   _tone(160, 0.1, 0.14, 1)
func win() -> void:
	for i in 4:
		var f: float = [523.0, 659.0, 784.0, 1047.0][i]
		_voices.append({freq = f, phase = 0.0, t = -i * 0.16, dur = 0.6, type = 0, vol = 0.2, sweep = 0.0})


# --- Music / mood -----------------------------------------------------------
func set_mood(root: float, fifth: float) -> void:
	_pad_root = root
	_pad_fifth = fifth

func toggle_mute() -> void:
	_muted = not _muted
	_mute_latch = true

func is_muted() -> bool:
	return _muted
