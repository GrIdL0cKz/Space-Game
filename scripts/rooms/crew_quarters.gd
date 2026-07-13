extends RoomBase
## Crew quarters: bunks, a wardrobe, a mirror, and a wall of photographs of
## people who are not here. This is where you change clothes like a person
## instead of through a menu - the wardrobe works the suit, piece by piece.

func _init() -> void:
	bg_texture = "res://astronaught/environs/rooms/crew_quarters.png"
	default_spawn = Vector2(220, STAND_Y)

func _populate() -> void:
	add_door("Corridor", 110, "res://scenes/craft_world.tscn", Vector2(760, 488))
	add_spot(FlavourSpot.make("Your bunk", [
		"Slept in once, three hundred years ago, technically by you.",
		"You could sleep. You should sleep. You check one more system instead.",
	]), 490, Vector2(300, 170))
	add_spot(FlavourSpot.make("Their bunks", [
		"Made. All of them. Whoever went last had time to be tidy.",
	]), 890, Vector2(300, 170))
	var wardrobe := Wardrobe.new()
	add_spot(wardrobe, 1255, Vector2(200, 190))
	add_spot(FlavourSpot.make("Mirror", [
		"You look like someone who has been asleep for three centuries. Accurate.",
		"You practise saying 'hello'. Out loud. It comes out strange. You'll get it back.",
	]), 1385)
	add_spot(FlavourSpot.make("Photo wall", [
		"Six crews' worth of families, all of them older than nations now.",
		"One photo shows a dog. Dr. Vashchenko's log was right about future missions.",
	]), 1610, Vector2(280, 190))

class Wardrobe extends Interactable:
	func _init() -> void:
		prompt = "Wardrobe"

	func _interact(_player: Node) -> void:
		var lines: Array[String] = []
		if GameState.has_item("suit_helmet") or GameState.is_equipped("suit_helmet"):
			var h := not GameState.is_equipped("suit_helmet")
			GameState.set_equipped("suit_helmet", h)
			Sd.play(&"helmet_seal")
			lines.append("Helmet %s." % ("sealed" if h else "off - hair situation confirmed survivable"))
			Hud.toast(lines[0])
		else:
			Hud.toast("Jumpsuits in crew sizes, none of them yours exactly. The EVA gear lives at the airlock.")
