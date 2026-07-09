extends Node
## Minimal progress persistence: which dream-worlds have had their shard claimed,
## so the menu can offer Continue. ConfigFile under user:// (survives export).

const SAVE_PATH := "user://saras_mirror.cfg"

var _data := ConfigFile.new()


func _ready() -> void:
	load_file()

func load_file() -> void:
	if _data.load(SAVE_PATH) != OK:
		_data = ConfigFile.new()

func mark_cleared(id: StringName) -> void:
	_data.set_value("shards", String(id), true)
	_data.set_value("meta", "last", String(id))
	_data.save(SAVE_PATH)

func is_cleared(id: StringName) -> bool:
	return _data.get_value("shards", String(id), false)

func has_progress() -> bool:
	return _data.has_section("shards") and not _data.get_section_keys("shards").is_empty()

func reset() -> void:
	_data = ConfigFile.new()
	_data.save(SAVE_PATH)
