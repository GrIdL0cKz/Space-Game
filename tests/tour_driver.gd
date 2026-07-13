extends Node
## The persistent half of the visual tour: lives under /root, survives
## every scene change, shoots each stop, quits at the end.

const STOPS := [
	["res://scenes/main.tscn", "menu"],
	["res://scenes/intro.tscn", "intro"],
	["res://scenes/rooms/cryo_bay.tscn", "cryobay"],
	["res://scenes/craft_world.tscn", "ship"],
	["res://scenes/rooms/science_lab.tscn", "lab"],
	["res://scenes/rooms/viewing_deck.tscn", "viewing"],
	["res://scenes/rooms/cockpit.tscn", "cockpit"],
	["res://scenes/rooms/fighter_bay.tscn", "bay"],
	["res://scenes/rooms/airlock_room.tscn", "airlock"],
	["res://scenes/rooms/crew_quarters.tscn", "quarters"],
	["res://scenes/rooms/eva_outside.tscn", "eva"],
	["res://scenes/fighter/dogfight.tscn", "dogfight"],
	["res://scenes/rooms/lander_dock.tscn", "landerdock"],
	["res://scenes/lander/lander_flight.tscn", "flight"],
	["res://scenes/rooms/derelict_ship.tscn", "derelict"],
]

var idx: int = 0

func _ready() -> void:
	GameState.reset()
	GameState.add_item("suit_torso", 1, true)
	GameState.add_item("suit_helmet", 1, true)
	GameState.add_item("wrench", 1, true)
	GameState.add_item("manual_airlock", 1, true)
	GameState.set_flag("solace_online")
	_next()

func _next() -> void:
	if idx >= STOPS.size():
		print("tour complete")
		get_tree().quit()
		return
	var stop: Array = STOPS[idx]
	get_tree().change_scene_to_file.call_deferred(String(stop[0]))
	var t := get_tree().create_timer(1.8)
	t.timeout.connect(func():
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://tests/tour_%s.png" % String(stop[1]))
		print("shot ", String(stop[1]))
		idx += 1
		_next())
