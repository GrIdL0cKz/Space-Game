extends Node2D
## The spine of the Perennial: Rob's hull, three decks and a crawlspace.
## Everything placed here is VISIBLE now - his door art and signed plates
## mark every way out, props mark every search spot, and the crawlspace
## makes you actually crawl.

const DOOR_TEX := "res://astronaught/interior assets/door closed.png"

# Deck stand heights, calibrated from the elevator system + Rob's art.
const DECK_BOTTOM := 655.0
const DECK_MID := 488.0
const DECK_TOP := 331.0
const ATTIC_Y := 160.0

# Floor-band tops per deck (art rows), for placing door sprites.
const FLOOR_TOPS := {655.0: 644.0, 488.0: 478.0, 331.0: 323.0}

func _ready() -> void:
	add_to_group("world")
	ManagerGame.elevator_floor_selected.connect(on_elevator_floor_selected)
	var pending: Variant = SaveManager.consume_pending_position()
	if pending is Vector2:
		$Player.global_position = pending
	_place_ship_contents()
	_first_waking_beat()

func _place_ship_contents() -> void:
	# --- Bottom deck: the working end.
	_door("Fighter Bay", 260, DECK_BOTTOM, "res://scenes/rooms/fighter_bay.tscn", Vector2(220, 631))
	_door("Science Lab", 1500, DECK_BOTTOM, "res://scenes/rooms/science_lab.tscn", Vector2(220, 631),
			"keycard_lab", "Locked. The reader wants Dr. Okonkwo's card, and won't hear otherwise.")
	_door("Airlock", 1830, DECK_BOTTOM, "res://scenes/rooms/airlock_room.tscn", Vector2(300, 631))
	_prop_crate(620, DECK_BOTTOM)
	_spot(Searchable.make("Storage crate", "searched_crate",
			["wrench", "duct_tape", "fuse"],
			"A wrench, duct tape, and a spare ceramic fuse: the three load-bearing pillars of astronautics."),
			Vector2(620, DECK_BOTTOM - 40))
	# --- Mid deck: living.
	_door("Viewing Deck", 1560, DECK_MID, "res://scenes/rooms/viewing_deck.tscn", Vector2(220, 631))
	_door("Crew Quarters", 760, DECK_MID, "res://scenes/rooms/crew_quarters.tscn", Vector2(220, 631))
	_door("Lander Dock", 960, DECK_MID, "res://scenes/rooms/lander_dock.tscn", Vector2(260, 631))
	_prop_locker(560, DECK_MID)
	_spot(Searchable.make("Crew locker", "searched_locker_a",
			["crew_log_medic", "protein_bar"],
			"Dr. Vashchenko's locker. A log, a protein bar, and a photo of a dog you will never meet."),
			Vector2(560, DECK_MID - 40))
	_prop_note(1320, DECK_MID)
	_spot(Searchable.make("Note on the galley wall", "read_galley_note", [],
			"", "It still says what it said.", "note_galley"),
			Vector2(1320, DECK_MID - 40))
	_spot(FlavourSpot.make("Galley", [
		"The dispenser marked COFFEE is lying. The note beside it explains.",
	]), Vector2(1220, DECK_MID - 40))
	# --- Top deck: command.
	_door("Cockpit", 260, DECK_TOP, "res://scenes/rooms/cockpit.tscn", Vector2(1700, 631))
	_prop_desk(1450, DECK_TOP)
	_spot(Searchable.make("Mission desk", "searched_desk",
			["mission_brief", "keycard_lab"],
			"The mission brief, and a keycard clipped to it: Dr. E. Okonkwo, SCIENCE. She left it for whoever woke."),
			Vector2(1450, DECK_TOP - 40))
	_spot(FlavourSpot.make("Cryo bay", [
		"Bays one and two are dark and cold and occupied. You let them be.",
		"Your own pod stands open. It has already done its part.",
	]), Vector2(900, DECK_TOP - 40))
	_spot(CoolantPanel.new(), Vector2(1010, DECK_TOP - 40))
	_make_coolant_alarm(1010.0)
	# --- Crawlspace.
	# One ladder spot reaching deck 3 (standing) and the attic (crawling),
	# but NOT deck 2 below - the box stops above a deck-2 head.
	_spot(Ladder.new(), Vector2(50, 247), Vector2(150, 175))
	# The junction box lives where Rob drew it: far right of the crawl.
	var wires := WiringBox.new()
	_spot(wires, Vector2(1480, ATTIC_Y), Vector2(220, 100))
	_make_attic()

func _door(label: String, x: float, deck_y: float, target: String, spawn: Vector2,
		req := "", locked := "") -> void:
	var floor_top: float = FLOOR_TOPS[deck_y]
	# z 1 so the hull sprite (z 0) can't cover it, and a steel tint so the
	# white line-art door reads as a door instead of more wall. The bottom
	# of the door sits exactly on the floor line.
	var door_sprite := Sprite2D.new()
	door_sprite.texture = load(DOOR_TEX)
	door_sprite.scale = Vector2(0.82, 0.82)
	door_sprite.position = Vector2(x, floor_top - door_sprite.texture.get_height() * 0.82 / 2.0)
	door_sprite.modulate = Color(0.62, 0.7, 0.78)
	door_sprite.z_index = 1
	add_child(door_sprite)
	# Deck interiors are only 92px tall; the plate straddles the ceiling
	# line like a mounted sign instead of vanishing behind the deck above.
	_sign(label, x, floor_top - 105.0)
	_spot(Doorway.make("To: %s" % label, target, spawn, req, locked), Vector2(x, deck_y - 40))

func _sign(text: String, x: float, y: float) -> void:
	var plate := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.32, 0.38)
	style.border_color = Color(0, 0, 0)
	style.set_border_width_all(2)
	plate.add_theme_stylebox_override("panel", style)
	var w := maxf(96.0, text.length() * 12.0 + 18.0)
	plate.size = Vector2(w, 26)
	plate.position = Vector2(x - w / 2.0, y)
	plate.z_index = 10
	add_child(plate)
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98))
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plate.add_child(l)

func _spot(inst: Interactable, pos: Vector2, reach := Vector2(150, 130)) -> void:
	# Reach boxes are shallow on purpose: a crawler in the attic must not
	# be able to work deck-3 consoles through the floor.
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = reach
	cs.shape = rect
	inst.add_child(cs)
	inst.position = pos
	add_child(inst)

# --- Simple engine-drawn props so every searchable is a THING on the deck.

func _prop_locker(x: float, deck_y: float) -> void:
	_prop_box(x, deck_y, Vector2(52, 82), Color(0.42, 0.47, 0.53))

func _prop_crate(x: float, deck_y: float) -> void:
	_prop_box(x, deck_y, Vector2(66, 48), Color(0.55, 0.48, 0.36))

func _prop_desk(x: float, deck_y: float) -> void:
	_prop_box(x, deck_y, Vector2(84, 44), Color(0.5, 0.55, 0.6))

func _prop_note(x: float, deck_y: float) -> void:
	var floor_top: float = FLOOR_TOPS[deck_y]
	var n := ColorRect.new()
	n.color = Color(0.94, 0.92, 0.82)
	n.size = Vector2(20, 26)
	n.position = Vector2(x - 10, floor_top - 95.0)
	n.z_index = -1
	add_child(n)

func _prop_box(x: float, deck_y: float, box_size: Vector2, col: Color) -> void:
	var floor_top: float = FLOOR_TOPS[deck_y]
	var b := ColorRect.new()
	b.color = col
	b.size = box_size
	b.position = Vector2(x - box_size.x / 2.0, floor_top - box_size.y)
	b.z_index = -1
	add_child(b)
	var edge := ColorRect.new()
	edge.color = Color(0, 0, 0)
	edge.size = Vector2(box_size.x, 3)
	edge.position = Vector2(x - box_size.x / 2.0, floor_top - box_size.y)
	edge.z_index = -1
	add_child(edge)

func _make_attic() -> void:
	# Floor for the crawlspace (the art has it; the physics didn't) and a
	# crawl zone that folds the player over while they're up there.
	# The floor lives on layer 8: a standing player is taller than the deck
	# interior, so on the default layer this slab wedged anyone who stood on
	# deck 3. The ladder toggles the player's mask when they climb.
	var attic_body := StaticBody2D.new()
	attic_body.collision_layer = 128
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1840, 20)
	cs.shape = rect
	cs.position = Vector2(960, 232)
	attic_body.add_child(cs)
	add_child(attic_body)
	var zone := Area2D.new()
	zone.collision_layer = 0
	zone.collision_mask = 2
	var zcs := CollisionShape2D.new()
	var zrect := RectangleShape2D.new()
	zrect.size = Vector2(1840, 130)
	zcs.shape = zrect
	zcs.position = Vector2(960, 165)
	zone.add_child(zcs)
	add_child(zone)
	zone.body_entered.connect(func(b: Node):
		# Only fold someone who's actually up here, not a deck-3 jumper
		# whose head grazes the zone mid-air.
		if b.is_in_group("player") and b.has_method("set_crawling") and b.is_on_floor():
			b.set_crawling(true))
	zone.body_exited.connect(func(b: Node):
		if b.is_in_group("player") and b.has_method("set_crawling"):
			b.set_crawling(false))

func _make_coolant_alarm(x: float) -> void:
	# The shortage, announced the ship's way: a small red light over the
	# cryo bay, blinking, with a faint alarm that refuses to be forgotten.
	var light := ColorRect.new()
	light.color = Color(0.85, 0.15, 0.1)
	light.size = Vector2(14, 10)
	light.position = Vector2(x - 7, DECK_TOP - 96.0)
	light.z_index = 5
	add_child(light)
	var tw := create_tween().set_loops()
	tw.tween_property(light, "modulate:a", 0.15, 0.9)
	tw.tween_interval(0.4)
	tw.tween_property(light, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.6)
	var chirp := Timer.new()
	chirp.wait_time = 16.0
	chirp.autostart = true
	add_child(chirp)
	chirp.timeout.connect(func():
		Sd.play(&"alarm_short", -22.0))

class CoolantPanel extends Interactable:
	func _init() -> void:
		prompt = "Coolant status panel"
	func _interact(_player: Node) -> void:
		if bool(GameState.get_flag("solace_online")):
			Hud.computer_say("Embryo bay coolant: 61 percent and leaking politely. There is a depot moon on our route with reserves. When we are moving again, we stop there. I have already written it in the diary.")
		else:
			Hud.toast("COOLANT RESERVE: 61%. TREND: DOWN. A red light blinks above the panel, unhurried and certain.")

func _first_waking_beat() -> void:
	if bool(GameState.get_flag("woke_up")):
		return
	GameState.set_flag("woke_up")
	Hud.toast("Cryo pod 4: cycle complete. Duration: rather longer than advertised.")
	# The ship's mind is down. What answers is the watchdog: a smoke
	# detector with a vocabulary. Restoring SOLACE is the first job.
	Hud.computer_say("AUTONOMIC WATCHDOG ONLINE. PRIMARY INTELLIGENCE: OFFLINE. CAUSE: CORE FUSE FAILURE.")
	Hud.computer_say("RESTORE SEQUENCE: SPARE FUSE - STORES CRATE, THIS DECK. CORE RACK - COCKPIT, DECK 3. END OF ASSISTANCE.")

func on_elevator_floor_selected(floor_number: int) -> void:
	for e in get_tree().get_nodes_in_group("Elevator"):
		if e.floor_number == floor_number:
			Sd.play(&"elevator_hum")
			$Player.global_position = e.global_position
			$Player.global_position.y += 64
			$Player.velocity = Vector2.ZERO
			break

class Ladder extends Interactable:
	## Rob's drawn ladder at the port end of deck 3: the one way up into the
	## crawlspace and the one way back down. Climbing up folds the player
	## prone and lets them collide with the attic floor; climbing down
	## stands them up and releases it.
	func _init() -> void:
		prompt = "Ladder"
	func _interact(player: Node) -> void:
		Sd.play(&"door_slide", -6.0)
		if player.global_position.y > 290.0:
			player.collision_mask |= 128
			player.global_position = Vector2(70.0, 218.0)
			if player.has_method("set_crawling"):
				player.set_crawling(true)
			Hud.toast("You fold yourself into the crawlspace. The wiring looks pleased to see you.")
		else:
			if player.has_method("set_crawling"):
				player.set_crawling(false)
			player.collision_mask &= ~128
			player.global_position = Vector2(70.0, 331.0)

class WiringBox extends Interactable:
	func _init() -> void:
		prompt = "Junction box"
	func _interact(_player: Node) -> void:
		if bool(GameState.get_flag("powered_lab_wiring")):
			Hud.toast("Your splices hold. Somewhere below, the lab hums about it.")
			return
		Minigames.open_wiring()
