extends RoomBase
## The hangar: double-height, hazard-striped, one small fighter that looks
## like somebody loved it. The breaker board rules the ship's power here.
## Climbing in launches the first-person defence screen - once the bay has
## power and there's a reason to fly.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/fighter_bay.png"
	default_spawn = Vector2(220, STAND_Y)

func _populate() -> void:
	add_door("Corridor", 110, "res://scenes/craft_world.tscn", Vector2(260, 655))
	var seat := FighterSeat.new()
	add_spot(seat, 800, Vector2(560, 220))
	add_spot(Searchable.make("Tool chest", "searched_tool_chest",
			["power_cell", "fuse"],
			"A power cell and a fuse, under a layer of sockets sorted by someone with feelings about sockets."),
			290)
	var breaker := BreakerBoard.new()
	add_spot(breaker, 1630, Vector2(280, 240))
	_make_circuit_lamps()

## Three lamps over the breaker board: which two circuits carry the
## generator right now, readable at a glance from across the bay.
func _make_circuit_lamps() -> void:
	var circuits := [["powered_lab", "LAB"], ["powered_viewing", "VIEW"], ["powered_fighter", "BAY"]]
	var lamps: Array = []
	for i in circuits.size():
		var lamp := ColorRect.new()
		lamp.size = Vector2(26, 16)
		lamp.position = Vector2(1560 + i * 56, 470)
		lamp.z_index = -3
		add_child(lamp)
		var tag := Label.new()
		tag.text = circuits[i][1]
		tag.add_theme_font_size_override("font_size", 11)
		tag.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
		tag.position = Vector2(1558 + i * 56, 488)
		tag.z_index = -3
		add_child(tag)
		lamps.append(lamp)
	var refresh := func():
		for i in circuits.size():
			var live := bool(GameState.get_flag(String(circuits[i][0])))
			(lamps[i] as ColorRect).color = Color(0.36, 0.72, 0.4) if live else Color(0.5, 0.14, 0.1)
	GameState.flags_changed.connect(refresh)
	refresh.call()

class FighterSeat extends Interactable:
	func _init() -> void:
		prompt = "The fighter"

	func _interact(_player: Node) -> void:
		if not bool(GameState.get_flag("sat_in_fighter")):
			GameState.set_flag("sat_in_fighter")
			Hud.toast("One seat. Stick, throttle, and a sticker of a cartoon shark someone loved.")
			Hud.computer_say("That is the P-1 interceptor. I mention its pre-flight checklist because you have the look.")
			return
		# Flying happens when the story says so: SOLACE has called debris on
		# the route, the bay has power, and targeting knows rock from ship.
		if not bool(GameState.get_flag("debris_alerted")):
			Hud.toast("Charged and willing. Nothing on scope worth burning fuel for. Yet.")
			Hud.computer_say("When there is something inbound worth shooting, I will be the first to tell you. Loudly.")
			return
		if not bool(GameState.get_flag("powered_fighter")):
			Hud.toast("The chargers are dark. The bay circuit needs power from the breaker board.")
			return
		if not bool(GameState.get_flag("rock_analysed")):
			Hud.toast("The targeting computer wants a reference sample analysed first - it would prefer not to shoot pieces of ship. Either ship.")
			return
		SaveManager.write_checkpoint()
		Hud.computer_say("Debris cluster dead ahead on the route. Canopy sealed. Fly well.")
		SaveManager._pending_pos = []
		get_tree().change_scene_to_file.call_deferred("res://scenes/fighter/dogfight.tscn")

class BreakerBoard extends Interactable:
	func _init() -> void:
		prompt = "Breaker board"

	func _interact(_player: Node) -> void:
		Minigames.open_power_routing()
