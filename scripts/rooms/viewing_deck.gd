extends RoomBase
## The viewing deck. The destination hangs in the window, closer than it
## has any right to be. This is where the game gets to be quiet on purpose.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/viewing_deck.png"
	default_spawn = Vector2(160, 860)

func _populate() -> void:
	add_spot(Doorway.make("Back to the ship", "res://scenes/craft_world.tscn",
			Vector2(1560, 488)), Vector2(80, 800))
	var window := FlavourSpot.make("Look out", [
		"Still there. Still slightly to the left of where it should be.",
		"You count the stars for a while. You lose count. They don't.",
		"The window has a smudge at nose height. You are not the first to stand here.",
	], [
		"That's it. Kepler-442b. Two hundred and ninety-seven years of travel, and it fits behind your thumb.",
		"Navigation says we are 0.4 degrees off course. Navigation says this like it isn't a catastrophe.",
	])
	add_spot(window, Vector2(960, 780), Vector2(700, 260))
	add_spot(FlavourSpot.make("Sit on the bench", [
		"You sit. The ship hums. Nobody joins you.",
		"The bench is bolted down, which suggests someone once had plans for it in zero-g.",
		"You allow yourself five minutes. You take eleven.",
	]), Vector2(960, 850))
