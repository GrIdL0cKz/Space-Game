extends RoomBase
## The viewing deck: the wall is glass and the destination is in it.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/viewing_deck.png"
	default_spawn = Vector2(220, STAND_Y)

func _populate() -> void:
	add_door("Corridor", 110, "res://scenes/craft_world.tscn", Vector2(1560, 488))
	add_sign("Viewing Deck", 700)
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
