extends RoomBase
## The viewing deck: the wall is glass and the destination is in it.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/viewing_deck.png"
	default_spawn = Vector2(220, STAND_Y)

func _populate() -> void:
	add_door("Corridor", 110, "res://scenes/craft_world.tscn", Vector2(1560, 488))
	var window := FlavourSpot.make("Look out", [
		"Still there. Still slightly to the left of where it should be.",
		"You count the stars for a while. You lose count. They don't.",
		"The glass has a smudge at forehead height. You are not the first to lean here.",
	], [
		"That's it. Kepler-442b. Two hundred and ninety-seven years of travel, and it fits behind your thumb.",
		"Navigation says we are 0.4 degrees off course. Navigation says this like it isn't a catastrophe.",
	])
	add_spot(window, 1000, Vector2(1200, 170))
	add_spot(FlavourSpot.make("Lean on the rail", [
		"You lean. The ship hums. Nobody joins you.",
		"You allow yourself five minutes. You take eleven.",
	]), 420)
	add_spot(ObservationConsole.new(), 1700, Vector2(200, 170))

class ObservationConsole extends Interactable:
	## The reason to power this deck: long-range optics that actually track
	## the story. Dark circuit, dark console.
	func _init() -> void:
		prompt = "Observation console"

	func _interact(_player: Node) -> void:
		if not bool(GameState.get_flag("powered_viewing")):
			Hud.toast("Dead screen. The viewing deck circuit is dark - the breaker board in the fighter bay decides who gets light.")
			return
		if not bool(GameState.get_flag("visited_derelict")):
			Sd.play(&"scanner_done", -8.0)
			Hud.toast("The optics sweep aft and catch a glint: something metallic, holding station off the bow. Not drifting. HOLDING. The lander could reach it.")
			return
		if not bool(GameState.get_flag("debris_cleared")):
			Sd.play(&"scanner_done", -8.0)
			Hud.toast("The route ahead sparkles in the wrong way. Debris, a whole field of it, sitting exactly where the ship needs to go.")
			return
		Sd.play(&"scanner_done", -8.0)
		Hud.toast("Ahead: the long dark, then a depot moon, then Kepler-442b. In that order, and finally in motion.")
