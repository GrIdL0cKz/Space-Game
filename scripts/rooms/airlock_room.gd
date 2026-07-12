extends RoomBase
## The aft airlock. Everything Rob promised about Space Quest lives here:
## the chamber follows real procedure, the manual teaches it, and every
## shortcut is survivable only by reload. Checkpoints are written before
## each lethal choice, so dying is a punchline, not a punishment.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/airlock.png"
	default_spawn = Vector2(160, 860)

func _populate() -> void:
	add_spot(Doorway.make("Inner door - back inside", "res://scenes/craft_world.tscn",
			Vector2(1830, 655)), Vector2(180, 800))
	add_spot(Searchable.make("Suit rack", "searched_suit_rack",
			["suit_torso", "suit_helmet"],
			"A pressure suit and helmet, racked with the care of someone who meant to come back."),
			Vector2(560, 800))
	add_spot(Searchable.make("Document pouch", "searched_airlock_pouch",
			["manual_airlock"],
			"A laminated manual on a lanyard. Rev. 11. You wonder briefly about Revs 1 through 10.",
			"Just the pouch. The lanyard stays."),
			Vector2(870, 700))
	var console := PressureConsole.new()
	add_spot(console, Vector2(1030, 760), Vector2(300, 260))
	var outer := OuterDoor.new()
	add_spot(outer, Vector2(1650, 800), Vector2(320, 400))

class PressureConsole extends Interactable:
	func _init() -> void:
		prompt = "Pressure console"

	func _interact(_player: Node) -> void:
		if bool(GameState.get_flag("airlock_cycled")):
			Hud.toast("Chamber at vacuum. The outer door is willing.")
			return
		# The choice ahead can kill: bank progress silently first.
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
		SaveManager._pending_pos = [180.0, 540.0]
		get_tree().change_scene_to_file.call_deferred("res://scenes/rooms/eva_outside.tscn")
