extends Node2D


func _ready():
	ManagerGame.elevator_floor_selected.connect(on_elevator_floor_selected)


func _unhandled_input(event):
	if event is InputEventScreenTouch and !event.pressed:
		var pos = Vector2.ZERO
		pos.x = event.position.x
		pos.y = $Player.global_position.y
		
		$Player.move_to(pos)


func on_elevator_floor_selected(floor_number):
	for e in get_tree().get_nodes_in_group('Elevator'):
		if e.floor_number == floor_number:
			$Player.global_position = e.global_position
			$Player.global_position.y += 64
			
			break
