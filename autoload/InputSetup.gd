extends Node
## Registers every input action in code so bindings always exist regardless of
## project.godot's InputMap. Runs first in the autoload order.
##
## Top-down controls (keyboard + a common gamepad layout):
##   move_left/right/up/down  WASD / arrows / left stick
##   interact                 E / gamepad X   (examine, pull levers, read signs)
##   attack                   J / Left-Mouse / gamepad Y  (mirror-shard strike)
##   dash                     Shift / gamepad B
##   true_sight               Q / Right-Mouse / gamepad RB (reveal real vs illusion)
##   pause                    Escape / gamepad Start

func _ready() -> void:
	_action(&"move_left",  [_key(KEY_A), _key(KEY_LEFT)],  [_axis(JOY_AXIS_LEFT_X, -1.0)])
	_action(&"move_right", [_key(KEY_D), _key(KEY_RIGHT)], [_axis(JOY_AXIS_LEFT_X,  1.0)])
	_action(&"move_up",    [_key(KEY_W), _key(KEY_UP)],    [_axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action(&"move_down",  [_key(KEY_S), _key(KEY_DOWN)],  [_axis(JOY_AXIS_LEFT_Y,  1.0)])
	_action(&"interact",   [_key(KEY_E)],                  [_joy(JOY_BUTTON_X)])
	_action(&"attack",     [_key(KEY_J), _mb(MOUSE_BUTTON_LEFT)],  [_joy(JOY_BUTTON_Y)])
	_action(&"dash",       [_key(KEY_SHIFT)],              [_joy(JOY_BUTTON_B)])
	_action(&"true_sight", [_key(KEY_Q), _mb(MOUSE_BUTTON_RIGHT)], [_joy(JOY_BUTTON_RIGHT_SHOULDER)])
	_action(&"pause",      [_key(KEY_ESCAPE)],             [_joy(JOY_BUTTON_START)])


func _action(name: StringName, events: Array, extra: Array = []) -> void:
	if InputMap.has_action(name):
		InputMap.erase_action(name)
	InputMap.add_action(name, 0.5)
	for e in events:
		InputMap.action_add_event(name, e)
	for e in extra:
		InputMap.action_add_event(name, e)


func _key(k: Key) -> InputEventKey:
	var e := InputEventKey.new(); e.physical_keycode = k; return e

func _mb(b: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new(); e.button_index = b; return e

func _joy(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new(); e.button_index = b; return e

func _axis(a: JoyAxis, v: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new(); e.axis = a; e.axis_value = v; return e
