extends RoomBase
## The main shuttle cockpit, in the nose taper. Course plotting and the
## computer's first words happen at the dash.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/cockpit.png"
	default_spawn = Vector2(1700, STAND_Y)

func _populate() -> void:
	add_door("Corridor", 1828, "res://scenes/craft_world.tscn", Vector2(260, 331))
	add_sign("Cockpit", 620)
	var nav := NavConsole.new()
	add_spot(nav, 615, Vector2(560, 170))
	add_spot(FlavourSpot.make("Pilot's seat", [
		"You sit in it. You feel neither more nor less qualified.",
		"There is a cup holder. There is no cup. Priorities were had.",
	]), 1020)
	add_spot(FlavourSpot.make("Advisory panel", [
		"Half the lights are amber. The manual calls amber 'advisory'. The manual is an optimist.",
	]), 1445, Vector2(560, 200))

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
