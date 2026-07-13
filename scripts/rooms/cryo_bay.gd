extends RoomBase
## Where the game begins: six pods, one of them yours and open, two dark,
## two still sleeping, and one gone entirely - unbolted, cables hanging.
## The wake-up beat, the cryosickness, and the first quest all start here.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/cryo_bay.png"
	default_spawn = Vector2(330, STAND_Y)

func _ready() -> void:
	super()
	if not bool(GameState.get_flag("woke_up")):
		GameState.set_flag("woke_up")
		GameState.set_flag("cryosick", 3)
		Hud.toast("Cryo pod 4: cycle complete. Duration: rather longer than advertised.")
		Hud.computer_say("AUTONOMIC WATCHDOG ONLINE. PRIMARY INTELLIGENCE: OFFLINE. CAUSE: CORE FUSE FAILURE.")
		Hud.computer_say("RESTORE SEQUENCE: SPARE FUSE - STORES CRATE, DECK 1. CORE RACK - COCKPIT, DECK 3. END OF ASSISTANCE.")

func _populate() -> void:
	add_door("Corridor", 110, "res://scenes/craft_world.tscn", Vector2(860, 331))
	add_spot(FlavourSpot.make("Your pod", [
		"Pod 4. Lid open, bed still shaped like you. It did its job for longer than anyone asked it to.",
		"You do not climb back in. It is a near thing.",
	]), 320, Vector2(200, 170))
	add_spot(FlavourSpot.make("Pod 2", [
		"Dark. Cold in the wrong way. The status lamp is a colour you will not forget.",
	]), 520, Vector2(160, 170))
	add_spot(FlavourSpot.make("Pod 3", [
		"Dark, like its neighbour. Whatever failed here failed quietly, and twice.",
	]), 720, Vector2(160, 170))
	add_spot(FlavourSpot.make("Pod 5", [
		"Green lamp. Slow frost on the glass. Someone is still in there, still asleep, still on schedule.",
		"You rest a hand on the glass. The pod does not object.",
	]), 920, Vector2(160, 170))
	add_spot(FlavourSpot.make("Pod 6", [
		"Green lamp, steady breath of the compressors. Asleep. The pods say DO NOT DISTURB and they mean it.",
	]), 1120, Vector2(160, 170))
	add_spot(Searchable.make("Empty pod cradle", "searched_missing_pod",
			["osei_note"],
			"Pod 1 is GONE - unbolted, umbilicals sheared, a dust outline where it stood. An envelope is taped to the cradle, addressed: TO WHOEVER WAKES."),
			1365, Vector2(220, 170))
	add_spot(PodDiagnostics.new(), 1710, Vector2(280, 190))

class PodDiagnostics extends Interactable:
	func _init() -> void:
		prompt = "Pod diagnostics"

	func _interact(_player: Node) -> void:
		Sd.play(&"computer_blip", -10.0)
		if not bool(GameState.get_flag("read_pod_diagnostics")):
			GameState.set_flag("read_pod_diagnostics")
			Hud.toast("POD 1: REMOVED (manual release). PODS 2, 3: OCCUPANT DECEASED - power interruption. PODS 5, 6: NOMINAL. POD 4: OCCUPANT DECEASED.")
			Hud.computer_say("POD 4 STATUS CONFLICT: OCCUPANT LOGGED DECEASED; OCCUPANT CURRENTLY OPERATING THIS PANEL. SENSOR FAULT FILED. APOLOGY: PENDING.")
			return
		Hud.toast("Pod 4 still reads OCCUPANT DECEASED, then a long appendix about sensor faults. Somebody believed this screen once. You wonder who it cost.")
