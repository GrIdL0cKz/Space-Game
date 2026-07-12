extends RoomBase
## The fighter bay. The little dogfighter sits on its cradle - one seat,
## no systems yet, all promise. The ship's breaker board lives here too:
## the power-routing job with real consequences.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/fighter_bay.png"
	default_spawn = Vector2(160, 860)

func _populate() -> void:
	add_spot(Doorway.make("Back to the ship", "res://scenes/craft_world.tscn",
			Vector2(260, 655)), Vector2(80, 800))
	var seat := FighterSeat.new()
	add_spot(seat, Vector2(910, 700), Vector2(500, 260))
	add_spot(Searchable.make("Tool chest", "searched_tool_chest",
			["power_cell", "fuse"],
			"A power cell and a fuse, under a layer of sockets sorted by someone with feelings about sockets."),
			Vector2(340, 830))
	var breaker := BreakerBoard.new()
	add_spot(breaker, Vector2(1670, 760), Vector2(260, 300))

class FighterSeat extends Interactable:
	func _init() -> void:
		prompt = "The fighter"

	func _interact(_player: Node) -> void:
		if not bool(GameState.get_flag("sat_in_fighter")):
			GameState.set_flag("sat_in_fighter")
			Hud.toast("One seat. Stick, throttle, and a sticker of a cartoon shark someone loved.")
			Hud.computer_say("That is the P-1 interceptor. Flight systems are offline. I mention this because you have the look.")
			return
		Hud.toast("Fuel lines dry, guidance dark. It'll fly when the ship can spare it the power. Soon.")

class BreakerBoard extends Interactable:
	func _init() -> void:
		prompt = "Breaker board"

	func _interact(_player: Node) -> void:
		Minigames.open_power_routing()
