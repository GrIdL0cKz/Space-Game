extends Area2D

signal elevator_press

@onready var sprite = $AnimatedSprite2D

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
