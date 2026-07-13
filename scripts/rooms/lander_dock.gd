extends RoomBase
## Deck 2: the lander on its cradle. SOLACE holds the clamps until it's
## online, which makes the little ship the reward for fixing the big one's
## mind. Coming back from the Reprieve triggers the debrief.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/lander_dock.png"
	default_spawn = Vector2(260, STAND_Y)

func _ready() -> void:
	super()
	if bool(GameState.get_flag("visited_derelict")) and not bool(GameState.get_flag("derelict_debriefed")):
		GameState.set_flag("derelict_debriefed")
		Hud.computer_say("Welcome back. I read the lander's telemetry while you were over there, because I am incapable of not.")
		Hud.computer_say("A crewed vessel. Holding station off our bow for two years, lights on, nobody home. It found us, and then something went wrong, and the wrongness appears to have been mutual.")
		Hud.computer_say("Their comms core is encrypted with an Earth cipher newer than anything in my libraries. Bring me time and I will bring you the why.")

func _populate() -> void:
	add_door("Corridor", 110, "res://scenes/craft_world.tscn", Vector2(1250, 488))
	add_spot(LanderSeat.new(), 1150, Vector2(420, 200))
	add_spot(FlavourSpot.make("Clamp status box", [
		"One red light, one amber. In dock-clamp language this means 'ask the computer'.",
	]), 405, Vector2(180, 200))

class LanderSeat extends Interactable:
	func _init() -> void:
		prompt = "Board the lander"

	func _interact(_player: Node) -> void:
		if not bool(GameState.get_flag("solace_online")):
			Hud.toast("The dock clamps are software-locked, and the software in charge is currently a smoke detector. The cockpit AI core might help.")
			return
		SaveManager.write_checkpoint()
		Sd.play(&"airlock_clunk")
		Hud.computer_say("Clamps released. Thrusters are gentle beasts: nudge, wait, nudge. The hatch on that thing's belly is your target. Please do not arrive as a headline.")
		SaveManager._pending_pos = [820.0, 560.0]
		get_tree().change_scene_to_file.call_deferred("res://scenes/lander/lander_flight.tscn")
