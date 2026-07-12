extends Node
## The run's living memory: inventory, equipped suit pieces, world flags,
## death count, playtime. Everything here round-trips through SaveManager.
## Scenes read flags; interactables set them; nobody stores world truth
## anywhere else.

signal inventory_changed
signal flags_changed
signal suit_changed

# item_id -> count
var inventory: Dictionary = {}
# suit pieces currently worn
var equipped: Dictionary = {"suit_torso": false, "suit_helmet": false}
# world flags: what's fixed, read, opened, powered. Power routing writes
# "powered_lab" / "powered_viewing" / "powered_fighter" booleans here.
var flags: Dictionary = {}
var deaths: int = 0
var playtime: float = 0.0

func _process(delta: float) -> void:
	playtime += delta

# ---------------------------------------------------------------- inventory

func add_item(id: String, count: int = 1, quiet: bool = false) -> void:
	inventory[id] = int(inventory.get(id, 0)) + count
	inventory_changed.emit()
	if not quiet:
		Hud.toast("Picked up: %s" % Items.display_name(id))
		Sd.play(&"pickup")

func remove_item(id: String, count: int = 1) -> bool:
	if int(inventory.get(id, 0)) < count:
		return false
	inventory[id] = int(inventory[id]) - count
	if int(inventory[id]) <= 0:
		inventory.erase(id)
	inventory_changed.emit()
	return true

func has_item(id: String, count: int = 1) -> bool:
	return int(inventory.get(id, 0)) >= count

# ---------------------------------------------------------------- suit

func set_equipped(piece: String, worn: bool) -> void:
	if equipped.has(piece):
		equipped[piece] = worn
		suit_changed.emit()

func is_equipped(piece: String) -> bool:
	return bool(equipped.get(piece, false))

func eva_safe() -> bool:
	return is_equipped("suit_torso") and is_equipped("suit_helmet")

# ---------------------------------------------------------------- flags

func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value
	flags_changed.emit()

func get_flag(key: String, default: Variant = false) -> Variant:
	return flags.get(key, default)

# ---------------------------------------------------------------- snapshot

func snapshot() -> Dictionary:
	return {
		"inventory": inventory.duplicate(),
		"equipped": equipped.duplicate(),
		"flags": flags.duplicate(),
		"deaths": deaths,
		"playtime": playtime,
	}

func restore(data: Dictionary) -> void:
	inventory = data.get("inventory", {}).duplicate()
	equipped = data.get("equipped", {"suit_torso": false, "suit_helmet": false}).duplicate()
	flags = data.get("flags", {}).duplicate()
	deaths = int(data.get("deaths", 0))
	playtime = float(data.get("playtime", 0.0))
	inventory_changed.emit()
	flags_changed.emit()
	suit_changed.emit()

func reset() -> void:
	restore({})
