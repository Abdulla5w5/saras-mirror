extends LevelBase
## LEVEL 2 — The Cursed Forest (Shadow world). The hall's back door opens onto a
## bleeding treeline. A wall of illusion hedges seals the grove — one gap is
## real. Between Sara and the hedges, a roaming blade of cold light sweeps the
## clearing (you must time the gap to cross), with quicksand pockets on the
## flanks. Two vampire nightmares guard the shard.

func _ready() -> void:
	level_id = &"cursed_forest"
	bounds = Rect2(-650, -525, 1300, 1050)
	player_start = Vector2(0, 460)
	super._ready()


func build() -> void:
	spawn_ground(Vector2(1300, 1050))
	_scatter_trees()
	scatter_props("res://assets/props/cursed/",
		["Rock1_shadow1_1.png", "Ruins_shadow2_1.png", "Bones_shadow1_1.png", "Rock2_shadow2_1.png"],
		10, 7, 470, 610, 480, 0.7, 1.1)
	scatter_props("res://assets/props/cursed/",
		["Eye_plant_shadow1_1.png", "Tentacle_plant_shadow1_1.png", "Meat_flower_shadow1_1.png", "Many_eyes_plant_shadow1_1.png", "Veins_shadow1_1.png"],
		12, 19, 300, 600, 490, 0.7, 1.2)

	spawn_boundary(Vector2(-650, 0), Vector2(40, 1050))
	spawn_boundary(Vector2(650, 0), Vector2(40, 1050))
	spawn_boundary(Vector2(0, -545), Vector2(1300, 40))

	spawn_sign(Vector2(-250, 470), [
		["Sara", "A frog. Wearing a crown. It won't let me past without a game."],
	], "!")

	# STAGE 1: a frog blocks the path — beat it at Connect Four to open the gate.
	spawn_frog_gate(430.0, 0.0, 240.0)

	# STAGE 2: a snake-infested swamp — lay the ladder, walk over the snakes.
	spawn_swamp_crossing(Vector2(0, 70), 1180.0, 220.0)

	# THE GATE: four hedge panels, only #2 is the true gap.
	spawn_gate_line(-40, 0, 420, 4, 2, Color(0.85, 0.3, 0.3))


	spawn_enemy(Vector2(-180, -280), {
		sheet_dir = "res://assets/enemies/countess/",
		speaker = "The Countess",
		aggro_lines = ["Lost little dreamer. Stay and keep me company forever."],
		defeat_lines = ["...the grove... will grow back..."],
		max_hp = 4, move_speed = 115.0, aggro_range = 300.0,
		tint = Color(1.0, 0.75, 0.8),
	})
	spawn_enemy(Vector2(200, -320), {
		sheet_dir = "res://assets/enemies/vampire_girl/",
		speaker = "The Thorned Girl",
		aggro_lines = ["You smell like the waking world. I hate that smell."],
		defeat_lines = ["...run, then..."],
		max_hp = 3, move_speed = 150.0, aggro_range = 260.0,
		tint = Color(0.8, 1.0, 0.85),
	})

	var shard := spawn_shard(Vector2(0, -400), Color(0.85, 0.3, 0.3))
	var portal := spawn_portal(Vector2(0, -480), Color(0.85, 0.3, 0.3))
	register_shard(shard, portal)


func _scatter_trees() -> void:
	var dir := "res://assets/trees/"
	var names := ["birch_2.png", "birch_3.png", "fir_tree_6.png", "fir_tree_7.png", "middle_lane_tree11.png"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 26:
		var tex := SpriteSheet.load_tex(dir + names[i % names.size()])
		if tex == null:
			continue
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * rng.randf_range(480, 630)
		var y := rng.randf_range(-500, 500)
		var s := Sprite2D.new()
		s.texture = tex
		var sc := rng.randf_range(0.55, 0.85)
		s.scale = Vector2(sc, sc)
		s.position = Vector2(x, y)
		s.offset = Vector2(0, -tex.get_height() * 0.5)
		s.z_index = int(y)
		add_child(s)
