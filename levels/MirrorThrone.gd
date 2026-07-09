extends LevelBase
## LEVEL 4 — The Mirror Throne (Reflection world). Every trick at once: a gauntlet
## of two phase-gates you must time through, a mirror-panel gate to read with
## True Sight, then the Warden of Glass — wearing Sara's own face. The last shard
## is locked behind a slid mirror-panel; pull the align-lever to move it aside.

func _ready() -> void:
	level_id = &"mirror_throne"
	bounds = Rect2(-600, -640, 1200, 1240)
	player_start = Vector2(0, 500)
	super._ready()


func build() -> void:
	spawn_ground(Vector2(1200, 1240))

	spawn_boundary(Vector2(-600, 0), Vector2(40, 1240))
	spawn_boundary(Vector2(600, 0), Vector2(40, 1240))
	spawn_boundary(Vector2(0, -660), Vector2(1200, 40))
	# mirror-hall decoration along the walls
	for my in [-360, -80, 200, 480]:
		spawn_decor_mirror(Vector2(-560, my), 0.4)
		spawn_decor_mirror(Vector2(560, my), 0.4)
	scatter_props("res://assets/props/cursed/",
		["Veins_shadow2_1.png", "Many_eyes_plant_shadow2_1.png", "Ruins_shadow2_1.png"],
		8, 5, 460, 560, 560, 0.6, 1.0, Color(0.8, 0.7, 1.0))

	spawn_sign(Vector2(-250, 470), [
		["Sara", "One shard left. The floor here is a lie — Q shows the safe steps."],
	], "!")

	# ILLUSION FLOOR: hidden spike tiles the player must read with True Sight and
	# weave between the gaps. Replaces the old crumbling bridge.
	for tx in [-320, -160, 0, 160, 320]:
		spawn_trap(Vector2(tx, 380), Vector2(96, 96))
	for tx in [-240, -80, 80, 240]:
		spawn_trap(Vector2(tx, 250), Vector2(96, 96))
	spawn_trap(Vector2(360, 250), Vector2(150, 90))

	# PHASE-GATE GAUNTLET: two horizontal light-walls with different rhythms.
	_phase_neck(210, 160, 1.7, 1.3, 0.0)
	_phase_neck(70, 160, 1.5, 1.5, 1.4)

	# MIRROR-PANEL GATE: two panels, only the right is a true gap.
	spawn_gate_line(-70, 0, 300, 2, 1, Color(0.72, 0.78, 1.0))

	# The Warden of Glass — the final nightmare.
	spawn_enemy(Vector2(0, -320), {
		sheet_dir = "res://assets/enemies/countess/",
		speaker = "The Warden of Glass",
		aggro_lines = [
			"I have worn your face since you were small enough to believe in me.",
			"Stay. Be the reflection. It is so much easier than being real.",
		],
		defeat_lines = [
			"...you were always going to choose the door...",
			"...go, then. Wake up.",
		],
		max_hp = 7, move_speed = 145.0, aggro_range = 340.0, give_up_range = 800.0,
		tint = Color(0.85, 0.88, 1.0),
	})

	# FINAL PUZZLE: the shard is sealed AND locked until the lever is pulled.
	var shard := spawn_shard(Vector2(0, -470), Color(0.72, 0.78, 1.0))
	shard.locked = true
	var portal := spawn_portal(Vector2(0, -560), Color(0.72, 0.78, 1.0))
	register_shard(shard, portal)

	var lock := spawn_slidewall(Vector2(0, -430), Vector2(200, 90), Vector2(-260, 0), Color(0.72, 0.78, 1.0))
	spawn_lever(Vector2(250, -380), [lock, shard], true)   # lever slides the wall AND unlocks the shard
	spawn_sign(Vector2(-250, -380), [
		["Sara", "The shard's sealed. Pull the lever to slide the glass aside."],
	], "?")


## A horizontal light-wall filling a central gap of `gap_w`, funnels to the sides.
func _phase_neck(line_y: float, gap_w: float, solid: float, open: float, off: float) -> void:
	var left := bounds.position.x
	var right := bounds.position.x + bounds.size.x
	var gl := -gap_w * 0.5
	var gr := gap_w * 0.5
	spawn_boundary(Vector2((left + gl) * 0.5, line_y), Vector2(gl - left, 60))
	spawn_boundary(Vector2((gr + right) * 0.5, line_y), Vector2(right - gr, 60))
	spawn_phase_gate(Vector2(0, line_y), Vector2(gap_w, 46), solid, open, off)
