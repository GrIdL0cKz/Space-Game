extends RoomBase
## Aboard the CSV Reprieve: two years abandoned, lights still on. Gear to
## take, a captain's log that says almost everything, and a comms core
## that says nothing yet. Nobody talks in your ear here - SOLACE stayed
## home, and the quiet is the point.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/derelict_deck.png"
	default_spawn = Vector2(180, STAND_Y)

func _ready() -> void:
	super()
	# Emergency lighting: everything a shade colder and redder.
	var mood := CanvasModulate.new()
	mood.color = Color(0.78, 0.68, 0.66)
	add_child(mood)
	if not bool(GameState.get_flag("derelict_first_step")):
		GameState.set_flag("derelict_first_step")
		Hud.toast("Dust. Cold. Stillness, and every light left on.")

func _populate() -> void:
	add_spot(CastOff.new(), 110, Vector2(160, 200))
	add_spot(Searchable.make("Spares bin", "reprieve_spares",
			["power_cell", "wire_coil"],
			"Their spares became your spares. Wherever the crew went, they were not coming back for the fuses."),
			620)
	add_spot(FlavourSpot.make("Emergency lamp", [
		"Still burning. However long it has been, it is still trying, and you find you respect it.",
	]), 778, Vector2(160, 200))
	add_spot(Searchable.make("Supply locker", "reprieve_locker",
			["medkit", "protein_bar"],
			"Stocked to come back to. Nobody came back. You take what keeps."),
			980)
	add_spot(Searchable.make("Crew tag on the rail", "reprieve_tag_found",
			["reprieve_tag"],
			"A crew tag, snapped from its lanyard in a hurry, by the pod rails."),
			1400)
	add_spot(FlavourSpot.make("Escape pod bays", [
		"Both pods gone. Dust on the launch rails, thick and undisturbed.",
		"Whatever happened here, it happened in an orderly queue. That is its own kind of chilling.",
	]), 1500, Vector2(400, 200))
	add_spot(Searchable.make("Captain's log terminal", "read_reprieve_log", [],
			"", "The terminal wakes reluctantly, like it had made peace with being done.", "reprieve_captains_log"),
			1800)
	add_spot(CommsCore.new(), 1660, Vector2(150, 200))

class CastOff extends Interactable:
	func _init() -> void:
		prompt = "Lander - cast off"
	func _interact(_player: Node) -> void:
		Sd.play(&"airlock_clunk")
		# Push off well clear of the hatch: spawning inside the dock radius
		# used to re-dock you instantly, forever.
		SaveManager._pending_pos = [4230.0, 880.0]
		get_tree().change_scene_to_file.call_deferred("res://scenes/lander/lander_flight.tscn")

class CommsCore extends Interactable:
	func _init() -> void:
		prompt = "Comms core"
	func _interact(_player: Node) -> void:
		if bool(GameState.get_flag("reprieve_comms_found")):
			Hud.toast("Still encrypted. Still newer than anything this ship should be carrying.")
			return
		GameState.set_flag("reprieve_comms_found")
		Sd.play(&"computer_blip", -8.0)
		Hud.toast("The comms core is intact and encrypted - an Earth cipher, decades newer than this hull. Someone kept this ship's secrets on purpose. SOLACE will want a copy.")
