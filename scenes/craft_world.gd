extends Node2D
## The main deck of the Perennial: Rob's hull, three floors, the elevators,
## the flickering lights. Gameplay scenes join the "world" group so the HUD
## knows to exist; a loaded save drops the player exactly where they stood.

const DECK_BOTTOM := 655.0
const DECK_MID := 488.0
const DECK_TOP := 331.0
const ATTIC := 170.0

func _ready() -> void:
	add_to_group("world")
	ManagerGame.elevator_floor_selected.connect(on_elevator_floor_selected)
	var pending: Variant = SaveManager.consume_pending_position()
	if pending is Vector2:
		$Player.global_position = pending
	_place_ship_contents()
	_first_waking_beat()

# Doors, lockers, terminals and the attic - everything placed in code so
# Rob's hull scene stays untouched and the deck plan reads as a list.
func _place_ship_contents() -> void:
	# Bottom deck: working end of the ship.
	_spot(Doorway.make("Fighter bay", "res://scenes/rooms/fighter_bay.tscn", Vector2(160, 860)),
			Vector2(260, DECK_BOTTOM))
	_spot(Doorway.make("Science lab", "res://scenes/rooms/science_lab.tscn", Vector2(160, 860),
			"keycard_lab", "Locked. The reader wants Dr. Okonkwo's card, and won't hear otherwise."),
			Vector2(1500, DECK_BOTTOM))
	_spot(Doorway.make("Aft airlock", "res://scenes/rooms/airlock_room.tscn", Vector2(160, 860)),
			Vector2(1840, DECK_BOTTOM))
	_spot(Searchable.make("Storage crate", "searched_crate",
			["wrench", "duct_tape"],
			"A wrench and a roll of duct tape: the two load-bearing pillars of astronautics."),
			Vector2(620, DECK_BOTTOM))
	# Mid deck: living quarters.
	_spot(Doorway.make("Viewing deck", "res://scenes/rooms/viewing_deck.tscn", Vector2(160, 860)),
			Vector2(1560, DECK_MID))
	_spot(Searchable.make("Crew locker", "searched_locker_a",
			["crew_log_medic", "protein_bar"],
			"Dr. Vashchenko's locker. A log, a protein bar, and a photo of a dog you will never meet."),
			Vector2(620, DECK_MID))
	_spot(FlavourSpot.make("Galley", [
		"The dispenser marked COFFEE is lying. The note on the wall explains.",
	], []), Vector2(1240, DECK_MID))
	_spot(Searchable.make("Note on the galley wall", "read_galley_note", [],
			"", "It still says what it said.", "note_galley"),
			Vector2(1320, DECK_MID))
	# Top deck: command and quarters.
	_spot(Doorway.make("Cockpit", "res://scenes/rooms/cockpit.tscn", Vector2(1760, 860)),
			Vector2(260, DECK_TOP))
	_spot(Searchable.make("Mission desk", "searched_desk",
			["mission_brief", "keycard_lab"],
			"The mission brief, and a keycard clipped to it: Dr. E. Okonkwo, SCIENCE. She left it for whoever woke."),
			Vector2(1450, DECK_TOP))
	_spot(FlavourSpot.make("Cryo bay door", [
		"Bays one and two are dark and cold and occupied. You let them be.",
		"Your own pod stands open. It has already done its part.",
	]), Vector2(900, DECK_TOP))
	# Attic access + the wiring job.
	_spot(HatchUp.new(), Vector2(140, DECK_TOP))
	_spot(HatchDown.new(), Vector2(240, ATTIC))
	var wires := WiringBox.new()
	_spot(wires, Vector2(660, ATTIC), Vector2(260, 200))
	# The crawlspace floor: Rob's art has the deck, the physics didn't.
	var attic_body := StaticBody2D.new()
	var attic_cs := CollisionShape2D.new()
	var attic_rect := RectangleShape2D.new()
	attic_rect.size = Vector2(1800, 20)
	attic_cs.shape = attic_rect
	attic_cs.position = Vector2(960, 230)
	attic_body.add_child(attic_cs)
	add_child(attic_body)

func _spot(inst: Interactable, pos: Vector2, reach := Vector2(170, 200)) -> void:
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = reach
	cs.shape = rect
	inst.add_child(cs)
	inst.position = pos
	add_child(inst)

func _first_waking_beat() -> void:
	if bool(GameState.get_flag("woke_up")):
		return
	GameState.set_flag("woke_up")
	Hud.toast("Cryo pod 4: cycle complete. Duration: rather longer than advertised.")
	Hud.computer_say("Occupant of pod four: welcome back. Please remain calm. Several things require your attention, in an order I am still prioritising.")

class HatchUp extends Interactable:
	func _init() -> void:
		prompt = "Climb to the crawlspace"
	func _interact(player: Node) -> void:
		Sd.play(&"door_slide", -6.0)
		player.global_position.y = 170.0

class HatchDown extends Interactable:
	func _init() -> void:
		prompt = "Climb down"
	func _interact(player: Node) -> void:
		Sd.play(&"door_slide", -6.0)
		player.global_position.y = 331.0

class WiringBox extends Interactable:
	func _init() -> void:
		prompt = "Junction box"
	func _interact(_player: Node) -> void:
		if bool(GameState.get_flag("powered_lab_wiring")):
			Hud.toast("Your splices hold. Somewhere below, the lab hums about it.")
			return
		Minigames.open_wiring()

func _unhandled_input(event: InputEvent) -> void:
	# Click / tap on open floor walks there. Interactables consume their own
	# clicks first, so a walk order never fires when you meant "use that".
	if Hud.any_overlay_open():
		return
	var tapped: bool = event is InputEventScreenTouch and not event.pressed
	if tapped:
		var pos := Vector2(event.position.x, $Player.global_position.y)
		$Player.move_to(pos)

func on_elevator_floor_selected(floor_number: int) -> void:
	for e in get_tree().get_nodes_in_group("Elevator"):
		if e.floor_number == floor_number:
			Sd.play(&"elevator_hum")
			$Player.global_position = e.global_position
			$Player.global_position.y += 64
			break
