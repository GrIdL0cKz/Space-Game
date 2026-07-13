extends RoomBase
## The aft airlock, at hull scale: suit rack, manual pouch, pressure
## console between two real doors. Every lethal choice checkpoints first.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/airlock.png"
	default_spawn = Vector2(300, STAND_Y)

func _populate() -> void:
	# The inner door is not a formality: while the chamber sits at vacuum
	# (airlock_cycled), it stays sealed until the console repressurises.
	var inner := InnerDoor.new()
	var inner_sprite := Sprite2D.new()
	inner_sprite.texture = load(DOOR_TEX)
	inner_sprite.scale = Vector2(0.8, 0.8)
	inner_sprite.position = Vector2(148, FLOOR_TOP - inner_sprite.texture.get_height() * 0.8 / 2.0)
	inner_sprite.modulate = Color(0.62, 0.7, 0.78)
	inner_sprite.z_index = -5
	add_child(inner_sprite)
	add_sign("Ship", 148)
	add_spot(inner, 148)
	add_spot(Searchable.make("Suit rack", "searched_suit_rack",
			["suit_torso", "suit_helmet"],
			"A pressure suit and helmet, racked with the care of someone who meant to come back."),
			530, Vector2(260, 170))
	add_spot(Searchable.make("Document pouch", "searched_airlock_pouch",
			["manual_airlock"],
			"A laminated manual on a lanyard. Rev. 11. You wonder briefly about Revs 1 through 10.",
			"Just the pouch. The lanyard stays."),
			745)
	var console := PressureConsole.new()
	add_spot(console, 960, Vector2(300, 190))
	var outer := OuterDoor.new()
	add_sign("Outer Door", 1768)
	add_spot(outer, 1768, Vector2(220, 220))

class InnerDoor extends Interactable:
	func _init() -> void:
		prompt = "Ship"

	func _interact(_player: Node) -> void:
		if bool(GameState.get_flag("airlock_cycled")):
			Hud.toast("Sealed. The chamber behind you is still hard vacuum - cycle the console before this door will even discuss it.")
			return
		Sd.play(&"door_slide")
		SaveManager._pending_pos = [1830.0, 655.0]
		get_tree().change_scene_to_file.call_deferred("res://scenes/craft_world.tscn")

class PressureConsole extends Interactable:
	func _init() -> void:
		prompt = "Pressure console"

	func _interact(_player: Node) -> void:
		if bool(GameState.get_flag("airlock_cycled")):
			# Coming home: the chamber is at vacuum and must be refilled
			# before the inner door acknowledges you exist.
			GameState.set_flag("airlock_cycled", false)
			Sd.play(&"airlock_hiss")
			Sd.play(&"airlock_clunk", -6.0)
			Hud.toast("TSHHHHH. Pressure floods back. Sound returns with it - the hum, the vents, your own breathing. The inner door unlocks.")
			return
		SaveManager.write_checkpoint()
		Minigames.open_airlock_sequence()

class OuterDoor extends Interactable:
	func _init() -> void:
		prompt = "Outer door"

	func _interact(_player: Node) -> void:
		if not bool(GameState.get_flag("airlock_cycled")):
			Hud.toast("Sealed against a pressurised chamber. The console decides when this opens.")
			return
		SaveManager.write_checkpoint()
		if not GameState.eva_safe():
			var missing := "helmet" if GameState.is_equipped("suit_torso") else "suit"
			Death.die("EXPLOSIVE SOCIALISING",
				"You stepped into hard vacuum without your %s. Space accepted you exactly as you were, which is more than can be said for your lungs." % missing)
			return
		GameState.set_flag("went_eva")
		Sd.play(&"airlock_clunk")
		SaveManager._pending_pos = [400.0, 545.0]
		get_tree().change_scene_to_file.call_deferred("res://scenes/rooms/eva_outside.tscn")
