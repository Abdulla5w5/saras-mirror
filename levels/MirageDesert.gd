extends LevelBase
## LEVEL 3 — The Mirage (Mirage world). An endless dune under a frozen sky. The
## signature obstacle: a long bridge of crumbling mirage-tiles is the only span
## across the sinking sands — stop moving and it drops you. A quicksand belt and
## a hidden spike flank it, and a wall of mirage-cliffs (one a true gap) seals
## the far side.

func _ready() -> void:
	level_id = &"mirage_desert"
	bounds = Rect2(-680, -600, 1360, 1200)
	player_start = Vector2(0, 480)
	super._ready()


func build() -> void:
	spawn_ground(Vector2(1360, 1200))
	# sparse sun-bleached rocks along the margins (desert-appropriate, unlike the
	# old random tileset scatter)
	scatter_props("res://assets/props/cursed/",
		["Rock1_shadow1_1.png", "Rock2_shadow2_1.png", "Rock3_shadow1_2.png"],
		9, 11, 500, 640, 540, 0.8, 1.4, Color(0.95, 0.85, 0.62))

	spawn_boundary(Vector2(-680, 0), Vector2(40, 1200))
	spawn_boundary(Vector2(680, 0), Vector2(40, 1200))
	spawn_boundary(Vector2(0, -620), Vector2(1360, 40))

	spawn_sign(Vector2(-360, 400), [
		["Sara", "A sea of sinking sand. I'll need the ladder to bridge it."],
	], "!")

	# THE CROSSING (signature): a vast belt of sinking mirror-sand fills the
	# valley. There is no running across it — reveal the winding shard-path with
	# True Sight and step it, or the sands take you. Deep enough that brute force
	# is fatal.
	spawn_shard_crossing(Vector2(0, 190), 1300.0, 320.0, 8)

	# THE GATE: three mirage-cliffs, only the centre is a true gap.
	spawn_gate_line(-40, 0, 320, 3, 1, Color(0.95, 0.85, 0.55))


	spawn_enemy(Vector2(-160, -320), {
		sheet_dir = "res://assets/enemies/countess/",
		speaker = "The Mirage",
		aggro_lines = ["Drink. Rest. Stay. There is no forest, no hall, no home."],
		defeat_lines = ["...the sand remembers nothing..."],
		max_hp = 4, move_speed = 125.0, aggro_range = 300.0,
		tint = Color(1.0, 0.9, 0.6),
	})
	spawn_enemy(Vector2(180, -360), {
		sheet_dir = "res://assets/enemies/vampire_girl/",
		speaker = "The Heat-Shade",
		aggro_lines = ["Every step forward is a step back out here."],
		defeat_lines = ["...it was never real ground anyway..."],
		max_hp = 3, move_speed = 150.0, aggro_range = 260.0,
		tint = Color(1.0, 0.8, 0.5),
	})

	var shard := spawn_shard(Vector2(0, -440), Color(0.95, 0.85, 0.55))
	var portal := spawn_portal(Vector2(0, -520), Color(0.95, 0.85, 0.55))
	register_shard(shard, portal)
