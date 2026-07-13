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
	add_spot(AICore.new(), 190, Vector2(220, 200))
	add_spot(FlavourSpot.make("Pilot's seat", [
		"You sit in it. You feel neither more nor less qualified.",
		"There is a cup holder. There is no cup. Priorities were had.",
	]), 1020)
	add_spot(FlavourSpot.make("Advisory panel", [
		"Half the lights are amber. The manual calls amber 'advisory'. The manual is an optimist.",
	]), 1445, Vector2(560, 200))

class AICore extends Interactable:
	## The ship's mind, fuse blown since the strike. One spare ceramic fuse
	## turns the watchdog into SOLACE - and SOLACE into the quest-giver.
	func _init() -> void:
		prompt = "AI core rack"

	func _interact(_player: Node) -> void:
		if bool(GameState.get_flag("solace_online")):
			Hud.computer_say("The rack is fine now, thank you. It is the rest of the ship I worry about.")
			return
		if not GameState.has_item("fuse"):
			Hud.computer_say("CORE RACK OPEN. FUSE SOCKET: EMPTY. SPARE FUSE: STORES CRATE, DECK 1. END OF ASSISTANCE.")
			return
		GameState.remove_item("fuse")
		GameState.set_flag("solace_online")
		Sd.play(&"console_boot")
		Hud.toast("The fuse seats with a click. Somewhere behind the panel, a mind boots.")
		Hud.computer_say("...")
		Hud.computer_say("Good morning. Boot time 4,196 milliseconds. I have been rehearsing that greeting for one hundred and six years. I am SOLACE: Ship Operations, Logistics And Crew Emulation.")
		Hud.computer_say("Status summary: propulsion HALTED, course DRIFTING, crew... let's do status again later.")
		Hud.computer_say("Twenty-six months ago I executed an emergency avoidance manoeuvre and awaited instructions. None came. The object I avoided is still out there, holding station off our bow. I would very much like you to go and look at it.")
		Hud.computer_say("Also: the embryo bay coolant reserve is bleeding pressure. That is the red light, and the little alarm that goes with it. Not urgent. Not nothing, either.")
		Hud.computer_say("The lander is docked on deck 2. I can release the clamps whenever you are ready. No pressure. Well. Some pressure.")

class NavConsole extends Interactable:
	func _init() -> void:
		prompt = "Navigation console"

	func _interact(_player: Node) -> void:
		if not bool(GameState.get_flag("solace_online")):
			Hud.computer_say("NAVIGATION CONSOLE LOCKED. PRIMARY INTELLIGENCE: OFFLINE. RESTORE CORE RACK FIRST. END OF ASSISTANCE.")
			return
		if not bool(GameState.get_flag("computer_booted")):
			GameState.set_flag("computer_booted")
			Hud.computer_say("The heading needs plotting by hand. The console will walk you through it. I will watch supportively.")
			return
		if bool(GameState.get_flag("course_plotted")):
			Hud.toast("Heading locked. The stars slide past at the correct angle now.")
			Hud.computer_say("Course holding. Estimated arrival: within your natural lifespan. I checked twice.")
			return
		Minigames.open_course_plot()
