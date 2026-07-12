extends RoomBase
## The science lab. Locked behind Dr. Okonkwo's keycard; home of the sample
## scanner (needs lab power from the attic wiring job before it hums).

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/science_lab.png"
	default_spawn = Vector2(160, 860)

func _populate() -> void:
	add_spot(Doorway.make("Back to the ship", "res://scenes/craft_world.tscn",
			Vector2(1500, 655)), Vector2(80, 800))
	var scanner := ScannerConsole.new()
	add_spot(scanner, Vector2(520, 760))
	add_spot(Searchable.make("Search the shelf", "searched_lab_shelf",
			["fuse"],
			"Behind the jars: a spare fuse. The jars you leave exactly where they are.",
			"The jars watch you leave. Probably."), Vector2(1440, 700))
	add_spot(FlavourSpot.make("Specimen table", [
		"Someone labelled the table 'CLEAN' and the label itself is filthy.",
		"Three hundred years of sterile procedure, undone by one coffee ring.",
	]), Vector2(1320, 820))

class ScannerConsole extends Interactable:
	func _init() -> void:
		prompt = "Sample scanner"

	func _interact(_player: Node) -> void:
		if not bool(GameState.get_flag("powered_lab")):
			Hud.toast("Dead console. The lab circuit isn't drawing power.")
			Sd.play(&"switch_click", -10.0, 0.6)
			return
		Minigames.open_lab_scanner()
