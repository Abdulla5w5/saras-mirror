class_name World
extends RefCounted
## Per-dream palettes + a procedural ground material, so each world reads as a
## distinct illusion without hand-painted floor tiles. The ground shader is fbm
## noise blended across three palette colours with an optional slow shimmer
## (used to make the dream feel like it's breathing).

## mood keys: clear, ground_a, ground_b, ground_c, accent, shimmer, pad_root, pad_fifth
const MOODS := {
	# Vibrant, jewel-toned dream palettes — illusion is magical, not depressing.
	&"shattered_hall": {
		clear = Color(0.10, 0.08, 0.22),
		ground_a = Color(0.24, 0.16, 0.52), ground_b = Color(0.36, 0.24, 0.72),
		ground_c = Color(0.22, 0.58, 0.82), accent = Color(0.50, 0.95, 1.0),
		shimmer = 1.2, pad_root = 110.0, pad_fifth = 164.81,
	},
	&"cursed_forest": {
		clear = Color(0.05, 0.16, 0.13),
		ground_a = Color(0.10, 0.36, 0.26), ground_b = Color(0.16, 0.54, 0.32),
		ground_c = Color(0.58, 0.74, 0.22), accent = Color(0.55, 1.0, 0.55),
		shimmer = 0.7, pad_root = 98.0, pad_fifth = 146.83,
	},
	&"mirage_desert": {
		clear = Color(0.60, 0.72, 0.90),                                # warm daylight sky
		ground_a = Color(0.88, 0.66, 0.34), ground_b = Color(0.96, 0.80, 0.44),
		ground_c = Color(1.0, 0.92, 0.62), accent = Color(1.0, 0.85, 0.45),
		shimmer = 2.0, vignette = 0.28, pad_root = 130.81, pad_fifth = 196.0,
	},
	&"mirror_throne": {
		clear = Color(0.12, 0.06, 0.20),
		ground_a = Color(0.28, 0.12, 0.42), ground_b = Color(0.46, 0.18, 0.60),
		ground_c = Color(0.66, 0.32, 0.70), accent = Color(1.0, 0.82, 0.45),
		shimmer = 1.5, pad_root = 82.41, pad_fifth = 123.47,
	},
}

const GROUND_SHADER := "shader_type canvas_item;\n\
uniform vec4 col_a : source_color;\n\
uniform vec4 col_b : source_color;\n\
uniform vec4 col_c : source_color;\n\
uniform vec4 accent : source_color;\n\
uniform float tiling = 6.0;\n\
uniform float shimmer = 0.0;\n\
float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453); }\n\
float vnoise(vec2 p){ vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);\n\
	float a=hash(i), b=hash(i+vec2(1.0,0.0)), c=hash(i+vec2(0.0,1.0)), d=hash(i+vec2(1.0,1.0));\n\
	return mix(mix(a,b,f.x), mix(c,d,f.x), f.y); }\n\
float fbm(vec2 p){ float v=0.0; float a=0.5; for(int i=0;i<5;i++){ v+=a*vnoise(p); p*=2.0; a*=0.5; } return v; }\n\
float ridged(vec2 p){ return 1.0 - abs(fbm(p)*2.0 - 1.0); }\n\
void fragment(){\n\
	vec2 uv = UV * tiling;\n\
	vec2 flow = vec2(0.0, TIME * shimmer * 0.03);\n\
	float n = fbm(uv + flow);\n\
	float n2 = fbm(uv*2.3 + 5.0);\n\
	float big = fbm(uv*0.28 - 2.0);\n\
	// base palette blend with large-scale depth mottling\n\
	vec3 col = mix(col_a.rgb, col_b.rgb, smoothstep(0.25, 0.72, n));\n\
	col = mix(col, col_c.rgb, smoothstep(0.55, 0.95, n2) * 0.6);\n\
	col *= 0.72 + 0.5 * big;\n\
	// dark hairline cracks / veins winding through the ground\n\
	float veins = pow(ridged(uv*1.4 + 7.0), 4.0);\n\
	col = mix(col, col_a.rgb * 0.4, clamp(veins*1.4, 0.0, 0.7));\n\
	// faint accent glints catching the light\n\
	float glint = pow(fbm(uv*3.1 + flow*2.0), 6.0);\n\
	col += accent.rgb * glint * 0.25;\n\
	COLOR = vec4(col, 1.0);\n\
}\n"

const VIGNETTE_SHADER := "shader_type canvas_item;\n\
uniform vec4 tint : source_color = vec4(0.0,0.0,0.0,1.0);\n\
uniform float strength = 0.55;\n\
void fragment(){\n\
	float d = length(SCREEN_UV - vec2(0.5)) * 1.42;\n\
	float v = smoothstep(0.42, 0.98, d) * strength;\n\
	COLOR = vec4(tint.rgb, v);\n\
}\n"

static func mood(level_id: StringName) -> Dictionary:
	return MOODS.get(level_id, MOODS[&"shattered_hall"])

static func make_ground_material(m: Dictionary, tiling: float) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = GROUND_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("col_a", m.ground_a)
	mat.set_shader_parameter("col_b", m.ground_b)
	mat.set_shader_parameter("col_c", m.ground_c)
	mat.set_shader_parameter("accent", m.accent)
	mat.set_shader_parameter("tiling", tiling)
	mat.set_shader_parameter("shimmer", m.shimmer)
	return mat

## A dreamy bloom environment (2D canvas glow) so accent glints, shards, portals
## and the ambient motes softly light up — sells the "illusion" without art.
static func make_environment(_m: Dictionary) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_strength = 1.1
	env.glow_bloom = 0.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_hdr_threshold = 0.95      # only the brightest pixels bloom
	env.glow_hdr_scale = 2.0
	env.set_glow_level(2, 1.0)
	env.set_glow_level(3, 1.0)
	env.set_glow_level(4, 0.5)
	return env

static func make_vignette_material(m: Dictionary, strength := 0.55) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = VIGNETTE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("tint", (m.clear as Color).darkened(0.4))
	mat.set_shader_parameter("strength", strength)
	return mat
