extends Node2D
## The main deck of the Perennial: Rob's hull, three floors, the elevators,
## the flickering lights. Gameplay scenes join the "world" group so the HUD
## knows to exist; a loaded save drops the player exactly where they stood.

func _ready() -> void:
	add_to_group("world")
	ManagerGame.elevator_floor_selected.connect(on_elevator_floor_selected)
	var pending: Variant = SaveManager.consume_pending_position()
	if pending is Vector2:
		$Player.global_position = pending

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
