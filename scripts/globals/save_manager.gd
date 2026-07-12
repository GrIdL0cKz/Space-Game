extends Node
## Unlimited labelled saves, JSON files under user://saves/. A save carries
## the label, the scene, the player's position, and the whole GameState
## snapshot. "checkpoint" is a reserved slot written silently before
## known-lethal choices, so comedy deaths never cost real progress.

const SAVE_DIR := "user://saves"
const CHECKPOINT := "checkpoint"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _slug(label: String) -> String:
	var s := label.strip_edges().to_lower()
	var out := ""
	for ch in s:
		out += ch if (ch.is_valid_identifier() or ch.is_valid_int()) else "_"
	return out.substr(0, 40) if out != "" else "save"

func _path(slug: String) -> String:
	return "%s/%s.json" % [SAVE_DIR, slug]

# ---------------------------------------------------------------- write

func save_game(label: String) -> bool:
	var player := get_tree().get_first_node_in_group("player")
	var scene := get_tree().current_scene
	if player == null or scene == null:
		return false
	var data := {
		"label": label,
		"time": Time.get_datetime_string_from_system(false, true),
		"scene": String(scene.scene_file_path),
		"player_pos": [player.global_position.x, player.global_position.y],
		"state": GameState.snapshot(),
	}
	var f := FileAccess.open(_path(_slug(label)), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	return true

func write_checkpoint() -> void:
	save_game(CHECKPOINT)

# ---------------------------------------------------------------- read

func list_saves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return out
	for file in dir.get_files():
		if not file.ends_with(".json"):
			continue
		var f := FileAccess.open("%s/%s" % [SAVE_DIR, file], FileAccess.READ)
		if f == null:
			continue
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if parsed is Dictionary:
			parsed["slug"] = file.trim_suffix(".json")
			out.append(parsed)
	out.sort_custom(func(a, b): return String(a.get("time", "")) > String(b.get("time", "")))
	return out

func has_checkpoint() -> bool:
	return FileAccess.file_exists(_path(CHECKPOINT))

func load_game(slug: String) -> bool:
	var f := FileAccess.open(_path(slug), FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return false
	var data: Dictionary = parsed
	GameState.restore(data.get("state", {}))
	_pending_pos = data.get("player_pos", [])
	get_tree().paused = false
	get_tree().change_scene_to_file(String(data.get("scene", "res://scenes/craft_world.tscn")))
	return true

func delete_save(slug: String) -> void:
	if slug == "":
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_path(slug)))

# The loaded scene asks for this in _ready to place the player.
var _pending_pos: Array = []

func consume_pending_position() -> Variant:
	if _pending_pos.size() == 2:
		var p := Vector2(float(_pending_pos[0]), float(_pending_pos[1]))
		_pending_pos = []
		return p
	return null
