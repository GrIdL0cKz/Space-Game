extends RoomBase
## The science lab: scanner on the bench, jars on the shelf, a locker of
## other people's careful work. Needs the keycard to enter and attic power
## to be useful.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/science_lab.png"
	default_spawn = Vector2(220, STAND_Y)

func _populate() -> void:
	add_door("Corridor", 110, "res://scenes/craft_world.tscn", Vector2(1500, 655))
	add_sign("Science Lab", 590)
	var scanner := ScannerConsole.new()
	add_spot(scanner, 590, Vector2(360, 170))
	add_spot(Searchable.make("Search the shelf", "searched_lab_shelf",
			["fuse"],
			"Behind the jars: a spare fuse. The jars you leave exactly where they are.",
			"The jars watch you leave. Probably."), 1480, Vector2(340, 170))
	add_spot(Searchable.make("Specimen locker", "searched_lab_locker",
			["sample_rock"],
			"A catalogued fragment, bagged and dated Y204. Dr. Okonkwo never got to finish with it.",
			"Empty, except for the smell of careful work."), 1775)

class ScannerConsole extends Interactable:
	func _init() -> void:
		prompt = "Sample scanner"

	func _interact(_player: Node) -> void:
		if not bool(GameState.get_flag("powered_lab")):
			Hud.toast("Dead console. The lab circuit isn't drawing power.")
			Sd.play(&"switch_click", -10.0, 0.6)
			return
		Minigames.open_lab_scanner()
