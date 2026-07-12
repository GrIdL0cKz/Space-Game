extends RoomBase
## The main shuttle cockpit. Course plotting happens here, and the ship
## computer wakes up here for the first time - your only colleague.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/cockpit.png"
	default_spawn = Vector2(1760, 860)

func _populate() -> void:
	add_spot(Doorway.make("Back to the ship", "res://scenes/craft_world.tscn",
			Vector2(260, 331)), Vector2(1840, 800))
	var nav := NavConsole.new()
	add_spot(nav, Vector2(1000, 780), Vector2(360, 240))
	add_spot(FlavourSpot.make("Pilot's seat", [
		"You sit in it. You feel neither more nor less qualified.",
		"There is a coffee holder. There is no coffee. Priorities were had.",
	]), Vector2(1080, 500))
	var overhead := FlavourSpot.make("Overhead panel", [
		"Half the lights are amber. The manual calls amber 'advisory'. The manual is an optimist.",
	])
	add_spot(overhead, Vector2(1300, 200), Vector2(700, 200))

class NavConsole extends Interactable:
	func _init() -> void:
		prompt = "Navigation console"

	func _interact(_player: Node) -> void:
		if not bool(GameState.get_flag("computer_booted")):
			GameState.set_flag("computer_booted")
			Sd.play(&"console_boot")
			Hud.computer_say("...")
			Hud.computer_say("Good morning. Boot time 4,196 milliseconds. I have been rehearsing that greeting for one hundred and six years.")
			Hud.computer_say("Status summary: propulsion HALTED, course DRIFTING, crew... let's do status again later.")
			Hud.computer_say("The heading needs plotting by hand. The console will walk you through it. I will watch supportively.")
			return
		if bool(GameState.get_flag("course_plotted")):
			Hud.toast("Heading locked. The stars slide past at the correct angle now.")
			Hud.computer_say("Course holding. Estimated arrival: within your natural lifespan. I checked twice.")
			return
		Minigames.open_course_plot()
