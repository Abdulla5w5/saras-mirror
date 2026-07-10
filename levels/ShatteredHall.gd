extends LevelBase
## LEVEL 1 — The Shattered Hall. Sara's cracked bedroom mirror swallowed her;
## she lands in a warped reflection of her own house. Tutorial: the room is
## sealed by a wall of mirror panels — only one is a passable illusion, and True
## Sight is the only way to tell which. First taste of crumbling floor and
## quicksand on the approach, and the first nightmare guards the shard.

func _ready() -> void:
	level_id = &"shattered_hall"
	bounds = Rect2(-560, -500, 1120, 1000)
	player_start = Vector2(0, 420)
	super._ready()
	show_toast("WASD move  ·  Q True Sight reveals illusions  ·  E interact  ·  J strike")


func build() -> void:
	spawn_ground(Vector2(1120, 1000))
	# Worn-floor richness: cracks/pebbles strewn across the ground, plus glinting
	# mirror shards that give the Shattered Hall its broken-glass identity.
	scatter_floor_decals(SpriteSheet.load_tex("res://assets/ground/details.png"),
		[Rect2(4, 4, 26, 26), Rect2(30, 40, 42, 30), Rect2(70, 94, 30, 28),
		Rect2(116, 116, 44, 22), Rect2(94, 96, 26, 26), Rect2(8, 52, 34, 34)],
		28, 1011, Color(0.55, 0.8, 1.0, 0.32))
	scatter_mirror_shards(20, 2022, _mood.accent)

	# Outer boundary.
	spawn_boundary(Vector2(-560, -60), Vector2(40, 1000))
	spawn_boundary(Vector2(560, -60), Vector2(40, 1000))
	spawn_boundary(Vector2(0, -520), Vector2(1120, 40))
	# hall of mirrors — hung on the far (north) wall, clear of the gates
	for mx in [-380, 380]:
		spawn_decor_mirror(Vector2(mx, -470), 0.42)

	spawn_sign(Vector2(-250, 360), [
		["Sara", "The mirror pulled me in. This isn't my room."],
		["Sara", "Q reveals what's real. E works the locked dial."],
	], "!")

	# Locked combination gate (E to work the dial; four clicks opens it).
	spawn_code_gate(220.0, 0.0, 220.0, [3, 7, 1, 9], Color(0.5, 0.85, 1.0))

	# THE GATE: five panels seal the hall; only panel #1 (from the left) is fake.
	spawn_gate_line(-20, 0, 360, 5, 1, Color(0.5, 0.65, 1.0))

	# North chamber: the first nightmare, the shard, and the way onward.
	spawn_enemy(Vector2(80, -300), {
		sheet_dir = "res://assets/enemies/vampire_girl/",
		speaker = "The Reflection",
		aggro_lines = [
			"You should not have come looking for pieces of yourself.",
			"Every girl who stares too long falls in eventually.",
		],
		defeat_lines = ["...if I am not real... then neither are you..."],
		max_hp = 3, move_speed = 135.0, aggro_range = 300.0,
		tint = Color(0.85, 0.8, 1.0),
	})

	var shard := spawn_shard(Vector2(0, -380), Color(0.7, 0.85, 1.0))
	var portal := spawn_portal(Vector2(0, -460), Color(0.7, 0.85, 1.0))
	register_shard(shard, portal)
