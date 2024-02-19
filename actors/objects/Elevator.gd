extends Area2D

signal elevator_press

@onready var sprite = $AnimatedSprite2D
@export var floor_number = 1
@export var link_code: int = 0


var is_open = false



func _on_input_event(viewport, event, shape_idx):
	if event is InputEventScreenTouch and !event.pressed:
		if is_open == false:
			sprite.play("open")
		else:
			sprite.play("close")
		
		is_open = !is_open
		
		elevator_press.emit()
		
		get_viewport().set_input_as_handled()


func _on_area_2d_body_entered(body):
	if is_open:
		var i = load('res://actors/ui/popups/ElevatorFloorSelectView.tscn').instantiate()
		
		sprite.play("close")
		is_open = false
		
		ManagerGame.global_player_ui_ref.pop_to_ui(i)
