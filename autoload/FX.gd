extends Node
## Screen + world juice (2D): trauma-based camera shake, screen flash, hit-pause,
## the True-Sight vignette pulse, and one-shot particle bursts that need no assets.
##
## Camera shake uses a trauma model: add trauma on events, it decays, and the
## active Camera2D polls get_shake_offset()/get_shake_roll() every frame — FX
## never needs a direct camera reference.

const MAX_OFFSET := Vector2(18.0, 18.0)  # pixels
const MAX_ROLL := 0.05                    # radians
const TRAUMA_DECAY := 1.5                 # per second

var _trauma := 0.0
var _t := 0.0

var _layer: CanvasLayer
var _flash: ColorRect
var _vignette: ColorRect
var _vignette_active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 90
	add_child(_layer)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_flash)

	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.material = _make_vignette_material()
	_vignette.visible = false
	_layer.add_child(_vignette)


func _process(delta: float) -> void:
	_t += delta
	if _trauma > 0.0:
		_trauma = maxf(_trauma - TRAUMA_DECAY * delta, 0.0)
	if _vignette_active and _vignette.material:
		var pulse: float = 0.4 + 0.25 * sin(_t * 6.0)
		_vignette.material.set_shader_parameter("intensity", pulse)


# --- Camera shake -----------------------------------------------------------
func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func get_shake_offset() -> Vector2:
	var s := _trauma * _trauma
	return Vector2(MAX_OFFSET.x * s * _noise(0), MAX_OFFSET.y * s * _noise(1))

func get_shake_roll() -> float:
	return MAX_ROLL * _trauma * _trauma * _noise(2)

func _noise(o: int) -> float:
	return sin(_t * 47.0 + o * 12.9898) * cos(_t * 31.0 - o * 4.1)


# --- Flash / hit-pause ------------------------------------------------------
func flash(color: Color, duration := 0.2) -> void:
	_flash.color = Color(color.r, color.g, color.b, 0.0)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.45, duration * 0.25)
	tw.tween_property(_flash, "color:a", 0.0, duration * 0.75)

func hit_pause(duration := 0.07, scale := 0.05) -> void:
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


# --- True-Sight vignette -----------------------------------------------------
func set_true_sight_vignette(active: bool) -> void:
	_vignette_active = active
	_vignette.visible = active


# --- Procedural particle bursts (no imported assets) ------------------------
func burst(world_pos: Vector2, color := Color(0.8, 0.7, 0.5), amount := 12, speed := 90.0) -> void:
	var host := get_tree().current_scene
	if host == null:
		return
	var p := GPUParticles2D.new()
	p.amount = amount
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 0.95
	p.global_position = world_pos
	p.z_index = 50
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.gravity = Vector3(0, 220, 0)
	mat.initial_velocity_min = speed * 0.4
	mat.initial_velocity_max = speed
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.color = color
	p.process_material = mat
	host.add_child(p)
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.3).timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free())

## A True-Sight shockwave: an expanding ring that sweeps out to `radius`,
## making the reveal feel like a real pulse of insight (the game's core verb).
func reveal_pulse(world_pos: Vector2, radius := 340.0) -> void:
	var host := get_tree().current_scene
	if host == null:
		return
	var ring := Line2D.new()
	ring.width = 7.0
	ring.default_color = Color(0.6, 0.9, 1.0, 0.9)
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	var pts := PackedVector2Array()
	for i in 41:
		var a := TAU * i / 40.0
		pts.append(Vector2(cos(a), sin(a)) * 40.0)
	ring.points = pts
	ring.global_position = world_pos
	ring.z_index = 60
	host.add_child(ring)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector2.ONE * (radius / 40.0), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "modulate:a", 0.0, 0.5)
	tw.tween_property(ring, "width", 2.0, 0.5)
	tw.chain().tween_callback(ring.queue_free)

func illusion_break(world_pos: Vector2, color := Color(0.6, 0.85, 1.0)) -> void:
	burst(world_pos, color, 26, 160.0)
	add_trauma(0.28)
	flash(color * 0.55, 0.16)
	Audio.illusion_break()


func _make_vignette_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\n" + \
		"uniform float intensity : hint_range(0.0, 1.0) = 0.4;\n" + \
		"uniform vec4 tint : source_color = vec4(0.4, 0.6, 1.0, 1.0);\n" + \
		"void fragment() {\n" + \
		"    vec2 uv = SCREEN_UV - vec2(0.5);\n" + \
		"    float d = length(uv) * 1.4;\n" + \
		"    float v = smoothstep(0.3, 0.95, d) * intensity;\n" + \
		"    COLOR = vec4(tint.rgb, v);\n" + \
		"}\n"
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("intensity", 0.4)
	return m
