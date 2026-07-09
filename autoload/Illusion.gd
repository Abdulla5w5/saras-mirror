extends Node
## Sara's TRUE SIGHT — the one thread that ties every dream-world to the jam
## theme (Illusion). A short-cooldown pulse briefly reveals what is real vs.
## illusory around her: fake walls flicker and turn passable, hidden real paths
## and shards fade in, disguised traps expose themselves.
##
## Objects opt in by joining the "illusion" group and implementing
## reveal(duration). Illusion finds those within RADIUS of the pulse origin,
## reveals them, and owns cooldown/duration plus the vignette + sting feel.

signal pulse_started(origin: Vector2, radius: float, duration: float)
signal pulse_ended()
signal cooldown_changed(remaining: float, total: float)

const RADIUS := 340.0
const DURATION := 3.5
const COOLDOWN := 3.0

var _active := false
var _cooldown_left := 0.0
var _duration_left := 0.0


func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)
		cooldown_changed.emit(_cooldown_left, COOLDOWN)
	if _active:
		_duration_left -= delta
		if _duration_left <= 0.0:
			_end()

func can_activate() -> bool:
	return _cooldown_left <= 0.0 and not _active

func is_active() -> bool:
	return _active

func cooldown_ratio() -> float:
	return 1.0 - (_cooldown_left / COOLDOWN) if COOLDOWN > 0.0 else 1.0

func activate(origin: Vector2) -> bool:
	if not can_activate():
		return false
	_active = true
	_duration_left = DURATION
	_cooldown_left = COOLDOWN

	Audio.reveal()
	FX.set_true_sight_vignette(true)
	FX.add_trauma(0.14)
	FX.flash(Color(0.55, 0.8, 1.0), 0.22)
	FX.reveal_pulse(origin, RADIUS)

	for obj in get_tree().get_nodes_in_group("illusion"):
		if obj is Node2D and obj.has_method("reveal"):
			if obj.global_position.distance_to(origin) <= RADIUS:
				obj.reveal(DURATION)
	pulse_started.emit(origin, RADIUS, DURATION)
	return true

func _end() -> void:
	_active = false
	_duration_left = 0.0
	FX.set_true_sight_vignette(false)
	pulse_ended.emit()
