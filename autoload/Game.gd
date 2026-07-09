extends Node
## Global game state + level flow for Sara's Mirror.
##
## Sara is pulled into her cracked bedroom mirror. To wake, she must reclaim one
## MIRROR SHARD from each of four dream-worlds, then step back through the mirror.
## change_scene_to_packed frees the previous level automatically, so only the
## current dream is resident in memory at a time.

signal level_changed(level_id: StringName)
signal shard_collected(level_id: StringName, total: int)
signal player_respawned(pos: Vector2)

## The four dream-worlds, in order. Each maps to a scene under res://levels/.
const LEVELS := {
	&"shattered_hall": "res://levels/ShatteredHall.tscn",
	&"cursed_forest":  "res://levels/CursedForest.tscn",
	&"mirage_desert":  "res://levels/MirageDesert.tscn",
	&"mirror_throne":  "res://levels/MirrorThrone.tscn",
}
const ORDER: Array[StringName] = [
	&"shattered_hall", &"cursed_forest", &"mirage_desert", &"mirror_throne",
]
## Human-readable titles shown on the level-intro card and HUD.
const TITLES := {
	&"shattered_hall": "The Shattered Hall",
	&"cursed_forest":  "The Cursed Forest",
	&"mirage_desert":  "The Mirage",
	&"mirror_throne":  "The Mirror Throne",
}

var current_level: StringName = &""
var player_hp := 5                   # persists across levels (see Player)
var shards: Dictionary = {}          # level_id -> true
var checkpoint: Vector2 = Vector2.ZERO
var _player: Node = null
var _loading := false


func level_title(id: StringName) -> String:
	return TITLES.get(id, "A Dream")

func shard_count() -> int:
	return shards.size()

func has_shard(id: StringName) -> bool:
	return shards.has(id)


# --- Player registration ----------------------------------------------------
func register_player(p: Node) -> void:
	_player = p

func get_player() -> Node:
	return _player if is_instance_valid(_player) else null

func set_checkpoint(pos: Vector2) -> void:
	checkpoint = pos

func respawn_player() -> void:
	var p := get_player()
	if p == null:
		return
	if p.has_method("teleport_to"):
		p.teleport_to(checkpoint)
	player_respawned.emit(checkpoint)
	FX.flash(Color(0.6, 0.8, 1.0), 0.3)


# --- Flow -------------------------------------------------------------------
func start_new_game() -> void:
	player_hp = 5
	shards.clear()
	SaveManager.reset()
	goto_level(ORDER[0])

func continue_game() -> void:
	# Drop the player into the first not-yet-cleared dream.
	for id in ORDER:
		if not SaveManager.is_cleared(id):
			goto_level(id)
			return
	goto_level(ORDER[0])

func goto_level(id: StringName) -> void:
	if _loading or not LEVELS.has(id):
		return
	_loading = true
	current_level = id
	var path: String = LEVELS[id]
	ResourceLoader.load_threaded_request(path)
	while true:
		var st := ResourceLoader.load_threaded_get_status(path)
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Failed to load level: %s" % path)
			_loading = false
			return
		await get_tree().process_frame
	var packed: PackedScene = ResourceLoader.load_threaded_get(path)
	get_tree().change_scene_to_packed(packed)
	_loading = false
	level_changed.emit(id)

func collect_shard(id: StringName) -> void:
	if shards.has(id):
		return
	shards[id] = true
	SaveManager.mark_cleared(id)
	shard_collected.emit(id, shards.size())

func advance_level() -> void:
	var i := ORDER.find(current_level)
	if i == -1 or i + 1 >= ORDER.size():
		get_tree().change_scene_to_file("res://ui/WinScreen.tscn")
	else:
		goto_level(ORDER[i + 1])

func reload_level() -> void:
	if current_level != &"":
		goto_level(current_level)

func quit_to_menu() -> void:
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
