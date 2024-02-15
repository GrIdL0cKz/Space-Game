extends Node2D


func _ready():
	ManagerGame.elevator_floor_selected.connect(on_elevator_floor_selected)
	


func on_elevator_floor_selected(floor_number):
	for e in get_tree().get_nodes_in_group('Elevator'):
		if e.floor_number == floor_number:
			$Player.global_position = e.global_position
			$Player.global_position.y += 64
			
			break
