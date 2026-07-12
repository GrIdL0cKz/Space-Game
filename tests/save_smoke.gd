extends Node2D
## Headless smoke: the save system round-trips, the item DB is coherent,
## and every text every item references actually exists.

func _ready() -> void:
	var failures: Array[String] = []
	# --- items reference real texts
	for id in Items.DB:
		var def: Dictionary = Items.DB[id]
		if String(def.get("kind", "")) == "read":
			var tid := String(def.get("text_id", ""))
			if not Texts.DB.has(tid):
				failures.append("item %s references missing text %s" % [id, tid])
	# --- state snapshot round-trip
	GameState.reset()
	GameState.add_item("wrench", 1, true)
	GameState.add_item("fuse", 3, true)
	GameState.set_equipped("suit_torso", true)
	GameState.set_flag("powered_lab", true)
	GameState.deaths = 2
	var snap := GameState.snapshot()
	GameState.reset()
	if GameState.has_item("wrench"):
		failures.append("reset did not clear inventory")
	GameState.restore(snap)
	if not GameState.has_item("fuse", 3):
		failures.append("restore lost fuses")
	if not GameState.is_equipped("suit_torso"):
		failures.append("restore lost suit")
	if not bool(GameState.get_flag("powered_lab")):
		failures.append("restore lost flags")
	if GameState.deaths != 2:
		failures.append("restore lost death count")
	# --- save file round-trip through disk (needs a live player to record)
	var p := preload("res://actors/entities/player.tscn").instantiate()
	p.global_position = Vector2(123, 456)
	add_child(p)
	SaveManager.save_game("smoke test save")
	var found := false
	for s in SaveManager.list_saves():
		if String(s.get("label", "")) == "smoke test save":
			found = true
			var st: Dictionary = s.get("state", {})
			if int(st.get("deaths", -1)) != 2:
				failures.append("disk save lost death count")
	if not found:
		failures.append("labelled save not listed after save_game")
	SaveManager.delete_save("smoke_test_save")
	# --- report
	if failures.is_empty():
		print("save smoke test passed")
	else:
		for f in failures:
			print("FAIL: " + f)
	get_tree().quit(0 if failures.is_empty() else 1)
